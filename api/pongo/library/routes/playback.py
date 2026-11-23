import asyncio
import contextlib
import json
import logging
import time
from pathlib import Path

from fastapi import APIRouter, Depends, HTTPException, Request, WebSocket, WebSocketDisconnect
from fastapi.responses import FileResponse, Response, StreamingResponse

from library import config, db, limits
from library.auth import tokens
from library.auth.tokens import Session, current_session
from library.metadata import deezer, scenes
from library.track import downloads, loudness, mood, partial as partial_files
from library.track.downloads import (
    NotStreamable, TrackUnavailable, ensure_track, ensure_tracks, queue_of, stream_track, streaming,
)

log = logging.getLogger(__name__)

router = APIRouter()


async def _audio_file(stid: str) -> Response:
    path = await db.track_audio_path(stid)
    if path is None or not Path(path).is_file():
        raise HTTPException(status_code=404, detail="Audio file not found")
    if config.SERVE_AUDIO_VIA_PROXY:
        return Response(headers={"X-Pongo-Audio": str(Path(path).relative_to(config.DATA_DIR))})
    # FileResponse handles the Range requests AVPlayer depends on
    return FileResponse(path, media_type="audio/mp4")


@router.get("/play_song/{stid}")
@router.get("/play_song/android/{stid}")
@router.get("/play_song_caching/{stid}")
@router.get("/play_song_caching/android/{stid}")
async def play_song(stid: str, st: str | None = None):
    await tokens.check_stream_token(st)
    return await _audio_file(stid)


@router.get("/stream/{st}/{stid}/{name}")
async def stream(st: str, stid: str, name: str, request: Request):
    """A track that isn't in the library yet, as an HLS playlist, playable while it downloads.

    The stream token is in the path, so the player's requests for the audio, which
    are relative to the playlist, carry it too. A 404 means the app should wait for
    the track to be in the library and play it from /play_song instead.
    """
    session = await tokens.check_stream_token(st)
    if name == "index.m3u8":
        try:
            partial = await stream_track(stid, session.uid)
        except (NotStreamable, TrackUnavailable) as error:
            log.info("Not streaming %s: %s", stid, error)
            raise HTTPException(status_code=404, detail="Not streamable")
        return Response(partial_files.playlist(partial.layout, f"{partial.key}.m4a"),
                        media_type="application/vnd.apple.mpegurl")

    partial = streaming(stid)
    if partial is None or partial.layout is None or name != f"{partial.key}.m4a":
        raise HTTPException(status_code=404, detail="Not found")
    partial.used = time.monotonic()
    total = partial.layout.total
    try:
        span = partial_files.byte_range(request.headers.get("range"), total)
    except ValueError:
        raise HTTPException(status_code=416, detail="Range not satisfiable",
                            headers={"Content-Range": f"bytes */{total}"})
    start, end = span or (0, total - 1)
    headers = {"Accept-Ranges": "bytes", "Content-Length": str(end - start + 1)}
    if span:
        headers["Content-Range"] = f"bytes {start}-{end}/{total}"
    return StreamingResponse(partial.chunks(start, end), status_code=206 if span else 200,
                             media_type="audio/mp4", headers=headers)


@router.post("/track_gains", dependencies=[Depends(current_session)])
async def track_gains(request: Request):
    """Decibels to play each track at so they sound about as loud as each other."""
    stids = [str(s) for s in (await request.json()).get("stids") or []][: config.MAX_BATCH_TRACKS]
    return {"gains": await loudness.gains(stids)}


@router.post("/track_moods", dependencies=[Depends(current_session)])
async def track_moods(request: Request):
    """The mood, tempo and scores of each of the tracks that were analyzed."""
    stids = [str(s) for s in (await request.json()).get("stids") or []][: config.MAX_BATCH_TRACKS]
    return {"moods": await mood.moods(stids)}


@router.post("/prepare_tracks")
async def prepare_tracks(request: Request, session: Session = Depends(current_session)):
    """Starts downloading the given tracks the server doesn't have yet, such as a playlist's,
    so they all play and shuffle. Tracks that failed are tried again."""
    stids = [str(s) for s in (await request.json()).get("stids") or [] if str(s).isdigit()]
    stids = stids[: config.MAX_BATCH_TRACKS]
    have = {row[0] for row in await db.track_durations(stids)}
    started, limited = downloads.prepare([s for s in stids if s not in have], session.uid)
    return {"started": started, "limited": limited}


@router.post("/download_track/{stid}", dependencies=[Depends(current_session)])
async def download_track(stid: str):
    return await _audio_file(stid)


async def _ws_session(websocket: WebSocket, data: dict) -> tokens.Session | None:
    """Reports a bad token on the socket in the form the app expects, then returns None."""
    if not limits.sockets.allow(limits.client_ip(websocket)):
        await websocket.close(code=1013, reason="Too many connections")
        return None
    session = tokens.decode(data.get("at+JWT") or "", "at+JWT")
    status = await tokens.session_status(session) if session else "unknown"
    if status == "ok":
        return session
    if status == "disabled":
        await websocket.send_json({"Status": "Disabled"})
    else:
        await websocket.send_json({"exists": "expired"})
    await websocket.close()
    return None


