import asyncio

from library.metadata import deezer


def _track(track_id, artist_id):
    return {"id": track_id, "title": f"t{track_id}", "duration": 200,
            "artist": {"id": artist_id, "name": f"a{artist_id}"}}


def test_follows_the_latest_seed_and_skips_excluded(monkeypatch):
    responses = {
        "/track/1": _track(1, 10),
        "/track/2": _track(2, 20),
        "/artist/10/related": {"data": [{"id": 11}]},
        "/artist/10/radio": {"data": [_track(1, 10), _track(100, 10), _track(101, 10)]},
        "/artist/11/radio": {"data": [_track(110, 11), _track(100, 10)]},
        "/artist/20/radio": {"data": [_track(200, 20)]},
    }

    async def get(path, **_):
        if path not in responses:
            raise deezer.DeezerError(path)
        return responses[path]

    monkeypatch.setattr(deezer, "_get", get)
    mix = asyncio.run(deezer.mix_candidates(["1", "2"], exclude={"101"}))
    # Round robin over the radios of 10, its related 11, then the older seed's 20
    assert [t["id"] for t in mix] == ["110", "200", "100"]


def test_no_known_seeds_give_no_candidates(monkeypatch):
    async def get(path, **_):
        raise deezer.DeezerError(path)

    monkeypatch.setattr(deezer, "_get", get)
    assert asyncio.run(deezer.mix_candidates(["1"], exclude=set())) == []


def test_anchors_keep_the_mix_to_its_own_artists(monkeypatch):
    responses = {
        "/track/1": _track(1, 10),
        "/track/5": _track(5, 50),
        "/artist/10/related": {"data": [{"id": 11}]},
        "/artist/10/radio": {"data": [_track(99, 77), _track(100, 10)]},
        "/artist/11/radio": {"data": [_track(110, 11)]},
        "/artist/50/radio": {"data": [_track(500, 50)]},
    }

    async def get(path, **_):
        if path not in responses:
            raise deezer.DeezerError(path)
        return responses[path]

    monkeypatch.setattr(deezer, "_get", get)
    # The latest seed is a tango the mix wandered to; the mix started from artist 10
    mix = asyncio.run(deezer.mix_candidates(["5"], exclude=set(), anchors=["1"]))
    # Its artists and those like them first, then what their radios wandered to
    assert [t["id"] for t in mix] == ["110", "100", "99"]
