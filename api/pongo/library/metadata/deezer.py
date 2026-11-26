"""Deezer catalog, reshaped into the JSON the app's models parse.

The public API needs no key and allows 50 requests per 5 seconds per IP.
"""
import asyncio
import logging
import random
import re
import time
from collections import Counter, deque
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
    genre, chart = await asyncio.gather(_get(f"/genre/{genre_id}"), _get(f"/chart/{genre_id}", limit=50))
    return {
        "id": str(genre["id"]),
        "name": genre.get("name", ""),
        "icons": _images(genre, "picture"),
        "tracks": [track_shape(t) for t in chart["tracks"]["data"][:limit]],
        "albums": [album_shape(a) for a in chart["albums"]["data"]],
        "artists": genre_artists(chart, limit),
        "playlists": [_playlist_shape(p) for p in chart["playlists"]["data"]],
    }


def genre_artists(chart: dict, limit: int) -> list[dict]:
    """A genre's popular artists: those of its chart tracks, by how many they have.

    Deezer's own artists of a genre's chart are the country's top artists whatever
    the genre, so Croatian rappers would show up under latin and R&B."""
    return popular_artists(chart["tracks"]["data"], limit)


async def get_new_releases() -> dict:
    # Deezer's /editorial/0/releases is empty, so use its current editorial picks
    albums = await _get("/editorial/0/selection", limit=50)
    if not albums["data"]:
        albums = await _get("/chart/0/albums", limit=50)
    return {"albums": {"items": [album_shape(a) for a in albums["data"]]}}


# The country charts of Deezer's "Deezer Charts" account, by ISO country code, with
# the country as the account's playlist titles name it. Deezer's /chart/0 follows the
# location of whoever asks, which is the server, so every listener got its country's chart
DEEZER_CHARTS_USER = 637006841
WORLDWIDE_CHART = 3155776842
COUNTRY_CHARTS: dict[str, tuple[str, int]] = {
    "AE": ("United Arab Emirates", 1362491345), "AR": ("Argentina", 1279119721),
    "AT": ("Austria", 1313615765), "AU": ("Australia", 1313616925), "BE": ("Belgium", 1266968331),
    "BG": ("Bulgaria", 1362494565), "BO": ("Bolivia", 1362495515), "BR": ("Brazil", 1111141961),
    "CA": ("Canada", 1652248171), "CH": ("Switzerland", 1313617925), "CI": ("Ivory Coast", 1362497945),
    "CL": ("Chile", 1279119121), "CO": ("Colombia", 1116188451), "CR": ("Costa Rica", 1313618455),
    "CZ": ("Czech Republic", 1266969571), "DE": ("Germany", 1111143121), "DK": ("Denmark", 1313618905),
    "DZ": ("Algeria", 1362501015), "EC": ("Ecuador", 1362501235), "EE": ("Estonia", 1221037201),
    "EG": ("Egypt", 1362501615), "ES": ("Spain", 1116190041), "FI": ("Finland", 1221034071),
    "FR": ("France", 1109890291), "GB": ("UK", 1111142221), "GT": ("Guatemala", 1279118671),
    "HN": ("Honduras", 1116190301), "HR": ("Croatia", 1266971131), "HU": ("Hungary", 1362506695),
    "ID": ("Indonesia", 1116188761), "IE": ("Ireland", 1313619455), "IL": ("Israel", 1362507345),
    "IT": ("Italy", 1116187241), "JM": ("Jamaica", 1362508575), "JO": ("Jordan", 1362508765),
    "JP": ("Japan", 1362508955), "KE": ("Kenya", 1362509215), "KR": ("South Korea", 1362510315),
    "LB": ("Lebanon", 1362511155), "LT": ("Lithuania", 1221037371), "LV": ("Latvia", 1221037511),
    "MA": ("Morocco", 1362512715), "MX": ("Mexico", 1111142361), "MY": ("Malaysia", 1362515675),
    "NG": ("Nigeria", 1362516565), "NL": ("Netherlands", 1266971851), "NO": ("Norway", 1313619885),
    "PE": ("Peru", 1362518525), "PH": ("Philippines", 1362518895), "PL": ("Poland", 1266972311),
    "PT": ("Portugal", 1362519755), "PY": ("Paraguay", 1362520135), "RO": ("Romania", 1279117071),
    "RS": ("Serbia", 1266972981), "SA": ("Saudi Arabia", 1362521285), "SE": ("Sweden", 1313620305),
    "SG": ("Singapore", 1313620765), "SI": ("Slovenia", 1362522355), "SK": ("Slovakia", 1266973701),
    "SN": ("Senegal", 1362523075), "SV": ("El Salvador", 1362523615), "TH": ("Thailand", 1362524475),
    "TN": ("Tunisia", 1362525375), "TR": ("Turkey", 1116189071), "UA": ("Ukraine", 1362526495),
    "US": ("USA", 1313621735), "VE": ("Venezuela", 1362527605), "ZA": ("South Africa", 1362528775),
}
# Countries whose music is close enough to a neighbour's chart, where Deezer has none
NEIGHBOUR_CHARTS = {"BA": "HR", "ME": "RS", "MK": "RS", "XK": "RS", "LU": "BE", "LI": "CH", "NZ": "AU",
                    "BY": "UA", "MD": "RO"}