# Make sure a track is on the server before the player asks for it
@router.websocket("/test")
async def track_ready(websocket: WebSocket):
    await websocket.accept()
    try:
        data = json.loads(await websocket.receive_text())
        session = await _ws_session(websocket, data)
        if session is None:
            return
        stid = str(data["stid"])

        duration = await db.track_duration(stid)
        await websocket.send_json({"exists": "true" if duration is not None else "false"})
        try:
            duration = await ensure_track(stid, session.uid)
            await websocket.send_json({"exists": "true", "duration": duration})
        except TrackUnavailable as error:
            log.warning("Track %s unavailable: %s", stid, error)
            await websocket.send_json({"exists": "failed", "duration": None})
        await websocket.close()
    except WebSocketDisconnect:
        pass


# Prepare the tracks of an album or playlist while they are queued
@router.websocket("/concenating_stids")
async def concatenating_tracks(websocket: WebSocket):
    await websocket.accept()
    try:
        data = json.loads(await websocket.receive_text())
        session = await _ws_session(websocket, data)
        if session is None:
            return
        count = data["stids"]
        if not isinstance(count, int) or not 0 <= count <= config.MAX_BATCH_TRACKS:
            await websocket.close(code=1008, reason="Too many tracks")
            return
        stids: asyncio.Queue[str | None] = asyncio.Queue()

        async def read_stids():
            try:
                for _ in range(count):
                    stids.put_nowait(str(json.loads(await websocket.receive_text())["stid"]))
            except WebSocketDisconnect:
                pass
            finally:
                # Also when the app hangs up, so the tracks below stop waiting for more
                stids.put_nowait(None)

        # The app may send every stid up front, so the next tracks download while it waits
        reader = asyncio.create_task(read_stids())
        try:
            async with contextlib.aclosing(ensure_tracks(stids, owner=session.uid)) as tracks:
                async for _, duration in tracks:
                    await websocket.send_json({"duration": duration})
        finally:
            reader.cancel()
        await websocket.close()
    except WebSocketDisconnect:
        pass


MIX_SEEDS = 5
MIX_ANCHORS = 10
MIX_MAX_COUNT = 5
MIX_MAX_EXCLUDE = 1000


def _catalog_ids(values, limit: int) -> list[str]:
    return [str(v) for v in (values or [])[:limit] if str(v).isdigit()]


async def _fits(stid: str, moods: set[str] | None) -> bool:
    """Whether the track is of one of the moods, which downloading it measured."""
    if not moods:
        return True
    found = (await mood.moods([stid])).get(stid)
    # Songs whose mood couldn't be measured are let in
    return found is None or found["mood"] in moods


# Mix mode: the app asks for a few more similar tracks whenever its queue is nearly done
@router.post("/next_mix_tracks")
async def next_mix_tracks(request: Request, session: tokens.Session = Depends(current_session)):
    data = await request.json()
    seeds = _catalog_ids(data.get("seeds"), MIX_SEEDS)
    # The tracks the mix started from, whose kind of music it keeps to
    anchors = _catalog_ids(data.get("anchors"), MIX_ANCHORS)
    exclude = set(_catalog_ids(data.get("exclude"), MIX_MAX_EXCLUDE))
    count = data.get("count")
    count = min(max(count, 1), MIX_MAX_COUNT) if isinstance(count, int) else 3
    # A mix of a mood only takes songs that sound like it
    wanted = mood.NEIGHBOURS.get(data.get("mood"))
    if not seeds:
        raise HTTPException(status_code=422, detail="No seed tracks")

    candidates = await deezer.mix_candidates(seeds, exclude, anchors)
    by_stid = {track["id"]: track for track in candidates}
    order = list(by_stid)
    if wanted:
        # Songs already known to fit come first, and those known not to are left out
        known = await mood.moods(order)
        order = sorted((s for s in order if s not in known or known[s]["mood"] in wanted),
                       key=lambda s: s not in known)[: count * 6]
    else:
        order = order[: count * 3]
    result = []
    # Only as many downloads at once as tracks wanted; a failed one is replaced by the next candidate
    async with contextlib.aclosing(
        ensure_tracks(queue_of(order), ahead=count, owner=session.uid)
    ) as durations:
        async for stid, duration in durations:
            if duration is not None and await _fits(stid, wanted):
                result.append({"track": by_stid[stid], "duration": duration})
            if len(result) == count:
                break
    return {"tracks": result}


@router.post("/artist_groups")
async def artist_groups(request: Request, session: Session = Depends(current_session)):
    """The artists in scenes of artists that belong together, biggest first, so the
    app can make mixes that keep to one kind of music."""
    limits.check(limits.artist_groupings, session.uid)
    artists = list(dict.fromkeys(_catalog_ids((await request.json()).get("artists"), scenes.MAX_ARTISTS)))
    return {"groups": scenes.group(artists, await scenes.related(artists))}
