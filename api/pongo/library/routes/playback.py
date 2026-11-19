import asyncio
import base64
import contextlib
import json
import logging
from pathlib import Path

from fastapi import APIRouter, Depends, HTTPException, Request, WebSocket, WebSocketDisconnect
from fastapi.responses import FileResponse

from library import db
from library.auth import tokens
from library.auth.tokens import current_session
from library.metadata import deezer
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


@router.post("/download_track/{stid}", dependencies=[Depends(current_session)])
async def download_track(stid: str):
    return await _audio_file(stid)


def _encode_file(path: str) -> str:
    return base64.b64encode(Path(path).read_bytes()).decode()


@router.post("/download_a_playlist", dependencies=[Depends(current_session)])
async def download_a_playlist(request: Request):
    stids = (await request.json())["stids"]
    result = {}
    # Encoding one file at a time keeps at most one file's base64 in memory beyond the response so far
    async with contextlib.aclosing(ensure_tracks(queue_of(stids))) as tracks:
        async for stid, duration in tracks:
            if duration is None:
                continue
            path = await db.track_audio_path(stid)
            result[stid] = (duration, await asyncio.to_thread(_encode_file, path))
    return result


async def _ws_session(websocket: WebSocket, data: dict) -> tokens.Session | None:
    """Reports a bad token on the socket in the form the app expects, then returns None."""
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
        if await _ws_session(websocket, data) is None:
            return
        stid = str(data["stid"])

        duration = await db.track_duration(stid)
        await websocket.send_json({"exists": "true" if duration is not None else "false"})
        try:
            duration = await ensure_track(stid)
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
        if await _ws_session(websocket, data) is None:
            return
        stids: asyncio.Queue[str | None] = asyncio.Queue()

        async def read_stids():
            try:
                for _ in range(data["stids"]):
                    stids.put_nowait(str(json.loads(await websocket.receive_text())["stid"]))
            except WebSocketDisconnect:
                pass
            finally:
                # Also when the app hangs up, so the tracks below stop waiting for more
                stids.put_nowait(None)

        # The app may send every stid up front, so the next tracks download while it waits
        reader = asyncio.create_task(read_stids())
        try:
            async with contextlib.aclosing(ensure_tracks(stids)) as tracks:
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
@router.post("/next_mix_tracks", dependencies=[Depends(current_session)])
async def next_mix_tracks(request: Request):
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
        ensure_tracks(queue_of(list(by_stid)[: count * 3]), ahead=count)
    ) as durations:
        async for stid, duration in durations:
            if duration is not None:
                result.append({"track": by_stid[stid], "duration": duration})
            if len(result) == count:
                break
    return {"tracks": result}
