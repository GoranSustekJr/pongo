import asyncio
import struct

import pytest

from library import db
from library.track import downloads, partial as partial_files
from library.track.partial import Partial


def _box(kind: bytes, payload: bytes) -> bytes:
    return struct.pack(">I4s", 8 + len(payload), kind) + payload


def _sidx(sizes: list[int], durations: list[int], timescale: int = 1000) -> bytes:
    payload = struct.pack(">IIIIIHH", 0, 1, timescale, 0, 0, 0, len(sizes))
    for size, duration in zip(sizes, durations):
        payload += struct.pack(">III", size, duration, 0x90000000)
    return _box(b"sidx", payload)


def _fragment(size: int) -> bytes:
    # A moof and an mdat that together take `size` bytes
    return _box(b"moof", b"\0" * 8) + _box(b"mdat", b"\1" * (size - 24))


def _fmp4(sizes=(100, 120, 80), durations=(10000, 10000, 5000)) -> bytes:
    head = _box(b"ftyp", b"M4A \0\0\0\0") + _box(b"moov", b"\0" * 40)
    return head + _sidx(list(sizes), list(durations)) + b"".join(_fragment(s) for s in sizes)


def test_the_layout_comes_from_the_index_at_the_start():
    data = _fmp4()
    layout = partial_files.parse_layout(data)
    assert layout.init_end == 16 + 48
    assert layout.total == len(data)
    first = len(data) - 300
    assert layout.fragments == [(first, 100, 10.0), (first + 100, 120, 10.0), (first + 220, 80, 5.0)]


def test_the_layout_waits_for_the_whole_index():
    data = _fmp4()
    # The sidx box ends after the 64-byte header and its own 68 bytes
    assert partial_files.parse_layout(data[:131]) is None
    assert partial_files.parse_layout(data[:132]) is not None


def test_audio_without_an_index_up_front_cant_be_streamed():
    data = _box(b"ftyp", b"M4A \0\0\0\0") + _box(b"moov", b"\0" * 40) + _fragment(100)
    with pytest.raises(ValueError):
        partial_files.parse_layout(data)


def test_the_playlist_lists_each_fragment_as_a_byte_range():
    layout = partial_files.parse_layout(_fmp4())
    text = partial_files.playlist(layout, "abc.m4a")
    assert '#EXT-X-MAP:URI="abc.m4a",BYTERANGE="64@0"' in text
    assert text.count("#EXT-X-BYTERANGE:") == 3
    assert "#EXT-X-PLAYLIST-TYPE:VOD" in text
    assert text.endswith("#EXT-X-ENDLIST\n")


def test_ranges():
    assert partial_files.byte_range(None, 100) is None
    assert partial_files.byte_range("bytes=0-1", 100) == (0, 1)
    assert partial_files.byte_range("bytes=10-", 100) == (10, 99)
    assert partial_files.byte_range("bytes=90-200", 100) == (90, 99)
    assert partial_files.byte_range("bytes=-30", 100) == (70, 99)
    for bad in ("bytes=100-", "bytes=5-2", "items=0-1"):
        with pytest.raises(ValueError):
            partial_files.byte_range(bad, 100)


async def _write_slowly(partial: Partial, data: bytes, piece: int = 50) -> None:
    partial.folder.mkdir(parents=True, exist_ok=True)
    with partial.path.open("wb") as file:
        for start in range(0, len(data), piece):
            partial.append(file, data[start:start + piece])
            await asyncio.sleep(0.01)
    partial.complete()


def test_readers_get_bytes_as_they_arrive(tmp_path):
    data = _fmp4()

    async def main():
        partial = Partial(tmp_path / "p")
        writing = asyncio.create_task(_write_slowly(partial, data))
        assert await partial.wait(lambda: partial.layout is not None)
        # Asked for before most of it is written
        got = b"".join([chunk async for chunk in partial.chunks(100, len(data) - 1)])
        await writing
        return got

    assert asyncio.run(main()) == data[100:]


def test_readers_stop_when_the_download_fails(tmp_path):
    async def main():
        partial = Partial(tmp_path / "p")
        partial.folder.mkdir()
        with partial.path.open("wb") as file:
            partial.append(file, _fmp4()[:200])
        asyncio.get_running_loop().call_later(0.05, partial.fail, "gone")
        return [chunk async for chunk in partial.chunks(0, 300)]

    with pytest.raises(RuntimeError):
        asyncio.run(main())


def _fake_fetches(monkeypatch, tmp_path):
    """Makes each download write a small streamable file, recording which ones started."""
    started = []

    async def fetch(stid):
        started.append(stid)
        await _write_slowly(downloads._partials[stid], _fmp4())
        return 25.0

    async def not_stored(_):
        return None

    monkeypatch.setattr(downloads, "_fetch", fetch)
    monkeypatch.setattr(db, "track_duration", not_stored)
    monkeypatch.setattr(downloads.config, "TEMP_DIR", tmp_path)
    monkeypatch.setattr(downloads, "_slots", asyncio.Semaphore(2))
    monkeypatch.setattr(downloads, "_partials", {})
    return started


def test_streaming_shares_the_download_and_the_limit(monkeypatch, tmp_path):
    started = _fake_fetches(monkeypatch, tmp_path)
    monkeypatch.setattr(downloads.limits, "downloads", downloads.limits.SlidingWindow(1, 3600))

    async def main():
        partial = await downloads.stream_track("s1", owner="user")
        assert partial.layout is not None and partial.streamed
        assert await downloads.ensure_track("s1", owner="user") == 25.0
        assert downloads.streaming("s1") is partial
        with pytest.raises(downloads.TrackUnavailable):
            await downloads.stream_track("s2", owner="user")

    asyncio.run(main())
    assert started == ["s1"]


def test_tracks_in_the_library_are_not_streamed(monkeypatch, tmp_path):
    _fake_fetches(monkeypatch, tmp_path)

    async def stored(_):
        return 100.0

    monkeypatch.setattr(db, "track_duration", stored)
    with pytest.raises(downloads.NotStreamable):
        asyncio.run(downloads.stream_track("s"))


def test_audio_that_cant_be_piped_is_downloaded_whole(monkeypatch, tmp_path):
    async def pipe(video_id, partial):
        raise downloads.TrackUnavailable("no m4a")

    async def whole(video_id, folder):
        return folder / "whole.m4a"

    monkeypatch.setattr(downloads, "_pipe_audio", pipe)
    monkeypatch.setattr(downloads, "_download_audio", whole)
    partial = Partial(tmp_path / "p")
    audio = asyncio.run(downloads._download_streamable("v", tmp_path, partial))
    assert audio == tmp_path / "whole.m4a"
    assert partial.failed and downloads.streaming("v") is None
