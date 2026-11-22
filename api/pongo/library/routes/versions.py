"""Picking the right recording of a track when the matched YouTube video is another one,
such as a re-recording with the same title and length."""
import asyncio
import re

from fastapi import APIRouter, Depends, HTTPException, Request

from library import db, limits
from library.auth.tokens import Session, current_session
from library.metadata import deezer
from library.track import downloads, matcher

router = APIRouter()

# A video ID alone, or in a youtube.com / youtu.be / music.youtube.com link
_VIDEO = re.compile(r"(?:^|v=|youtu\.be/|/shorts/|/embed/|/live/)([A-Za-z0-9_-]{11})(?:$|[?&#/])")
MAX_ALBUM_YEARS = 8


def video_id(text: str) -> str | None:
    match = _VIDEO.search((text or "").strip())
    return match.group(1) if match else None


def _stid(value) -> str:
    value = str(value or "")
    if not value.isdigit():
        raise HTTPException(status_code=404, detail="Not found")
    return value


@router.post("/track_versions")
async def track_versions(request: Request, session: Session = Depends(current_session)):
    """The YouTube recordings that could be the track, the one it plays now first."""
    limits.check(limits.versions, session.uid)
    stid = _stid((await request.json()).get("stid"))
    full = await deezer.full_track(stid)
    track = {"title": full["title"], "artist": full["artist"]["name"], "duration": full.get("duration", 0)}
    row = await db.fetch_one("SELECT ytvid FROM track WHERE stid = %s", (stid,))
    current = row[0] if row else None

    found = await asyncio.to_thread(matcher.versions, track)
    if current and not any(v["id"] == current for v in found):
        playing = await asyncio.to_thread(matcher.video, current)
        if playing:
            found.insert(0, {**playing, "score": None})
    found.sort(key=lambda v: v["id"] != current)

    # The year tells re-recordings apart, and YouTube gives it only per album
    albums = list(dict.fromkeys(v["album_id"] for v in found if v.get("album_id") and not v.get("year")))
    years = await asyncio.gather(
        *(asyncio.to_thread(matcher.album_year, a) for a in albums[:MAX_ALBUM_YEARS])
    )
    by_album = dict(zip(albums, years))
    for version in found:
        version["year"] = version.get("year") or by_album.get(version.get("album_id"))
        version["current"] = version["id"] == current
    return {"title": track["title"], "artist": track["artist"], "duration": track["duration"], "versions": found}


@router.post("/set_track_version")
async def set_track_version(request: Request, session: Session = Depends(current_session)):
    """Plays the track from the given YouTube video from now on, for everyone."""
    data = await request.json()
    stid = _stid(data.get("stid"))
    chosen = video_id(data.get("video") or "")
    if chosen is None:
        raise HTTPException(status_code=422, detail="not_a_video")
    try:
        duration = await downloads.use_version(stid, chosen, session.uid)
    except downloads.TrackUnavailable as error:
        raise HTTPException(status_code=422, detail="unavailable") from error
    return {"duration": duration, "video": chosen}
