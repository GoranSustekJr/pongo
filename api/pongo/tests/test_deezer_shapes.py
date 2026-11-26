import asyncio

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


def test_search_keeps_plus_signs_for_deezers_double_decoding(monkeypatch):
    queries = []

    async def fake_get(path, **params):
        queries.append(params["q"])
        return {"data": []}

    monkeypatch.setattr(deezer, "_get", fake_get)
    asyncio.run(deezer.search("z++"))
    assert set(queries) == {"z%2B%2B"}


def test_charts_are_shaped_for_the_app(monkeypatch):
    async def chart(path, **params):
        assert path == "/chart/0"
        return {
            "tracks": {"data": [{"id": 1, "title": "Song", "duration": 100, "artist": {"id": 2, "name": "A"}}]},
            "artists": {"data": [{"id": 2, "name": "A", "picture_xl": "xl.jpg"}]},
            "playlists": {"data": [{"id": 3, "title": "Hits", "picture_xl": "xl.jpg"}]},
        }

    monkeypatch.setattr(deezer, "_get", chart)
    charts = asyncio.run(deezer.get_charts())
    assert charts["tracks"][0]["id"] == "1"
    assert charts["artists"][0]["images"][0]["url"] == "xl.jpg"
    assert charts["playlists"][0]["name"] == "Hits"


def test_charts_failure_leaves_the_sections_empty(monkeypatch):
    async def failing(path, **params):
        raise deezer.DeezerError("down")

    monkeypatch.setattr(deezer, "_get", failing)
    assert asyncio.run(deezer.get_charts()) == {"tracks": [], "artists": [], "playlists": []}


def test_genre_page_has_the_genres_charts(monkeypatch):
    async def get(path, **params):
        if path == "/genre/116":
            return {"id": 116, "name": "Rap", "picture_xl": "rap.jpg"}
        assert path == "/chart/116"
        return {
            "tracks": {"data": [{"id": 1, "title": "Song", "duration": 100, "artist": {"id": 2, "name": "A"}}]},
            "albums": {"data": [{"id": 4, "title": "Record", "artist": {"id": 2, "name": "A"}, **COVER}]},
            "artists": {"data": [{"id": 2, "name": "A", "picture_xl": "xl.jpg"}]},
            "playlists": {"data": [{"id": 3, "title": "Rap hits", "picture_xl": "xl.jpg"}]},
        }

    monkeypatch.setattr(deezer, "_get", get)
    page = asyncio.run(deezer.get_genre_page("116"))
    assert page["name"] == "Rap"
    assert page["icons"][0]["url"] == "rap.jpg"
    assert page["tracks"][0]["id"] == "1"
    assert page["albums"][0]["artists"][0]["name"] == "A"
    assert page["playlists"][0]["name"] == "Rap hits"


def test_charts_follow_the_listeners_country(monkeypatch):
    paths = []

    async def get(path, **params):
        paths.append(path)
        if path.startswith("/playlist/"):
            return {"data": [
                {"id": 1, "title": "A1", "artist": {"id": 7, "name": "Seven"}},
                {"id": 2, "title": "B", "artist": {"id": 8, "name": "Eight"}},
                {"id": 3, "title": "A2", "artist": {"id": 7, "name": "Seven"}},
                {"id": 4, "title": "Gone", "readable": False, "artist": {"id": 9, "name": "Nine"}},
            ]}
        return {"data": [
            {"id": 1116189071, "title": "Top Turkey"}, {"id": 1362526495, "title": "Top Ukraine"},
            {"id": 1111142221, "title": "Top UK"}, {"id": 3155776842, "title": "Top Worldwide"},
            {"id": 5, "title": "Top Women UK"},
        ]}

    monkeypatch.setattr(deezer, "_get", get)
    charts = asyncio.run(deezer.get_charts("gb"))
    assert paths[0] == "/playlist/1111142221/tracks"
    assert [t["id"] for t in charts["tracks"]] == ["1", "2", "3"]
    assert [a["name"] for a in charts["artists"]] == ["Seven", "Eight"]
    # The UK's charts, not Ukraine's, then the worldwide one
    assert [p["name"] for p in charts["playlists"]] == ["Top UK", "Top Women UK", "Top Worldwide"]


def test_countries_without_a_chart_get_a_neighbours_or_the_worldwide_one():
    assert deezer.chart_for("BA") == deezer.COUNTRY_CHARTS["HR"]
    assert deezer.chart_for("IS") == ("Worldwide", deezer.WORLDWIDE_CHART)
    assert deezer.chart_for(None) is None and deezer.chart_for("") is None


def test_worldwide_charts_are_listed_once(monkeypatch):
    async def get(path, **params):
        if path.startswith("/playlist/"):
            return {"data": []}
        return {"data": [{"id": 3155776842, "title": "Top Worldwide"}, {"id": 6, "title": "Top Women Worldwide"}]}

    monkeypatch.setattr(deezer, "_get", get)
    playlists = asyncio.run(deezer.get_charts("IS"))["playlists"]
    assert [p["name"] for p in playlists] == ["Top Worldwide", "Top Women Worldwide"]
