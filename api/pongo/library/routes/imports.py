from fastapi import APIRouter, Depends, HTTPException, Request

from library import config, limits
from library.auth.tokens import Session, current_session
from library.imports import links, matching

router = APIRouter()

MAX_TEXT = 300
MAX_ARTISTS = 10


@router.post("/import_link")
async def import_link(request: Request, session: Session = Depends(current_session)):
    """The songs of a shared Spotify or Apple Music playlist or album."""
    limits.check(limits.import_links, session.uid)
    data = await request.json()
    link = data.get("link")
    if not isinstance(link, str) or not link.strip() or len(link) > 2000:
        raise HTTPException(status_code=400, detail="Missing link")
    try:
        return await links.read(link)
    except links.LinkError as error:
        raise HTTPException(status_code=422, detail=error.reason)


def _text(value, limit: int = MAX_TEXT) -> str | None:
    return (value.strip()[:limit] or None) if isinstance(value, str) else None


def _song(value) -> dict:
    if not isinstance(value, dict) or not _text(value.get("title")):
        raise HTTPException(status_code=400, detail="Every song needs a title")
    artists = value.get("artists") if isinstance(value.get("artists"), list) else []
    duration = value.get("duration_ms")
    return {
        "title": _text(value["title"]),
        "artists": [a for a in (_text(a) for a in artists[:MAX_ARTISTS]) if a],
        "album": _text(value.get("album")),
        "duration_ms": int(duration) if isinstance(duration, (int, float)) and 0 < duration < 86_400_000 else None,
        "isrc": _text(value.get("isrc"), 20),
    }


@router.post("/import_match")
async def import_match(request: Request, session: Session = Depends(current_session)):
    """The catalog track for each song, in the order sent, or the closest candidates."""
    data = await request.json()
    songs = data.get("songs")
    if not isinstance(songs, list) or not songs:
        raise HTTPException(status_code=400, detail="Missing songs")
    if len(songs) > config.MAX_IMPORT_BATCH:
        raise HTTPException(status_code=413, detail=f"At most {config.MAX_IMPORT_BATCH} songs at once")
    songs = [_song(s) for s in songs]
    limits.check(limits.import_batches, session.uid)
    return {"matches": await matching.match_all(songs)}
