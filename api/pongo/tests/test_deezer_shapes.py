from library.metadata import deezer

COVER = {"cover_xl": "xl.jpg", "cover_small": "small.jpg"}


def test_track_ids_are_strings_and_album_has_images():
    shaped = deezer.track_shape(
        {
            "id": 1,
            "title": "Song",
            "duration": 100,
            "artist": {"id": 2, "name": "Artist"},
            "album": {"id": 3, "title": "Album", **COVER},
        }
    )
    assert shaped["id"] == "1"
    assert shaped["artists"] == [{"id": "2", "name": "Artist"}]
    assert shaped["album"]["id"] == "3"
    assert shaped["album"]["images"][0] == {"url": "xl.jpg", "width": 1000, "height": 1000}


def test_contributors_win_over_the_primary_artist():
    shaped = deezer.track_shape(
        {
            "id": 1,
            "artist": {"id": 2, "name": "A"},
            "contributors": [{"id": 2, "name": "A"}, {"id": 5, "name": "B"}],
        }
    )
    assert [a["name"] for a in shaped["artists"]] == ["A", "B"]


def test_album_without_artist_uses_the_given_one():
    shaped = deezer.album_shape({"id": 1, "title": "X", "record_type": "compile"}, {"id": 9, "name": "Y"})
    assert shaped["album_type"] == "compilation"
    assert shaped["artists"] == [{"id": "9", "name": "Y"}]
