import asyncio

from fastapi.responses import FileResponse

from library import config, db
from library.routes import playback


def _stored(monkeypatch, tmp_path):
    audio = tmp_path / "audio" / "ab" / "abc.m4a"
    audio.parent.mkdir(parents=True)
    audio.write_bytes(b"m4a")

    async def path(_):
        return str(audio)

    monkeypatch.setattr(db, "track_audio_path", path)
    monkeypatch.setattr(config, "DATA_DIR", tmp_path)


def test_names_the_file_for_caddy_behind_the_proxy(monkeypatch, tmp_path):
    _stored(monkeypatch, tmp_path)
    monkeypatch.setattr(config, "SERVE_AUDIO_VIA_PROXY", True)
    response = asyncio.run(playback._audio_file("1"))
    assert response.headers["X-Pongo-Audio"] == "audio/ab/abc.m4a"
    assert response.body == b""


def test_sends_the_file_itself_without_the_proxy(monkeypatch, tmp_path):
    _stored(monkeypatch, tmp_path)
    monkeypatch.setattr(config, "SERVE_AUDIO_VIA_PROXY", False)
    assert isinstance(asyncio.run(playback._audio_file("1")), FileResponse)
