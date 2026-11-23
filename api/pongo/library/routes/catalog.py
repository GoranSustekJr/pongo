import asyncio

from fastapi import APIRouter, Depends, HTTPException, Request

from library import db
from library.auth.tokens import current_session
from library.metadata import deezer
from library.track import shazam

router = APIRouter(dependencies=[Depends(current_session)])


def _catalog_id(value) -> str:
    """Catalog ids are numeric; anything else can't be a real item."""
    value = str(value)
    if not value.isdigit():
        raise HTTPException(status_code=404, detail="Not found")
    return value


async def _availability(stids: list[str]) -> dict:
    durations = await db.track_durations(stids)
    existing = {row[0] for row in durations}
    missing = [stid for stid in stids if stid not in existing]
    return {
        "durations": durations,
        "missing_tracks": missing,
        # Why the server couldn't download some of the missing ones, by stid
        "failed_tracks": await db.track_failures(missing),
    }


@router.post("/search_spotify")
async def search(request: Request):
    data = await request.json()
    return await deezer.search(data["query"])


@router.post("/get_playlist")
async def get_playlist(request: Request):
    data = await request.json()
    tracks = await deezer.get_playlist_tracks(_catalog_id(data["spid"]))
    availability = await _availability([t["id"] for t in tracks])
    return {"items": [{"track": t} for t in tracks], **availability}


@router.post("/get_playlist_shuffle")
async def get_playlist_shuffle(request: Request):
    data = await request.json()
    tracks = await deezer.get_playlist_tracks(_catalog_id(data["spid"]))
    return {"durations": await db.track_durations([t["id"] for t in tracks])}


@router.post("/get_album")
async def get_album(request: Request):
    data = await request.json()
    tracks = await deezer.get_album_tracks(_catalog_id(data["salid"]))
    availability = await _availability([t["id"] for t in tracks])
    return {"items": tracks, **availability}


@router.post("/get_album_data")
async def get_album_data(request: Request):
    data = await request.json()
    return await deezer.get_album(_catalog_id(data["salid"]))


@router.post("/get_album_shuffle")
async def get_album_shuffle(request: Request):
    data = await request.json()
    tracks = await deezer.get_album_tracks(_catalog_id(data["said"]))
    return {"durations": await db.track_durations([t["id"] for t in tracks])}


@router.post("/get_serialized_tracks")
async def get_serialized_tracks(request: Request):
    data = await request.json()
    stids = [_catalog_id(s) for s in data["stids"]]
    tracks = await deezer.get_tracks(stids)
    return {"tracks": {"tracks": tracks}, **await _availability(stids)}


@router.post("/get_serialized_shuffle")
async def get_serialized_shuffle(request: Request):
    data = await request.json()
    return await _availability([_catalog_id(s) for s in data["stids"]])


@router.post("/get_artist_metadata")
async def get_artist_metadata(request: Request):
    data = await request.json()
    return await deezer.get_artist_page(_catalog_id(data["said"]))


@router.post("/caf5cc332d474f35ff74e94af44f2a7801b620b2ce0196560e038b511d14986e")
async def get_artist_images(request: Request):
    data = await request.json()
    artist = await deezer.get_artist(_catalog_id(data["said"]))
    return {"images": artist["images"]}


@router.post("/get_recommendations")
async def get_recommendations(request: Request):
    data = await request.json()
    # Phones can still hold ids from before the Deezer catalog; skip those
    history = [str(s) for s in data.get("history") or [] if str(s).isdigit()]
    categories, history_tracks, new_releases, charts = await asyncio.gather(
        deezer.get_genres(data.get("category_num", 20)),
        deezer.get_tracks(history),
        deezer.get_new_releases(),
        deezer.get_charts(),
    )
    return {
        "history": {"tracks": history_tracks} if history else None,
        "categories": categories,
        "new_releases": new_releases,
        "charts": charts,
    }


@router.post("/get_genre")
async def get_genre(request: Request):
    data = await request.json()
    return await deezer.get_genre_page(_catalog_id(data["gid"]))


@router.post("/get_track_duration")
async def get_track_duration(request: Request):
    data = await request.json()
    return {"duration": await db.track_duration(_catalog_id(data["stid"]))}


@router.post("/6a2f5d49dda86647d136751f354f0bbfbd76a414a283b18f211b34f911029e0e")
async def identify_track(request: Request):
    data = await request.json()
    path = await db.track_audio_path(_catalog_id(data["stid"]))
    if path is None:
        raise HTTPException(status_code=404, detail="Audio file not found")
    return await shazam.recognize(path)
