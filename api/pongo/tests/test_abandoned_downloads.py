import asyncio

from library import db
from library.track import downloads


def _fake_downloads(monkeypatch, seconds):
    """Makes every download take `seconds`, recording which ones started."""
    started = []

    async def fetch(stid):
        started.append(stid)
        await asyncio.sleep(seconds)
        return 1.0

    async def not_stored(_):
        return None

    monkeypatch.setattr(downloads, "_fetch", fetch)
    monkeypatch.setattr(db, "track_duration", not_stored)
    monkeypatch.setattr(downloads, "_slots", asyncio.Semaphore(2))
    monkeypatch.setattr(downloads.config, "MAX_CONCURRENT_DOWNLOADS", 2)
    return started


async def _abandon(album: str) -> None:
    """Starts an album's queue, then leaves it right away for another one."""
    tracks = downloads.ensure_tracks(downloads.queue_of([f"{album}{i}" for i in range(5)]))
    first = asyncio.create_task(anext(tracks))
    await asyncio.sleep(0.01)
    first.cancel()
    try:
        await first
    except asyncio.CancelledError:
        pass
    await tracks.aclose()


def test_leaving_queues_drops_downloads_that_had_not_started(monkeypatch):
    started = _fake_downloads(monkeypatch, 0.2)

    async def scenario():
        for album in "ABC":
            await _abandon(album)
        loop = asyncio.get_running_loop()
        start = loop.time()
        tracks = downloads.ensure_tracks(downloads.queue_of(["D0"]))
        assert await anext(tracks) == ("D0", 1.0)
        return loop.time() - start

    waited = asyncio.run(scenario())
    # Album A's two downloads had started and hold both slots; B's and C's never ran
    assert sorted(s for s in started if s[0] != "D") == ["A0", "A1"]
    assert waited < 0.45


def test_started_downloads_finish_after_the_caller_leaves(monkeypatch):
    started = _fake_downloads(monkeypatch, 0.05)

    async def scenario():
        waiting = asyncio.create_task(downloads.ensure_track("x"))
        await asyncio.sleep(0.01)
        waiting.cancel()
        await asyncio.sleep(0.01)
        assert "x" in downloads._tasks
        # A second caller joins the running download instead of starting another
        return await downloads.ensure_track("x")

    assert asyncio.run(scenario()) == 1.0
    assert started == ["x"]


def test_a_track_without_a_match_is_not_searched_again(monkeypatch):
    searches = []

    async def not_stored(_):
        return None

    async def full_track(stid):
        return {"title": "t", "artist": {"name": "a"}, "duration": 1}

    def find_video(track):
        searches.append(track)
        return None

    monkeypatch.setattr(db, "track_duration", not_stored)
    monkeypatch.setattr(downloads.deezer, "full_track", full_track)
    monkeypatch.setattr(downloads.matcher, "find_video", find_video)
    monkeypatch.setattr(downloads, "_no_match", {})

    async def scenario():
        for _ in range(2):
            try:
                await downloads.ensure_track("nomatch")
            except downloads.TrackUnavailable:
                pass

    asyncio.run(scenario())
    assert len(searches) == 1


def test_new_downloads_count_towards_the_users_limit(monkeypatch):
    _fake_downloads(monkeypatch, 0)
    monkeypatch.setattr(downloads.limits, "downloads", downloads.limits.SlidingWindow(1, 3600))

    async def scenario():
        assert await downloads.ensure_track("first", owner="user") == 1.0
        try:
            await downloads.ensure_track("second", owner="user")
        except downloads.TrackUnavailable as error:
            return str(error)

    assert "limit" in asyncio.run(scenario())