def popular_artists(tracks: list[dict], limit: int) -> list[dict]:
    """The artists of chart tracks, those with the most tracks first, then in chart order."""
    artists = [t["artist"] for t in tracks if t.get("artist")]
    counts = Counter(a["id"] for a in artists)
    unique = list({a["id"]: a for a in reversed(artists)}.values())[::-1]
    unique.sort(key=lambda a: -counts[a["id"]])
    return [artist_shape(a) for a in unique[:limit]]


def chart_for(country: str | None) -> tuple[str, int] | None:
    """The country's chart playlist, the worldwide one for a country without its own,
    or None when the app didn't say which country it's in."""
    if not country:
        return None
    code = country.strip().upper()
    code = code if code in COUNTRY_CHARTS else NEIGHBOUR_CHARTS.get(code, code)
    return COUNTRY_CHARTS.get(code, ("Worldwide", WORLDWIDE_CHART))


async def get_charts(country: str | None = None, limit: int = 25) -> dict:
    """The charts of the listener's [country], an ISO code such as "GB".

    Apps from before they sent their country get /chart/0, the server's country's."""
    # The home page works without charts, so they must not fail it
    try:
        chart = chart_for(country)
        if chart is None:
            data = await _get("/chart/0", limit=limit)
            return {
                "tracks": [track_shape(t) for t in data["tracks"]["data"]],
                "artists": [artist_shape(a) for a in data["artists"]["data"]],
                "playlists": [_playlist_shape(p) for p in data["playlists"]["data"]],
            }
        name, playlist_id = chart
        tracks, playlists = await asyncio.gather(
            _get(f"/playlist/{playlist_id}/tracks", limit=100),
            _get(f"/user/{DEEZER_CHARTS_USER}/playlists", limit=200),
        )
    except (DeezerError, httpx.HTTPError) as error:
        log.warning("Deezer charts unavailable: %s", error)
        return {"tracks": [], "artists": [], "playlists": []}
    tracks = [t for t in tracks.get("data") or [] if t.get("readable", True)]
    # The country's own chart first, then its other charts, then the worldwide ones
    owned = playlists.get("data") or []
    own = [p for p in owned if p["id"] == playlist_id]
    named = re.compile(rf"\b{re.escape(name)}\b", re.IGNORECASE)
    local = [p for p in owned if named.search(p.get("title", "")) and p["id"] != playlist_id]
    world = [p for p in owned if "worldwide" in p.get("title", "").lower() and p["id"] != playlist_id]
    return {
        "tracks": [track_shape(t) for t in tracks[:limit]],
        "artists": popular_artists(tracks, limit),
        "playlists": [_playlist_shape(p) for p in {p["id"]: p for p in own + local + world}.values()],
    }


async def related_ids(artist_id: str, limit: int = 25) -> list[str]:
    """The ids of Deezer's artists similar to the artist, most similar first."""
    related = await _get(f"/artist/{artist_id}/related", limit=limit)
    return [str(a["id"]) for a in related.get("data") or []]


async def _artists_of(stids: list[str]) -> list:
    """The main artist of each track, most common first, then in the tracks' order."""
    tracks = await asyncio.gather(*(full_track(s) for s in stids), return_exceptions=True)
    artists = [t["artist"]["id"] for t in tracks if not isinstance(t, Exception) and t.get("artist")]
    counts = Counter(artists)
    return sorted(dict.fromkeys(artists), key=lambda a: -counts[a])


async def mix_candidates(seeds: list[str], exclude: set[str], anchors: list[str] | None = None) -> list[dict]:
    """Tracks similar to the seeds, most recent seed first, from the radios of their artists.

    The most recent seed's artist and related artists come first, older seeds' artists
    later, so the mix follows where the listener is now. With [anchors], the tracks the
    mix started from, it keeps to their artists instead: following what the mix itself
    added would drift from one kind of music to another. Excluded ids are left out.
    """
    artist_ids = await _artists_of(seeds)
    scene: set[str] = set()
    if anchors:
        own = await _artists_of(anchors)
        if own:
            scene = await _scene(own[:4])
            scene |= {str(a) for a in own}
            # The latest of the mix's own artists keeps it close to now; others take turns
            recent = [a for a in artist_ids if a in own]
            primary = recent[0] if recent else random.choice(own[:5])
            others = [a for a in own if a != primary]
            artist_ids = [primary, *random.sample(others, min(2, len(others)))]
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
    if scene:
        # Radios wander off too: songs of the mix's artists and those like them come first
        mix.sort(key=lambda t: not any(a["id"] in scene for a in t["artists"]))
    return mix


async def _scene(artist_ids: list) -> set[str]:
    """The artists and those similar to them."""
    lists = await asyncio.gather(*(related_ids(str(a)) for a in artist_ids), return_exceptions=True)
    return {a for ids in lists if not isinstance(ids, Exception) for a in ids}
