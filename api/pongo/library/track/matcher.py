"""Find the YouTube video for a catalog track."""
import logging
import re
from difflib import SequenceMatcher

from unidecode import unidecode
from ytmusicapi import YTMusic

log = logging.getLogger(__name__)

MIN_SCORE = 0.6
MAX_DURATION_DIFF = 20  # seconds
# Words that mark a different recording, unless the catalog title has them too
OTHER_VERSION = re.compile(
    r"\b(live|karaoke|cover|instrumental|remix|acoustic|slowed|sped up|nightcore|reverb|8d|tribute)\b"
)

_ytmusic = YTMusic()


def _normal(text: str) -> str:
    text = unidecode(text or "").lower()
    return re.sub(r"[^a-z0-9 ]+", " ", text).strip()


def _base_title(text: str) -> str:
    return _normal(re.sub(r"[\(\[].*?[\)\]]", " ", text or ""))


def _similar(a: str, b: str) -> float:
    return SequenceMatcher(None, a, b).ratio()


def score(track: dict, candidate: dict) -> float:
    """0-1 confidence that a search result is the same recording as the track."""
    title, candidate_title = _normal(track["title"]), _normal(candidate.get("title"))
    title_score = max(
        _similar(title, candidate_title),
        _similar(_base_title(track["title"]), _base_title(candidate.get("title"))),
    )

    names = [_normal(a.get("name")) for a in candidate.get("artists") or []]
    artist = _normal(track["artist"])
    artist_score = max(
        (1.0 if artist == n or artist in n or n in artist else _similar(artist, n) for n in names if n),
        default=0.0,
    )

    result = 0.55 * title_score + 0.45 * artist_score
    versions = set(OTHER_VERSION.findall(candidate_title)) - set(OTHER_VERSION.findall(title))
    if versions:
        result -= 0.4
    return result


def best_match(track: dict, candidates: list[dict]) -> tuple[str, float] | None:
    best = None
    for candidate in candidates:
        video_id, length = candidate.get("videoId"), candidate.get("duration_seconds")
        if not video_id or length is None:
            continue
        if track["duration"] and abs(length - track["duration"]) > MAX_DURATION_DIFF:
            continue
        current = score(track, candidate)
        if current >= MIN_SCORE and (best is None or current > best[1]):
            best = (video_id, current)
    return best


def find_video(track: dict) -> tuple[str, float] | None:
    """Blocking. Prefers official songs, falling back to music videos."""
    query = f"{track['title']} {track['artist']}"
    for result_filter in ("songs", "videos"):
        candidates = _ytmusic.search(query, filter=result_filter, limit=10)
        match = best_match(track, candidates)
        if match:
            return match
    return None
