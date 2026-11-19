import asyncio
import subprocess

from library.track import loudness


def test_loud_tracks_are_turned_down_and_quiet_ones_left_alone():
    assert loudness.gain_for(-8.0) == -6.0
    assert loudness.gain_for(-20.0) == 0.0
    assert loudness.gain_for(10.0) == loudness.MAX_CUT_DB
    assert loudness.gain_for(None) == 0.0


def test_measures_a_louder_file_as_louder(tmp_path):
    def tone(name, volume):
        path = tmp_path / name
        subprocess.run(
            ["ffmpeg", "-v", "error", "-f", "lavfi", "-i", "sine=frequency=440:duration=5",
             "-af", f"volume={volume}", "-c:a", "aac", str(path)],
            check=True,
        )
        return asyncio.run(loudness.measure(path))

    quiet, loud = tone("quiet.m4a", 0.1), tone("loud.m4a", 0.8)
    # Eight times the amplitude is about 18 dB louder
    assert 16 < loud - quiet < 20


def test_unreadable_files_have_no_loudness(tmp_path):
    broken = tmp_path / "broken.m4a"
    broken.write_bytes(b"not audio")
    assert asyncio.run(loudness.measure(broken)) is None
