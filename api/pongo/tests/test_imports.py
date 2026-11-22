import asyncio
import json

import pytest

from library.imports import links, matching
from library.metadata import deezer


# Links
@pytest.mark.parametrize(
    "link, expected",
    [
        ("https://open.spotify.com/playlist/37i9dQZF1DXcBWIGoYBM5M?si=abc", ("spotify", "playlist", "37i9dQZF1DXcBWIGoYBM5M", None)),
        ("open.spotify.com/intl-de/album/0ETFjACtuP2ADo6LFhL6HN", ("spotify", "album", "0ETFjACtuP2ADo6LFhL6HN", None)),
        ("https://open.spotify.com/user/someone/playlist/37i9dQZF1DXcBWIGoYBM5M", ("spotify", "playlist", "37i9dQZF1DXcBWIGoYBM5M", None)),
        ("spotify:playlist:37i9dQZF1DXcBWIGoYBM5M", ("spotify", "playlist", "37i9dQZF1DXcBWIGoYBM5M", None)),
        ("https://spotify.link/AbCdEf", ("spotify", "short", "https://spotify.link/AbCdEf", None)),
        ("https://music.apple.com/hr/playlist/moja/pl.u-AbC123xyz", ("apple_music", "playlist", "pl.u-AbC123xyz", "hr")),
        ("https://music.apple.com/us/album/abbey-road/1441164426?i=1441164430", ("apple_music", "album", "1441164426", "us")),
        ("https://music.apple.com/playlist/x/pl.f4d106fed2bd41149aaacabb233eb5eb", ("apple_music", "playlist", "pl.f4d106fed2bd41149aaacabb233eb5eb", "us")),
    ],
)
def test_links_are_parsed(link, expected):
    assert links.parse(link) == expected


@pytest.mark.parametrize(
    "link, reason",
    [
        ("https://open.spotify.com/collection/tracks", "liked_songs"),
        ("spotify:collection:tracks", "liked_songs"),
        ("https://music.apple.com/library/playlist/p.abc", "private"),
        ("https://open.spotify.com/track/4HCOHRCSQelz2GPX8iTamO", "unsupported"),
        ("https://open.spotify.com/playlist/../../etc", "unsupported"),
        ("https://example.com/playlist/37i9dQZF1DXcBWIGoYBM5M", "unsupported"),
        ("https://music.apple.com.evil.com/us/album/x/1", "unsupported"),
        ("", "unsupported"),
    ],
)
def test_unreadable_links_say_why(link, reason):
    with pytest.raises(links.LinkError) as error:
        links.parse(link)
    assert error.value.reason == reason


def _spotify_html(entity) -> str:
    data = {"props": {"pageProps": {"state": {"data": {"entity": entity}}}}}
    return f'<script id="__NEXT_DATA__" type="application/json">{json.dumps(data)}</script>'


def test_spotify_page_lists_songs_and_skips_episodes():
    page = links.spotify_page(
        _spotify_html({
            "name": "Mix",
            "subtitle": "Someone",
            "coverArt": {"sources": [{"url": "small", "width": 60}, {"url": "big", "width": 640}]},
            "trackList": [
                {"title": "Song", "subtitle": "A, B", "duration": 200000, "entityType": "track"},
                {"title": "Podcast", "subtitle": "Show", "duration": 1, "entityType": "episode"},
            ],
        }),
        "playlist",
    )
    assert page["name"] == "Mix" and page["image"] == "big"
    assert page["tracks"] == [
        {"title": "Song", "artists": ["A", "B"], "album": None, "duration_ms": 200000, "isrc": None}
    ]
    assert page["skipped"] == 1 and not page["truncated"] and page["total"] == 2


def test_a_full_spotify_embed_may_be_cut_off():
    songs = [{"title": f"S{i}", "subtitle": "A", "entityType": "track"} for i in range(100)]
    page = links.spotify_page(_spotify_html({"name": "Big", "trackList": songs}), "playlist")
    assert page["truncated"] and page["total"] is None
    album = links.spotify_page(_spotify_html({"name": "Box", "trackList": songs}), "album")
    assert not album["truncated"] and album["tracks"][0]["album"] == "Box"


def test_a_private_spotify_playlist_is_not_found():
    with pytest.raises(links.LinkError) as error:
        links.spotify_page('<script id="__NEXT_DATA__" type="application/json">{"props": {}}</script>', "playlist")
    assert error.value.reason == "not_found"


def _apple_html(header, items) -> str:
    data = {"data": [{"data": {"sections": [
        {"itemKind": "containerDetailHeaderLockup", "items": [header]},
        {"itemKind": "trackLockup", "items": items},
    ]}}]}
    return f'<script type="application/json" id="serialized-server-data">{json.dumps(data)}</script>'


