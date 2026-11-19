import asyncio
import contextlib
import json
import logging
from pathlib import Path

from fastapi import APIRouter, Depends, HTTPException, Request, WebSocket, WebSocketDisconnect
from fastapi.responses import FileResponse

from library import config, db, limits
from library.auth import tokens
from library.auth.tokens import current_session
from library.metadata import deezer
from library.track import loudness
from library.track.downloads import TrackUnavailable, ensure_track, ensure_tracks, queue_of

log = logging.getLogger(__name__)

router = APIRouter()


async def _audio_file(stid: str) -> FileResponse:
    path = await db.track_audio_path(stid)
    if path is None or not Path(path).is_file():
        raise HTTPException(status_code=404, detail="Audio file not found")
    # FileResponse handles the Range requests AVPlayer depends on
    return FileResponse(path, media_type="audio/mp4")


@router.get("/play_song/{stid}")
@router.get("/play_song/android/{stid}")
@router.get("/play_song_caching/{stid}")
@router.get("/play_song_caching/android/{stid}")
async def play_song(stid: str, st: str | None = None):
    await tokens.check_stream_token(st)
    return await _audio_file(stid)


@router.post("/track_gains", dependencies=[Depends(current_session)])
async def track_gains(request: Request):
    """Decibels to play each track at so they sound about as loud as each other."""
    stids = [str(s) for s in (await request.json()).get("stids") or []][: config.MAX_BATCH_TRACKS]
    return {"gains": await loudness.gains(stids)}


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
MIX_MAX_COUNT = 5
MIX_MAX_EXCLUDE = 1000


def _catalog_ids(values, limit: int) -> list[str]:
    return [str(v) for v in (values or [])[:limit] if str(v).isdigit()]


# Mix mode: the app asks for a few more similar tracks whenever its queue is nearly done
@router.post("/next_mix_tracks")
async def next_mix_tracks(request: Request, session: tokens.Session = Depends(current_session)):
    data = await request.json()
    seeds = _catalog_ids(data.get("seeds"), MIX_SEEDS)
    exclude = set(_catalog_ids(data.get("exclude"), MIX_MAX_EXCLUDE))
    count = data.get("count")
    count = min(max(count, 1), MIX_MAX_COUNT) if isinstance(count, int) else 3
    if not seeds:
        raise HTTPException(status_code=422, detail="No seed tracks")

    candidates = await deezer.mix_candidates(seeds, exclude)
    by_stid = {track["id"]: track for track in candidates}
    result = []
    # Only as many downloads at once as tracks wanted; a failed one is replaced by the next candidate
    async with contextlib.aclosing(
        ensure_tracks(queue_of(list(by_stid)[: count * 3]), ahead=count, owner=session.uid)
    ) as durations:
        async for stid, duration in durations:
            if duration is not None:
                result.append({"track": by_stid[stid], "duration": duration})
            if len(result) == count:
                break
    return {"tracks": result}
