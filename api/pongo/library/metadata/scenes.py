"""Scenes: groups of artists that belong together, such as Balkan pop or tango, worked
out from Deezer's similar artists, so mixes made from a library keep to one kind of music.

How a song sounds says nothing of its language or style, so a mood alone would put
Croatian pop, American pop and tango in one mix.
"""
import asyncio
import logging

import httpx

from library import db
from library.metadata import deezer

log = logging.getLogger(__name__)

MAX_ARTISTS = 300
# Similar artists are looked up again after this many days
_FRESH_DAYS = 30
# Artists alike enough to share a scene share at least this many similar artists
_SHARED = 3
# How long a request waits for Deezer before answering with what's known
_WAIT = 8.0

_fetching: dict[str, asyncio.Task] = {}


async def _fetch(artist_id: str) -> None:
    try:
        related = await deezer.related_ids(artist_id)
    except (deezer.DeezerError, httpx.HTTPError) as error:
        log.info("No similar artists of %s: %s", artist_id, error)
        return
    await db.execute(
        """
        INSERT INTO artist_related (artist_id, related) VALUES (%s, %s)
        ON CONFLICT (artist_id) DO UPDATE SET related = EXCLUDED.related, fetched_at = now()
        """,
        (artist_id, related),
    )


async def _known(artist_ids: list[str]) -> dict[str, set[str]]:
    rows = await db.fetch_all(
        "SELECT artist_id, related FROM artist_related WHERE artist_id = ANY(%s)"
        " AND fetched_at > now() - make_interval(days => %s)",
        (artist_ids, _FRESH_DAYS),
    )
    return {artist: set(related) for artist, related in rows}


async def related(artist_ids: list[str], wait: float = _WAIT) -> dict[str, set[str]]:
    """The similar artists of each of the artists, as far as known within [wait] seconds.

    Those still being looked up then are saved for the next time."""
    known = await _known(artist_ids)
    missing = [a for a in artist_ids if a not in known]
    for artist in missing:
        if artist not in _fetching:
            task = asyncio.create_task(_fetch(artist))
            _fetching[artist] = task
            task.add_done_callback(lambda _, artist=artist: _fetching.pop(artist, None))
    tasks = [_fetching[a] for a in missing if a in _fetching]
    if tasks:
        await asyncio.wait(tasks, timeout=wait)
        known |= await _known(missing)
    return known


def group(artist_ids: list[str], related: dict[str, set[str]]) -> list[list[str]]:
    """The artists in scenes, biggest first: two are in one if either is similar to the
    other, or they share enough similar artists. Unknown artists are alone in theirs."""
    parent = {a: a for a in artist_ids}

    def root(a):
        while parent[a] != a:
            parent[a] = parent[parent[a]]
            a = parent[a]
        return a

    for index, a in enumerate(artist_ids):
        for b in artist_ids[index + 1:]:
            ra, rb = related.get(a, set()), related.get(b, set())
            if b in ra or a in rb or len(ra & rb) >= _SHARED:
                parent[root(a)] = root(b)
    groups: dict[str, list[str]] = {}
    for a in artist_ids:
        groups.setdefault(root(a), []).append(a)
    return sorted(groups.values(), key=len, reverse=True)
