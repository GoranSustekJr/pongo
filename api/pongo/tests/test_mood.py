import asyncio
import subprocess

import numpy as np

from library.track import mood


def _sound(seconds=30, bpm=None, noise=0.0, seed=0):
    """A soft chord, with a noisy kick on every beat if bpm is given."""
    rng = np.random.default_rng(seed)
    t = np.arange(int(seconds * mood.RATE)) / mood.RATE
    # C major
    samples = sum(0.1 * np.sin(2 * np.pi * f * t) for f in (261.63, 329.63, 392.0))
    if bpm:
        beat = (t % (60 / bpm)) < 0.08
        decay = np.exp(-(t % (60 / bpm)) * 40)
        samples = samples + beat * decay * (np.sin(2 * np.pi * 60 * t) + noise * rng.standard_normal(len(t)))
    return samples.astype(np.float32)


def test_finds_the_tempo_of_a_steady_beat():
    assert abs(mood.features(_sound(bpm=120, noise=0.5))["tempo"] - 120) < 4


def test_drums_sound_more_energetic_and_danceable_than_a_held_chord():
    calm = mood.scores(mood.features(_sound()))
    beat = mood.scores(mood.features(_sound(bpm=124, noise=0.8)))
    assert beat["energy"] > calm["energy"]
    assert beat["danceability"] > calm["danceability"]


def test_moods_follow_the_scores():
    assert mood.label(0.9, 0.7, 0.9) == "party"
    assert mood.label(0.9, 0.2, 0.5) == "intense"
    assert mood.label(0.2, 0.2, 0.2) == "melancholy"
    assert mood.label(0.2, 0.7, 0.2) == "chill"
    assert mood.label(0.5, 0.7, 0.3) == "happy"
    assert all(m in mood.NEIGHBOURS[m] for m in mood.MOODS)


def test_reads_audio_files_and_skips_broken_ones(tmp_path):
    good, broken = tmp_path / "tone.m4a", tmp_path / "broken.m4a"
    subprocess.run(
        ["ffmpeg", "-v", "error", "-f", "lavfi", "-i", "sine=frequency=440:duration=15",
         "-c:a", "aac", str(good)],
        check=True,
    )
    broken.write_bytes(b"not audio")
    analyzed = asyncio.run(mood.analyze(good))
    assert analyzed and set(analyzed) == {"tempo", "energy", "valence", "danceability"}
    assert asyncio.run(mood.analyze(broken)) is None
