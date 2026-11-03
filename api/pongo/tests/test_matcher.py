from library.track import matcher

TRACK = {"title": "One More Time", "artist": "Daft Punk", "duration": 320}


def candidate(video_id="a", title="One More Time", artist="Daft Punk", duration=321):
    return {
        "videoId": video_id,
        "title": title,
        "artists": [{"name": artist}],
        "duration_seconds": duration,
    }


def test_picks_the_same_recording():
    wrong = candidate("wrong", title="Something Else", artist="Someone Else")
    assert matcher.best_match(TRACK, [wrong, candidate("right")])[0] == "right"


def test_rejects_a_different_length():
    assert matcher.best_match(TRACK, [candidate(duration=420)]) is None


def test_rejects_other_versions_unless_the_catalog_title_has_them():
    assert matcher.best_match(TRACK, [candidate(title="One More Time (Karaoke)", artist="Hits")]) is None
    remix = {"title": "One More Time (Remix)", "artist": "Daft Punk", "duration": 320}
    assert matcher.best_match(remix, [candidate(title="One More Time (Remix)")]) is not None


def test_handles_accents_and_featured_artists():
    track = {"title": "Tití Me Preguntó", "artist": "Bad Bunny", "duration": 243}
    result = candidate(title="Titi Me Pregunto", duration=244)
    result["artists"] = [{"name": "Bad Bunny"}, {"name": "Someone"}]
    assert matcher.best_match(track, [result]) is not None
