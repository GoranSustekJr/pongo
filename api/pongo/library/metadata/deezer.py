"""Deezer catalog, reshaped into the JSON the app's models parse.

The public API needs no key and allows 50 requests per 5 seconds per IP.
"""
import asyncio
import logging
import time
from collections import deque
from urllib.parse import urlencode

import httpx
from cachetools import TTLCache

log = logging.getLogger(__name__)

BASE_URL = "https://api.deezer.com"
QUOTA_EXCEEDED = 4
NOT_FOUND = 800

_client = httpx.AsyncClient(base_url=BASE_URL, timeout=15)
_cache: TTLCache = TTLCache(maxsize=5000, ttl=3600)
_in_flight = asyncio.Semaphore(10)
# Stay a little under Deezer's limit so big imports don't run into it
RATE_LIMIT, RATE_WINDOW = 45, 5.0
_sent: deque[float] = deque()
_pacing = asyncio.Lock()


class DeezerError(Exception):
    pass


async def _pace():
    """Waits until another request fits in Deezer's rate limit."""
    async with _pacing:
        while True:
            now = time.monotonic()
            while _sent and _sent[0] <= now - RATE_WINDOW:
                _sent.popleft()
            if len(_sent) < RATE_LIMIT:
                _sent.append(now)
                return
            await asyncio.sleep(_sent[0] + RATE_WINDOW - now)


async def _get(path: str, **params) -> dict:
    key = f"{path}?{urlencode(sorted(params.items()))}"
    if key in _cache:
        return _cache[key]

    for attempt in range(3):
        await _pace()
        async with _in_flight:
            response = await _client.get(path, params=params)
        response.raise_for_status()
        data = response.json()
        # Deezer reports errors, including rate limiting, as HTTP 200
        error = data.get("error") if isinstance(data, dict) else None
        if not error:
            _cache[key] = data
            return data
        if error.get("code") != QUOTA_EXCEEDED:
            raise DeezerError(f"{path}: {error}")
        await asyncio.sleep(2 * (attempt + 1))
    raise DeezerError(f"{path}: rate limited")


def close():
    return _client.aclose()


# Shapes
def _images(item: dict, prefix: str) -> list[dict]:
    sizes = (("xl", 1000), ("big", 500), ("medium", 250), ("small", 56))
    return [
        {"url": item[f"{prefix}_{name}"], "width": size, "height": size}
        for name, size in sizes
        if item.get(f"{prefix}_{name}")
    ]


def _artist_ref(artist: dict) -> dict:
    return {"id": str(artist["id"]), "name": artist.get("name")}


def artist_shape(artist: dict) -> dict:
    return {**_artist_ref(artist), "images": _images(artist, "picture")}


def album_shape(album: dict, artist: dict | None = None) -> dict:
    owner = album.get("artist") or artist
    record_type = album.get("record_type", "album")
    return {
        "id": str(album["id"]),
        "name": album.get("title", ""),
        "album_type": "compilation" if record_type == "compile" else record_type,
        "release_date": album.get("release_date"),
        "artists": [_artist_ref(owner)] if owner else [],
        "images": _images(album, "cover"),
    }


def track_shape(track: dict, album: dict | None = None) -> dict:
    # Only full track and album-track records list every artist
    artists = track.get("contributors") or ([track["artist"]] if track.get("artist") else [])
    source_album = track.get("album") or album
    return {
        "id": str(track["id"]),
        "name": track.get("title", ""),
        "duration_ms": track.get("duration", 0) * 1000,
        "isrc": track.get("isrc"),
        "artists": [_artist_ref(a) for a in artists],
        "album": album_shape(source_album) if source_album else None,
    }


def _playlist_shape(playlist: dict) -> dict:
    return {
        "id": str(playlist["id"]),
        "name": playlist.get("title", ""),
        "description": playlist.get("description"),
        "images": _images(playlist, "picture"),
    }


# Catalog
async def search(query: str) -> dict:
    # Deezer decodes the query twice, so a once-encoded "+" arrives as a space
    # and "z++" would search for "z"
    query = query.replace("+", "%2B")
    tracks, albums, artists, playlists = await asyncio.gather(
        _get("/search/track", q=query, limit=50),
        _get("/search/album", q=query, limit=25),
        _get("/search/artist", q=query, limit=25),
        _get("/search/playlist", q=query, limit=25),
    )
    return {
        "tracks": {"items": [track_shape(t) for t in tracks["data"]]},
        "albums": {"items": [album_shape(a) for a in albums["data"]]},
        "artists": {"items": [artist_shape(a) for a in artists["data"]]},
        "playlists": {"items": [_playlist_shape(p) for p in playlists["data"]]},
    }


async def search_tracks(query: str, limit: int = 10) -> list[dict]:
    """Raw track search results, best first."""
    data = await _get("/search/track", q=query.replace("+", "%2B"), limit=limit)
    return data.get("data") or []


