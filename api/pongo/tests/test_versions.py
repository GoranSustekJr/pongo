import pytest

from library.routes import versions
from library.track import matcher


@pytest.mark.parametrize(
    "text, expected",
    [
        ("-ajlhPUKiGQ", "-ajlhPUKiGQ"),
        ("https://www.youtube.com/watch?v=-ajlhPUKiGQ&list=x", "-ajlhPUKiGQ"),
        ("https://music.youtube.com/watch?v=0JCvfYGKkyc", "0JCvfYGKkyc"),
        ("https://youtu.be/0JCvfYGKkyc?si=abc", "0JCvfYGKkyc"),
        ("https://www.youtube.com/shorts/0JCvfYGKkyc", "0JCvfYGKkyc"),
        ("  0JCvfYGKkyc ", "0JCvfYGKkyc"),
        ("not a video", None),
        ("https://example.com/watch?v=short", None),
        ("", None),
    ],
)
def test_videos_are_read_from_ids_and_links(text, expected):
    assert versions.video_id(text) == expected


def test_versions_carry_album_and_score():
    track = {"title": "Minut' Srca Tvog", "artist": "Magazin", "duration": 261}
    result = {
        "videoId": "-ajlhPUKiGQ", "title": "Minut srca tvog", "artists": [{"name": "Magazin"}],
        "album": {"name": "Nebo boje moje ljubavi", "id": "MPREb_x"}, "duration_seconds": 263,
        "thumbnails": [{"url": "small"}, {"url": "big"}],
    }
    version = matcher._version(result, "song", track)
    assert version["album"] == "Nebo boje moje ljubavi" and version["album_id"] == "MPREb_x"
    assert version["image"] == "big" and version["score"] > 0.9
    assert matcher._version({"title": "No id"}, "video", track) is None


import asyncio

from library import db
from library.track import downloads


def _fake_store(monkeypatch, fail=False):
    """A track stored with video "old" and audio 7; records what's fetched and written."""
    calls = {"fetched": [], "written": [], "deleted": []}

    async def fetch(stid, chosen=None):
        calls["fetched"].append((stid, chosen))
        if fail:
            raise downloads.TrackUnavailable("gone")
        return 263.0

    async def fetch_one(query, params=()):
        if query.startswith("SELECT ytvid, auid, duration FROM track"):
            return ("old", 7, 262.0)
        if query.startswith("DELETE FROM audio"):
            calls["deleted"].append(params[0])
            return None
        raise AssertionError(query)

    async def execute(query, params=()):
        calls["written"].append(params)

    monkeypatch.setattr(downloads, "_fetch", fetch)
    monkeypatch.setattr(db, "fetch_one", fetch_one)
    monkeypatch.setattr(db, "execute", execute)
    monkeypatch.setattr(downloads, "_tasks", {})
    monkeypatch.setattr(downloads, "_partials", {})
    return calls


def test_a_chosen_version_replaces_the_audio_and_is_remembered(monkeypatch, tmp_path):
    monkeypatch.setattr(downloads.config, "TEMP_DIR", tmp_path)
    calls = _fake_store(monkeypatch)
    assert asyncio.run(downloads.use_version("1", "-ajlhPUKiGQ", "user")) == 263.0
    assert calls["fetched"] == [("1", "-ajlhPUKiGQ")]
    assert calls["written"] == [("1", "-ajlhPUKiGQ", "user")]
    assert calls["deleted"] == [7]


def test_a_failed_download_changes_nothing(monkeypatch, tmp_path):
    monkeypatch.setattr(downloads.config, "TEMP_DIR", tmp_path)
    calls = _fake_store(monkeypatch, fail=True)
    with pytest.raises(downloads.TrackUnavailable):
        asyncio.run(downloads.use_version("1", "-ajlhPUKiGQ", "user"))
    assert calls["written"] == [] and calls["deleted"] == []


def test_choosing_the_playing_version_only_remembers_it(monkeypatch, tmp_path):
    monkeypatch.setattr(downloads.config, "TEMP_DIR", tmp_path)
    calls = _fake_store(monkeypatch)
    assert asyncio.run(downloads.use_version("1", "old", "user")) == 262.0
    assert calls["fetched"] == [] and calls["written"] == [("1", "old", "user")] and calls["deleted"] == []
