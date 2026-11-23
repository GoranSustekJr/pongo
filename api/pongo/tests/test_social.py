from library.routes import social


def test_codes_are_read_from_what_people_type_or_paste():
    assert social.normalize_code("ab3k-9xyz") == "AB3K9XYZ"
    assert social.normalize_code(" pongo://friend/AB3K9XYZ/ ") == "AB3K9XYZ"
    assert social.normalize_code("") == ""


def test_others_see_neither_hidden_tracks_nor_extra_fields():
    data = {
        "title": "Za dom", "cover": "jpeg",
        "tracks": [
            {"stid": "1", "title": "A", "artists": "[]", "image": None, "album": None, "hidden": False, "x": 1},
            {"stid": "2", "title": "B", "artists": "[]", "image": "b.jpg", "album": None, "hidden": True},
            {"stid": "3", "title": "C", "artists": "[]", "image": "c.jpg", "album": None},
        ],
    }
    assert [t["stid"] for t in social.shown_tracks(data)] == ["1", "3"]
    assert "hidden" not in social.shown_tracks(data)[0] and "x" not in social.shown_tracks(data)[0]
    summary = social.summarize("k", data)
    assert summary == {"key": "k", "title": "Za dom", "count": 2, "has_cover": True, "image": "c.jpg"}


def test_an_empty_playlist_summarizes():
    assert social.summarize("k", {"title": None, "tracks": None})["count"] == 0


def test_codes_avoid_letters_that_look_alike():
    assert not set("01IO") & set(social._ALPHABET)