async def track_by_isrc(isrc: str) -> dict | None:
    try:
        track = await _get(f"/track/isrc:{isrc}")
    except DeezerError:
        return None
    return track if track.get("id") else None


async def full_track(stid: str) -> dict:
    return await _get(f"/track/{stid}")


async def get_track(stid: str) -> dict:
    return track_shape(await full_track(stid))


async def get_tracks(stids: list[str]) -> list[dict]:
    """Tracks in the order requested; ids Deezer no longer knows are left out."""
    results = await asyncio.gather(*(get_track(s) for s in stids), return_exceptions=True)
    return [r for r in results if not isinstance(r, Exception)]


async def get_album(album_id: str) -> dict:
    return album_shape(await _get(f"/album/{album_id}"))


async def get_album_tracks(album_id: str) -> list[dict]:
    tracks = await _get(f"/album/{album_id}/tracks", limit=300)
    return [track_shape(t) for t in tracks["data"]]


async def get_playlist_tracks(playlist_id: str) -> list[dict]:
    tracks = await _get(f"/playlist/{playlist_id}/tracks", limit=100)
    return [track_shape(t) for t in tracks["data"]]


async def get_artist(artist_id: str) -> dict:
    return artist_shape(await _get(f"/artist/{artist_id}"))


async def get_artist_page(artist_id: str) -> dict:
    artist, albums, top = await asyncio.gather(
        _get(f"/artist/{artist_id}"),
        _get(f"/artist/{artist_id}/albums", limit=50),
        _get(f"/artist/{artist_id}/top", limit=10),
    )
    return {
        "albums": [album_shape(a, artist) for a in albums["data"]],
        "tracks": [track_shape(t) for t in top["data"]],
    }


async def get_genres(limit: int) -> dict:
    genres = await _get("/genre")
    # Id 0 is the "All" pseudo genre
    items = [
        {"id": str(g["id"]), "name": g["name"], "icons": _images(g, "picture")}
        for g in genres["data"]
        if g["id"] != 0
    ]
    return {"categories": {"items": items[:limit]}}


async def get_genre_page(genre_id: str, limit: int = 25) -> dict:
    """A genre's name and picture with its own charts."""
    genre, chart = await asyncio.gather(_get(f"/genre/{genre_id}"), _get(f"/chart/{genre_id}", limit=limit))
    return {
        "id": str(genre["id"]),
        "name": genre.get("name", ""),
        "icons": _images(genre, "picture"),
        "tracks": [track_shape(t) for t in chart["tracks"]["data"]],
        "albums": [album_shape(a) for a in chart["albums"]["data"]],
        "artists": [artist_shape(a) for a in chart["artists"]["data"]],
        "playlists": [_playlist_shape(p) for p in chart["playlists"]["data"]],
    }


async def get_new_releases() -> dict:
    # Deezer's /editorial/0/releases is empty, so use its current editorial picks
    albums = await _get("/editorial/0/selection", limit=50)
    if not albums["data"]:
        albums = await _get("/chart/0/albums", limit=50)
    return {"albums": {"items": [album_shape(a) for a in albums["data"]]}}


async def get_charts(limit: int = 25) -> dict:
    # The home page works without charts, so they must not fail it
    try:
        chart = await _get("/chart/0", limit=limit)
    except (DeezerError, httpx.HTTPError) as error:
        log.warning("Deezer charts unavailable: %s", error)
        return {"tracks": [], "artists": [], "playlists": []}
    return {
        "tracks": [track_shape(t) for t in chart["tracks"]["data"]],
        "artists": [artist_shape(a) for a in chart["artists"]["data"]],
        "playlists": [_playlist_shape(p) for p in chart["playlists"]["data"]],
    }


async def mix_candidates(seeds: list[str], exclude: set[str]) -> list[dict]:
    """Tracks similar to the seeds, most recent seed first, from the radios of their artists.

    The most recent seed's artist and related artists come first, older seeds' artists
    later, so the mix follows where the listener is now. Excluded ids are left out.
    """
    tracks = await asyncio.gather(*(full_track(s) for s in seeds), return_exceptions=True)
    artist_ids = list(dict.fromkeys(
        t["artist"]["id"] for t in tracks if not isinstance(t, Exception)
    ))
    if not artist_ids:
        return []
    related = await _get(f"/artist/{artist_ids[0]}/related", limit=3)
    sources = [artist_ids[0], *(r["id"] for r in related["data"]), *artist_ids[1:3]]
    radios = await asyncio.gather(
        *(_get(f"/artist/{a}/radio", limit=50) for a in dict.fromkeys(sources)),
        return_exceptions=True,
    )

    # Round robin across the radios so one artist doesn't dominate
    lists = [r["data"] for r in radios if not isinstance(r, Exception)]
    seen, mix = {str(s) for s in [*seeds, *exclude]}, []
    for position in range(max(map(len, lists), default=0)):
        for items in lists:
            if position < len(items) and str(items[position]["id"]) not in seen:
                seen.add(str(items[position]["id"]))
                mix.append(track_shape(items[position]))
    return mix
