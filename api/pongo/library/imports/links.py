"""Reads the songs of a shared Spotify or Apple Music playlist or album from its
public page, so people can bring their playlists over without an account at either.

Only the services' own hosts are fetched, at an address rebuilt from the parsed ID
(redirects too must stay on those hosts), so a link can't make the server request
anything else.
"""
import json
import re
from urllib.parse import urljoin, urlparse

import httpx

SPOTIFY_HOST = "open.spotify.com"
SPOTIFY_SHORT_HOSTS = {"spotify.link", "spoti.fi", "spotify.app.link"}
APPLE_HOST = "music.apple.com"
APPLE_HOSTS = {APPLE_HOST, "itunes.apple.com", "geo.music.apple.com", "embed.music.apple.com"}
# Spotify's embed page lists at most this many songs of a playlist
SPOTIFY_EMBED_LIMIT = 100
MAX_PAGE_BYTES = 8 * 1024 * 1024
MAX_REDIRECTS = 4

_SPOTIFY_ID = re.compile(r"^[A-Za-z0-9]{22}$")
_APPLE_PLAYLIST_ID = re.compile(r"^pl\.[A-Za-z0-9._-]{1,80}$")
_APPLE_ALBUM_ID = re.compile(r"^\d{1,15}$")
_STOREFRONT = re.compile(r"^[a-z]{2}$")
_NEXT_DATA = re.compile(r'<script id="__NEXT_DATA__" type="application/json">(.*?)</script>', re.S)
_APPLE_DATA = re.compile(r'<script[^>]*id="serialized-server-data"[^>]*>(.*?)</script>', re.S)
_SPOTIFY_LINK_IN_PAGE = re.compile(r"https://open\.spotify\.com/[A-Za-z0-9/_?=&.-]+")
# Apple names singles and EPs "Name - Single"; the catalog doesn't
_RELEASE_SUFFIX = re.compile(r"\s+-\s+(Single|EP)$")

_client = httpx.AsyncClient(
    timeout=15,
    headers={
        "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 "
        "(KHTML, like Gecko) Version/18.0 Safari/605.1.15",
        "Accept-Language": "en",
    },
)


class LinkError(Exception):
    """A link that can't be read. [reason] is one of: unsupported (not a playlist or
    album link of either service), liked_songs (Spotify's liked songs, which can't be
    shared), private (only its owner can see it), not_found, unavailable (the service
    didn't answer as expected)."""

    def __init__(self, reason: str):
        super().__init__(reason)
        self.reason = reason


def close():
    return _client.aclose()


# Parsing
def parse(link: str) -> tuple[str, str, str, str | None]:
    """(service, kind, id, storefront) of a link, without fetching it. Short links
    come back as ("spotify", "short", url, None) and have to be resolved."""
    link = (link or "").strip()
    match = re.match(r"^spotify:(?:user:[^:]+:)?(playlist|album|collection):?([A-Za-z0-9]*)$", link)
    if match:
        return _spotify(match.group(1), match.group(2))

    if not re.match(r"^https?://", link, re.I):
        link = "https://" + link
    url = urlparse(link)
    host = (url.hostname or "").lower()
    parts = [p for p in url.path.split("/") if p]

    if host in SPOTIFY_SHORT_HOSTS:
        return "spotify", "short", f"https://{host}{url.path}", None
    if host in (SPOTIFY_HOST, "play.spotify.com"):
        # /intl-de/playlist/ID, /embed/playlist/ID, /user/NAME/playlist/ID
        if parts and (parts[0].startswith("intl-") or parts[0] == "embed"):
            parts = parts[1:]
        if len(parts) >= 3 and parts[0] == "user":
            parts = parts[2:]
        if parts and parts[0] == "collection":
            raise LinkError("liked_songs")
        if len(parts) >= 2:
            return _spotify(parts[0], parts[1])
        raise LinkError("unsupported")

    if host in APPLE_HOSTS:
        if parts and parts[0] == "library":
            raise LinkError("private")
        storefront = parts[0] if parts and _STOREFRONT.match(parts[0]) else "us"
        if parts and _STOREFRONT.match(parts[0]):
            parts = parts[1:]
        if len(parts) >= 2 and parts[0] in ("playlist", "album"):
            identifier = parts[-1]
            # A song link is its album's address with ?i=<song>; take the album
            if parts[0] == "album" and _APPLE_ALBUM_ID.match(identifier):
                return "apple_music", "album", identifier, storefront
            if parts[0] == "playlist" and _APPLE_PLAYLIST_ID.match(identifier):
                return "apple_music", "playlist", identifier, storefront
        raise LinkError("unsupported")
    raise LinkError("unsupported")


def _spotify(kind: str, identifier: str) -> tuple[str, str, str, None]:
    if kind == "collection":
        raise LinkError("liked_songs")
    if kind not in ("playlist", "album") or not _SPOTIFY_ID.match(identifier):
        raise LinkError("unsupported")
    return "spotify", kind, identifier, None


# Fetching
async def _fetch(url: str, hosts: set[str]) -> httpx.Response:
    """GETs [url], following redirects only to [hosts]."""
    for _ in range(MAX_REDIRECTS + 1):
        async with _client.stream("GET", url) as response:
            if response.is_redirect:
                target = urljoin(url, response.headers.get("location", ""))
                if (urlparse(target).hostname or "").lower() not in hosts:
                    raise LinkError("unsupported")
                url = target
                continue
            body = bytearray()
            async for chunk in response.aiter_bytes():
                body.extend(chunk)
                if len(body) > MAX_PAGE_BYTES:
                    raise LinkError("unavailable")
            return httpx.Response(response.status_code, content=bytes(body), request=response.request)
    raise LinkError("unavailable")