def test_apple_page_reads_artists_albums_and_the_cover():
    html = _apple_html(
        {"title": "Hits", "trackCount": 3, "subtitleLinks": [{"title": "Apple Music"}],
         "artwork": {"dictionary": {"url": "https://img/{w}x{h}{c}.{f}"}}},
        [
            {"title": "One", "duration": 1000, "subtitleLinks": [{"title": "A"}, {"title": "B"}],
             "tertiaryLinks": [{"title": "Record - Single"}], "contentDescriptor": {"kind": "song"}},
            {"title": "Two", "artistName": "C", "contentDescriptor": {"kind": "song"}},
        ],
    )
    page = links.apple_page(html, "playlist")
    assert page["image"] == "https://img/600x600bb.jpg"
    assert page["tracks"][0] == {"title": "One", "artists": ["A", "B"], "album": "Record", "duration_ms": 1000, "isrc": None}
    assert page["tracks"][1]["artists"] == ["C"]
    assert page["truncated"] and page["total"] == 3


def test_apple_album_songs_take_the_album_artist():
    html = _apple_html({"title": "LP", "trackCount": 1, "subtitleLinks": [{"title": "Band"}]}, [{"title": "One"}])
    page = links.apple_page(html, "album")
    assert page["tracks"][0]["artists"] == ["Band"] and page["tracks"][0]["album"] == "LP"
    assert not page["truncated"]


# Matching
def _candidate(title, artist, duration=200, album="Album", **extra):
    return {"id": 1, "title": title, "artist": {"id": 2, "name": artist}, "duration": duration,
            "album": {"id": 3, "title": album}, **extra}


def test_titles_lose_what_services_add():
    assert matching.core_title("Come Together - Remastered 2009") == "come together"
    assert matching.core_title("Song (feat. Someone) [From X]") == "song"
    assert matching.core_title("Song feat. Someone") == "song"
    assert matching.core_title("Dancing With Myself") == "dancing with myself"
    assert matching.core_title("Đurđevdan") == matching.core_title("Durdevdan")


def test_the_same_song_scores_high():
    song = {"title": "Come Together - Remastered 2009", "artists": ["The Beatles"], "duration_ms": 259946}
    assert matching.score(song, _candidate("Come Together (Remastered 2009)", "The Beatles", 259)) > 0.95


def test_a_featured_artist_in_the_catalog_title_counts():
    song = {"title": "Uptown Funk", "artists": ["Bruno Mars"], "duration_ms": 270000}
    assert matching.score(song, _candidate("Uptown Funk (feat. Bruno Mars)", "Mark Ronson", 270)) >= matching.MIN_SCORE


@pytest.mark.parametrize(
    "candidate",
    [
        _candidate("Song (Live)", "Artist"),
        _candidate("Song (Karaoke Version)", "Artist"),
        _candidate("Song", "Somebody Else"),
        _candidate("Another Song Entirely", "Artist"),
        _candidate("Song", "Artist", duration=400),
    ],
)
def test_other_recordings_are_not_matches(candidate):
    song = {"title": "Song", "artists": ["Artist"], "duration_ms": 200000}
    assert matching.score(song, candidate) < matching.MIN_SCORE


def test_a_live_song_matches_a_live_recording():
    song = {"title": "Song - Live", "artists": ["Artist"], "duration_ms": None}
    assert matching.score(song, _candidate("Song (Live)", "Artist")) >= matching.MIN_SCORE


def test_searches_keep_accents_and_version_words():
    assert matching._queries({"title": "Đurđevdan (feat. X)", "artists": ["Goran Bregović"]}) == [
        "Goran Bregović Đurđevdan", "Đurđevdan"]
    assert matching._queries({"title": "Song - Live", "artists": []}) == ["Song live"]


def test_isrc_matches_first(monkeypatch):
    found = _candidate("Blinding Lights", "The Weeknd", 200)

    async def by_isrc(isrc):
        assert isrc == "USUG11904206"
        return found

    async def search(query, limit=10):
        raise AssertionError("an ISRC match needs no search")

    monkeypatch.setattr(deezer, "track_by_isrc", by_isrc)
    monkeypatch.setattr(deezer, "search_tracks", search)
    song = {"title": "Blinding Lights", "artists": ["The Weeknd"], "duration_ms": 200040, "isrc": "usug1-1904206"}
    result = asyncio.run(matching.match(song))
    assert result["track"]["id"] == "1" and result["score"] == 1.0


def test_no_match_offers_the_closest_songs(monkeypatch):
    async def search(query, limit=10):
        return [
            {**_candidate("Song (Extended Version)", "Artist", 500), "id": 7},
            {**_candidate("Unrelated", "Nobody"), "id": 8},
        ]

    monkeypatch.setattr(deezer, "search_tracks", search)
    result = asyncio.run(matching.match({"title": "Song", "artists": ["Artist"], "duration_ms": 200000}))
    assert result["track"] is None
    assert [a["id"] for a in result["alternatives"]] == ["7"]
