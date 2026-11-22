"""Finds the catalog track for a song from another service's playlist.

The other services' IDs mean nothing to the catalog, so songs are matched by their
ISRC when one is known and otherwise by title, artists and length, the way the
services' own playlist transfers do.
"""
import asyncio
import re
from difflib import SequenceMatcher

from unidecode import unidecode

from library.metadata import deezer

MIN_SCORE = 0.72
MIN_TITLE = 0.8
MIN_ARTIST = 0.75
MAX_DURATION_DIFF = 30  # seconds
MAX_ALTERNATIVES = 4
# Words that mark a different recording, unless both titles have them
OTHER_VERSION = re.compile(
    r"\b(live|karaoke|cover|instrumental|remix|acoustic|slowed|sped up|nightcore|reverb|8d|tribute|"
    r"demo|unplugged|orchestral|piano version|a cappella|acapella)\b"
)
_FEATURING = re.compile(r"\s+(feat|ft|featuring)\.?\s.*$")
_BRACKETS = re.compile(r"[\(\[\{].*?[\)\]\}]")
_ARTIST_SEPARATORS = re.compile(r"\s*(?:,|;|/|&|\+|\bx\b|\band\b|\bfeat\.?|\bft\.?|\bfeaturing\b|\bwith\b)\s*")
_ISRC = re.compile(r"^[A-Z]{2}[A-Z0-9]{3}\d{7}$")


def _normal(text: str | None) -> str:
    text = unidecode(text or "").lower().replace("&", " and ")
    return " ".join(re.sub(r"[^a-z0-9 ]+", " ", text).split())


def _bare_title(title: str | None) -> str:
    """The title without what services add differently: "(feat. X)", "[Remastered]",
    " - Radio Edit" and the like."""
    title = _BRACKETS.sub(" ", title or "")
    title = title.split(" - ")[0]
    return " ".join(_FEATURING.sub("", title).split())


def core_title(title: str | None) -> str:
    return _normal(_bare_title(title))


def _similar(a: str, b: str) -> float:
    if not a or not b:
        return 0.0
    if a == b:
        return 1.0
    return SequenceMatcher(None, a, b).ratio()


def _artist_names(artists: list[str]) -> list[str]:
    names = []
    for artist in artists:
        names.append(_normal(artist))
        names.extend(_normal(part) for part in _ARTIST_SEPARATORS.split(artist or ""))
    return [n for n in dict.fromkeys(names) if n]


def _artist_score(wanted: list[str], candidate: list[str]) -> float:
    best = 0.0
    for a in wanted:
        for b in candidate:
            if a == b or (min(len(a), len(b)) >= 3 and (a in b or b in a)):
                return 1.0
            best = max(best, _similar(a, b))
    return best


def _duration_score(wanted_ms: int | None, candidate_s: int | None) -> float | None:
    if not wanted_ms or not candidate_s:
        return None
    diff = abs(wanted_ms / 1000 - candidate_s)
    for limit, value in ((3, 1.0), (8, 0.85), (15, 0.55), (MAX_DURATION_DIFF, 0.25)):
        if diff <= limit:
            return value
    return 0.0


def score(song: dict, candidate: dict) -> float:
    """0-1 confidence that a catalog track (as Deezer returns it) is the song."""
    title, candidate_title = song.get("title") or "", candidate.get("title") or ""
    title_score = max(
        _similar(core_title(title), core_title(candidate_title)),
        _similar(_normal(title), _normal(candidate_title)),
    )

    names = [(candidate.get("artist") or {}).get("name")]
    names += [c.get("name") for c in candidate.get("contributors") or []]
    # Catalog titles sometimes carry the featured artists instead of the artists
    feat = re.search(r"\((?:feat|ft|with)\.?\s+([^)]*)\)", candidate_title, re.I)
    if feat:
        names.append(feat.group(1))
    artist_score = _artist_score(_artist_names(song.get("artists") or []), _artist_names([n for n in names if n]))

    duration = _duration_score(song.get("duration_ms"), candidate.get("duration"))
    if duration is None:
        result = 0.55 * title_score + 0.45 * artist_score
    else:
        result = 0.45 * title_score + 0.35 * artist_score + 0.2 * duration

    wanted_versions = set(OTHER_VERSION.findall(_normal(title)))
    candidate_versions = set(OTHER_VERSION.findall(_normal(candidate_title)))
    if wanted_versions != candidate_versions:
        result -= 0.35
    album = (candidate.get("album") or {}).get("title")
    if song.get("album") and album and core_title(song["album"]) == core_title(album):
        result += 0.05
    if title_score < MIN_TITLE or artist_score < MIN_ARTIST or duration == 0.0:
        result = min(result, MIN_SCORE - 0.01)
    return max(0.0, min(1.0, result))


def _queries(song: dict) -> list[str]:
    # The catalog's search wants the letters as written: "durdevdan" misses "Đurđevdan".
    # Its artist:"" track:"" syntax finds nothing, so these are plain searches.
    title = _bare_title(song.get("title")) or (song.get("title") or "").strip()
    # Keep "remix", "live" and the like, which the bare title loses
    versions = set(OTHER_VERSION.findall(_normal(song.get("title"))))
    versions -= set(OTHER_VERSION.findall(_normal(title)))
    title = " ".join([title, *sorted(versions)])
    artists = song.get("artists") or []
    queries = [f"{artists[0]} {title}"] if artists else []
    # Without the artist, for songs whose artist the catalog spells differently
    queries.append(title)
    return [q for q in queries if q.strip()]


async def match(song: dict) -> dict:
    """{"track": the matched catalog track or None, "score", "alternatives"}: the
    closest other candidates, for the user to choose from when nothing fit."""
    isrc = (song.get("isrc") or "").upper().replace("-", "")
    if _ISRC.match(isrc):
        track = await deezer.track_by_isrc(isrc)
        # ISRCs are sometimes reused for another recording, so check it's the song
        if track and score(song, track) >= MIN_SCORE - 0.15:
            return {"track": deezer.track_shape(track), "score": 1.0, "alternatives": []}

    candidates: dict[int, tuple[float, int, dict]] = {}
    for query in _queries(song):
        try:
            results = await deezer.search_tracks(query)
        except deezer.DeezerError:
            continue
        for rank, candidate in enumerate(results):
            if candidate.get("id") and candidate.get("readable", True):
                current = score(song, candidate)
                known = candidates.get(candidate["id"])
                if known is None or current > known[0]:
                    candidates[candidate["id"]] = (current, rank, candidate)
        if any(s >= MIN_SCORE for s, _, _ in candidates.values()):
            break

    # Best score first, the catalog's order among equals
    ranked = sorted(candidates.values(), key=lambda c: (-c[0], c[1]))
    best = ranked[0] if ranked and ranked[0][0] >= MIN_SCORE else None
    others = [c for c in ranked if c is not best and c[0] >= 0.3][:MAX_ALTERNATIVES]
    return {
        "track": deezer.track_shape(best[2]) if best else None,
        "score": round(best[0] if best else (ranked[0][0] if ranked else 0.0), 3),
        "alternatives": [] if best else [deezer.track_shape(c[2]) for c in others],
    }


async def match_all(songs: list[dict]) -> list[dict]:
    """Matches [songs] concurrently; Deezer's pacing keeps the requests in its limit."""
    return await asyncio.gather(*(match(song) for song in songs))