async def _resolve_short(url: str) -> tuple[str, str, str, None]:
    """Spotify's short links redirect, sometimes through a page that names the target."""
    try:
        response = await _fetch(url, SPOTIFY_SHORT_HOSTS | {SPOTIFY_HOST})
    except httpx.HTTPError as error:
        raise LinkError("unavailable") from error
    final = str(response.request.url)
    if urlparse(final).hostname == SPOTIFY_HOST:
        service, kind, identifier, _ = parse(final)
        if kind != "short":
            return service, kind, identifier, None
    for candidate in _SPOTIFY_LINK_IN_PAGE.findall(response.text):
        try:
            service, kind, identifier, _ = parse(candidate)
        except LinkError:
            continue
        if kind != "short":
            return service, kind, identifier, None
    raise LinkError("not_found")


async def read(link: str) -> dict:
    """The name, cover and songs of a shared playlist or album."""
    service, kind, identifier, storefront = parse(link)
    if kind == "short":
        service, kind, identifier, storefront = await _resolve_short(identifier)
    try:
        if service == "spotify":
            response = await _fetch(f"https://{SPOTIFY_HOST}/embed/{kind}/{identifier}", {SPOTIFY_HOST})
            parse_page = spotify_page
        else:
            response = await _fetch(f"https://{APPLE_HOST}/{storefront}/{kind}/{identifier}", APPLE_HOSTS)
            parse_page = apple_page
    except httpx.HTTPError as error:
        raise LinkError("unavailable") from error
    if response.status_code == 404:
        raise LinkError("not_found")
    if response.status_code in (401, 403):
        raise LinkError("private")
    if response.status_code != 200:
        raise LinkError("unavailable")
    return {"source": service, "kind": kind, "id": identifier, **parse_page(response.text, kind)}


# Pages
def _artists(text: str | None) -> list[str]:
    # Spotify separates artists with a comma and a no-break space
    return [a.strip() for a in re.split(r", |,\s", text or "") if a.strip()]


def spotify_page(html: str, kind: str) -> dict:
    match = _NEXT_DATA.search(html)
    if not match:
        raise LinkError("unavailable")
    try:
        entity = json.loads(match.group(1))["props"]["pageProps"]["state"]["data"]["entity"]
    except (ValueError, KeyError, TypeError):
        # The embed page of a private or deleted playlist has no entity
        raise LinkError("not_found") from None

    name = entity.get("name") or entity.get("title") or ""
    album = name if kind == "album" else None
    tracks, skipped = [], 0
    for item in entity.get("trackList") or []:
        # Podcast episodes can be in playlists; they aren't music
        if item.get("entityType", "track") != "track" or not item.get("title"):
            skipped += 1
            continue
        tracks.append({
            "title": item["title"],
            "artists": _artists(item.get("subtitle")),
            "album": album,
            "duration_ms": item.get("duration") or None,
            "isrc": None,
        })

    sources = (entity.get("coverArt") or {}).get("sources") or []
    image = max(sources, key=lambda s: s.get("width") or 0).get("url") if sources else None
    listed = len(tracks) + skipped
    return {
        "name": name,
        "owner": entity.get("subtitle") if kind == "playlist" else None,
        "image": image,
        "tracks": tracks,
        "skipped": skipped,
        # The embed shows the first 100; a full page may mean there are more
        "truncated": kind == "playlist" and listed >= SPOTIFY_EMBED_LIMIT,
        "total": None if kind == "playlist" and listed >= SPOTIFY_EMBED_LIMIT else listed,
    }


def _artwork(item: dict | None, size: int = 600) -> str | None:
    template = ((item or {}).get("artwork") or {}).get("dictionary", {}).get("url")
    if not template:
        return None
    return template.replace("{w}", str(size)).replace("{h}", str(size)).replace("{c}", "bb").replace(
        "{f}", "jpg"
    )


def apple_page(html: str, kind: str) -> dict:
    match = _APPLE_DATA.search(html)
    if not match:
        raise LinkError("unavailable")
    try:
        data = json.loads(match.group(1))
        page = (data["data"] if isinstance(data, dict) else data)[0]["data"]
        sections = page["sections"]
    except (ValueError, KeyError, IndexError, TypeError):
        raise LinkError("unavailable") from None

    header = next(
        (s["items"][0] for s in sections if s.get("itemKind") == "containerDetailHeaderLockup" and s.get("items")),
        {},
    )
    header_artists = [link.get("title") for link in header.get("subtitleLinks") or [] if link.get("title")]
    name = header.get("title") or ""

    tracks, skipped = [], 0
    for section in sections:
        if section.get("itemKind") != "trackLockup":
            continue
        for item in section.get("items") or []:
            descriptor = (item.get("contentDescriptor") or {}).get("kind")
            if descriptor not in (None, "song", "musicVideo") or not item.get("title"):
                skipped += 1
                continue
            artists = [link.get("title") for link in item.get("subtitleLinks") or [] if link.get("title")]
            if not artists:
                artists = [item["artistName"]] if item.get("artistName") else header_artists
            album = name if kind == "album" else None
            if album is None and item.get("tertiaryLinks"):
                album = _RELEASE_SUFFIX.sub("", item["tertiaryLinks"][0].get("title") or "") or None
            tracks.append({
                "title": item["title"],
                "artists": artists,
                "album": album,
                "duration_ms": item.get("duration") or None,
                "isrc": None,
            })

    total = header.get("trackCount")
    listed = len(tracks) + skipped
    return {
        "name": name,
        "owner": ", ".join(header_artists) or None,
        "image": _artwork(header),
        "tracks": tracks,
        "skipped": skipped,
        "truncated": isinstance(total, int) and total > listed,
        "total": total if isinstance(total, int) else listed,
    }
