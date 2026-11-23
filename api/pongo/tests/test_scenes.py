from library.metadata import deezer, scenes


def test_similar_artists_share_a_scene():
    related = {
        "jala": {"buba", "x1", "x2"},
        "buba": {"jala", "x1"},
        "magazin": {"s1", "s2", "s3", "s4"},
        "severina": {"s1", "s2", "s3"},
        "billie": {"lana", "finneas"},
    }
    groups = scenes.group(["jala", "billie", "magazin", "buba", "severina", "tango"], related)
    assert sorted(map(sorted, groups)) == [["billie"], ["buba", "jala"], ["magazin", "severina"], ["tango"]]
    # Biggest first
    assert len(groups[0]) == 2


def test_genre_artists_come_from_its_tracks():
    def track(artist_id):
        return {"id": 1, "artist": {"id": artist_id, "name": f"a{artist_id}"}}

    chart = {"tracks": {"data": [track(1), track(2), track(2), track(3)]}, "artists": {"data": []}}
    assert [a["id"] for a in deezer.genre_artists(chart, 2)] == ["2", "1"]
