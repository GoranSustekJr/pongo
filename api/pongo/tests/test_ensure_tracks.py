import asyncio

from library.track import downloads


def _fake_fetch(monkeypatch, delays):
    """Makes ensure_track sleep for each stid's delay, recording the order fetches start."""
    started = []

    async def ensure_track(stid, owner=None):
        started.append(stid)
        await asyncio.sleep(delays[stid])
        if stid.startswith("bad"):
            raise downloads.TrackUnavailable(stid)
        return float(len(stid))

    monkeypatch.setattr(downloads, "ensure_track", ensure_track)
    monkeypatch.setattr(downloads.config, "MAX_CONCURRENT_DOWNLOADS", 2)
    return started


async def _collect(queue):
    return [item async for item in downloads.ensure_tracks(queue)]


def test_yields_in_order_while_fetching_ahead(monkeypatch):
    _fake_fetch(monkeypatch, {"a": 0.2, "bb": 0.2, "ccc": 0.2})
    queue = downloads.queue_of(["a", "bb", "ccc"])
    loop = asyncio.new_event_loop()
    start = loop.time()
    result = loop.run_until_complete(_collect(queue))
    elapsed = loop.time() - start
    loop.close()
    assert result == [("a", 1.0), ("bb", 2.0), ("ccc", 3.0)]
    # Two at a time takes 0.4s, one at a time would take 0.6s
    assert elapsed < 0.5


def test_unavailable_tracks_give_none(monkeypatch):
    _fake_fetch(monkeypatch, {"a": 0, "bad": 0})
    result = asyncio.run(_collect(downloads.queue_of(["bad", "a"])))
    assert result == [("bad", None), ("a", 1.0)]


def test_waits_for_stids_sent_one_at_a_time(monkeypatch):
    started = _fake_fetch(monkeypatch, {"a": 0, "bb": 0})

    async def scenario():
        queue = asyncio.Queue()
        tracks = downloads.ensure_tracks(queue)
        queue.put_nowait("a")
        assert await anext(tracks) == ("a", 1.0)
        # Nothing else queued yet, so it waits for the next stid instead of ending
        queue.put_nowait("bb")
        queue.put_nowait(None)
        assert [item async for item in tracks] == [("bb", 2.0)]

    asyncio.run(scenario())
    assert started == ["a", "bb"]


def test_never_runs_more_than_the_limit_ahead(monkeypatch):
    started = _fake_fetch(monkeypatch, {s: 0.01 for s in ["a", "b", "c", "d"]})

    async def scenario():
        tracks = downloads.ensure_tracks(downloads.queue_of(["a", "b", "c", "d"]))
        await anext(tracks)
        assert started == ["a", "b"]
        await tracks.aclose()

    asyncio.run(scenario())
