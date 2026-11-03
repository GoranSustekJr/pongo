import asyncio
import base64
import json
import logging
from pathlib import Path

from fastapi import APIRouter, Depends, HTTPException, Request, WebSocket, WebSocketDisconnect
from fastapi.responses import FileResponse

from library import db
from library.auth import tokens
from library.auth.tokens import current_session
from library.metadata import deezer
from library.track.downloads import TrackUnavailable, ensure_track

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
    data = await request.json()
    result = {}
    # One at a time keeps at most one file's base64 in memory beyond the response so far
    for stid in data["stids"]:
        try:
            duration = await ensure_track(stid)
        except TrackUnavailable as error:
            log.warning("Skipping %s: %s", stid, error)
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
        for _ in range(data["stids"]):
            stid = str(json.loads(await websocket.receive_text())["stid"])
            try:
                await websocket.send_json({"duration": await ensure_track(stid)})
            except TrackUnavailable as error:
                log.warning("Track %s unavailable: %s", stid, error)
                await websocket.send_json({"duration": None})
        await websocket.close()
    except WebSocketDisconnect:
        pass


# Mix mode: stream tracks similar to the one just played, as each becomes ready
@router.websocket("/cfc14e13ca191618a06bd94dd5976fccae585e36b3f651b467947288afb51ea8")
async def mix(websocket: WebSocket):
    await websocket.accept()
    try:
        data = json.loads(await websocket.receive_text())
        if await _ws_session(websocket, data) is None:
            return
        for track in await deezer.get_mix(str(data["stid"])):
            try:
                duration = await ensure_track(track["id"])
            except TrackUnavailable as error:
                log.warning("Skipping mix track %s: %s", track["id"], error)
                continue
            # A closed socket raises here, which stops downloading the rest of the mix
            await websocket.send_json({"duration": duration, "track": track})
        await websocket.close()
    except WebSocketDisconnect:
        pass
    except deezer.DeezerError as error:
        log.warning("Mix failed: %s", error)
        await websocket.close()
