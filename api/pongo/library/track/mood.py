"""Mood of stored audio, worked out from how it sounds, so the app can group songs by mood.

Each file is measured once: its tempo, how steady its beat is, how busy and bright it
sounds and whether it's in a major or minor key. Those become three scores from 0 to 1
(energy, positivity and danceability), and the scores pick one of a few moods.
"""
import asyncio
import logging
import math
from pathlib import Path

import numpy as np

from library import db

log = logging.getLogger(__name__)

MOODS = ("chill", "happy", "energetic", "party", "intense", "melancholy")

RATE = 22050
_FFT = 2048
_HOP = 512
# Analyzing more than this adds time without changing the result
_MAX_SECONDS = 240

# Krumhansl–Kessler key profiles, from C
_MAJOR = np.array([6.35, 2.23, 3.48, 2.33, 4.38, 4.09, 2.52, 5.19, 2.39, 3.66, 2.29, 2.88])
_MINOR = np.array([6.33, 2.68, 3.52, 5.38, 2.60, 3.53, 2.54, 4.75, 3.98, 2.69, 3.34, 3.17])


async def decode(path: Path) -> np.ndarray | None:
    """The file's audio as mono samples at RATE, or None if ffmpeg can't read it."""
    process = await asyncio.create_subprocess_exec(
        "ffmpeg", "-v", "error", "-i", str(path), "-t", str(_MAX_SECONDS),
        "-ac", "1", "-ar", str(RATE), "-f", "f32le", "-",
        stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.DEVNULL,
    )
    output, _ = await process.communicate()
    if process.returncode != 0 or len(output) < RATE * 4 * 10:
        return None
    return np.frombuffer(output, dtype=np.float32)


def features(samples: np.ndarray) -> dict[str, float]:
    """How the audio sounds, measured from its spectrum."""
    frames = np.lib.stride_tricks.sliding_window_view(samples, _FFT)[::_HOP]
    spectrum = np.abs(np.fft.rfft(frames * np.hanning(_FFT), axis=1)).astype(np.float32)
    power = spectrum**2
    freqs = np.fft.rfftfreq(_FFT, 1 / RATE)
    total = power.sum(axis=1) + 1e-10
    # Quiet frames, such as an intro, say nothing about the song
    loud = total > np.percentile(total, 20)

    # Onsets: how much louder each frame is than the one before, across frequencies
    flux = np.maximum(np.diff(np.log1p(1000 * spectrum), axis=0), 0).mean(axis=1)
    onsets = flux - flux.mean()

    # Tempo: the beat period the onsets repeat at most, preferring tempos near 120 BPM
    frame_rate = RATE / _HOP
    correlation = np.correlate(onsets, onsets, mode="full")[len(onsets) - 1:]
    lags = np.arange(int(frame_rate * 60 / 200), int(frame_rate * 60 / 60) + 1)
    bpms = 60 * frame_rate / lags
    weighted = correlation[lags] * np.exp(-0.5 * (np.log2(bpms / 120) / 0.9) ** 2)
    best = int(np.argmax(weighted))
    # How much the onsets repeat at the beat: steady beats are easy to dance to
    pulse = float(correlation[lags[best]] / (correlation[0] + 1e-10))

    # Drums: a kick repeating at the beat, in the lowest frequencies
    low = freqs < 200
    kicks = np.maximum(np.diff(np.log1p(1000 * spectrum[:, low]), axis=0), 0).mean(axis=1)
    kicks -= kicks.mean()
    kick_correlation = np.correlate(kicks, kicks, mode="full")[len(kicks) - 1:]
    beat = float(kick_correlation[lags].max() / (kick_correlation[0] + 1e-10))

    # Key: the 12 pitch classes' strength, against major and minor profiles
    pitched = (freqs > 60) & (freqs < 2000)
    classes = np.round(12 * np.log2(freqs[pitched] / 261.63)).astype(int) % 12
    chroma = np.bincount(classes, weights=spectrum[loud][:, pitched].sum(axis=0), minlength=12)
    chroma = (chroma - chroma.mean()) / (chroma.std() + 1e-10)

    def fit(profile):
        return max(np.corrcoef(chroma, np.roll(profile, key))[0, 1] for key in range(12))

    rms_db = 10 * np.log10(total[loud] / _FFT)
    return {
        "tempo": float(bpms[best]),
        "pulse": pulse,
        "flux": float(flux[loud[1:]].mean()),
        "brightness": float((power[loud] @ freqs / total[loud]).mean()),
        "treble": float((power[loud][:, freqs > 2000].sum(axis=1) / total[loud]).mean()),
        "dynamics": float(np.percentile(rms_db, 95) - np.percentile(rms_db, 10)),
        "bass": float((power[loud][:, freqs < 150].sum(axis=1) / total[loud]).mean()),
        "beat": beat,
        # Noise-like sound, such as drums and distorted guitars, is flat across frequencies
        "noisiness": float(np.mean(np.exp(np.log(spectrum[loud] + 1e-10).mean(axis=1))
                                   / (spectrum[loud].mean(axis=1) + 1e-10))),
        "major": float(fit(_MAJOR) - fit(_MINOR)),
    }


def _sigmoid(value: float) -> float:
    return 1 / (1 + math.exp(-value))


# Typical values and spreads of the features in a varied library, to compare a song's with
_TYPICAL = {
    "tempo": (117.0, 27.0),
    "pulse": (0.45, 0.15),
    "flux": (0.33, 0.025),
    "brightness": (660.0, 200.0),
    "treble": (0.072, 0.036),
    "dynamics": (8.2, 2.6),
    "major": (0.02, 0.15),
    "bass": (0.41, 0.17),
    "beat": (0.37, 0.16),
    "noisiness": (0.37, 0.07),
}


def scores(measured: dict[str, float]) -> dict[str, float]:
    """Energy, positivity and danceability from 0 to 1."""
    z = {name: (measured[name] - mean) / spread for name, (mean, spread) in _TYPICAL.items()}
    # Drums, bass and bright, noise-like sound make music feel energetic
    energy = _sigmoid(0.9 * z["noisiness"] + 0.6 * z["beat"] + 0.4 * z["bass"] + 0.4 * z["treble"]
                      + 0.3 * z["tempo"] + 0.3 * z["flux"] - 0.3 * z["dynamics"])
    # Major keys and faster, groovier songs feel more positive
    valence = _sigmoid(0.9 * z["major"] + 0.3 * z["tempo"] + 0.2 * z["brightness"] + 0.3 * z["beat"]
                       + 0.2 * z["bass"])
    # Dancing needs a steady beat at a tempo people dance to
    tempo_fit = math.exp(-0.5 * ((measured["tempo"] - 120) / 18) ** 2)
    danceability = _sigmoid(0.8 * z["beat"] + 0.5 * z["pulse"] + 0.4 * z["bass"] + 1.2 * (tempo_fit - 0.5)
                            + 0.3 * z["noisiness"])
    return {"energy": round(energy, 3), "valence": round(valence, 3), "danceability": round(danceability, 3)}


# Moods close enough to each other for a mix of one to take songs of the other
NEIGHBOURS = {
    "chill": {"chill", "happy"},
    "happy": {"happy", "chill", "party"},
    "energetic": {"energetic", "party", "intense"},
    "party": {"party", "energetic", "happy"},
    "intense": {"intense", "energetic"},
    "melancholy": {"melancholy", "chill"},
}


def label(energy: float, valence: float, danceability: float) -> str:
    """The mood scores like these sound like."""
    if energy >= 0.6:
        if valence < 0.4:
            return "intense"
        return "party" if danceability >= 0.55 and valence >= 0.5 else "energetic"
    if energy < 0.4:
        return "melancholy" if valence < 0.4 else "chill"
    if valence >= 0.55:
        return "party" if danceability >= 0.65 else "happy"
    return "melancholy" if valence < 0.35 else "chill"


async def analyze(path: Path) -> dict[str, float] | None:
    """The tempo and scores of the file, or None if it can't be read."""
    samples = await decode(path)
    if samples is None:
        log.warning("Couldn't analyze the mood of %s", path)
        return None
    try:
        measured = await asyncio.to_thread(features, samples)
    except Exception:
        log.exception("Mood analysis of %s failed", path)
        return None
    return {"tempo": round(measured["tempo"], 1), **scores(measured)}


def values(analyzed: dict[str, float] | None) -> tuple:
    """The analysis in the order of the audio table's columns."""
    return tuple(analyzed[k] if analyzed else None for k in ("tempo", "energy", "valence", "danceability"))


async def save(auid: int, analyzed: dict[str, float] | None) -> None:
    await db.execute(
        """
        UPDATE audio SET tempo = %s, energy = %s, valence = %s, danceability = %s, mood_checked = true
        WHERE auid = %s
        """,
        (*values(analyzed), auid),
    )


async def moods(stids: list[str]) -> dict[str, dict]:
    """The mood and scores of each of the tracks that were analyzed."""
    rows = await db.fetch_all(
        """
        SELECT t.stid, a.tempo, a.energy, a.valence, a.danceability
        FROM track t JOIN audio a USING (auid)
        WHERE t.stid = ANY(%s) AND a.energy IS NOT NULL
        """,
        (stids,),
    )
    return {
        stid: {"mood": label(energy, valence, dance), "tempo": tempo, "energy": energy,
               "valence": valence, "danceability": dance}
        for stid, tempo, energy, valence, dance in rows
    }


async def analyze_stored(pause: float = 2.0) -> None:
    """Analyzes audio stored before moods were, one file at a time."""
    while True:
        rows = await db.fetch_all(
            "SELECT auid, path FROM audio WHERE NOT mood_checked ORDER BY auid DESC LIMIT 20"
        )
        if not rows:
            return
        for auid, path in rows:
            await save(auid, await analyze(Path(path)) if Path(path).is_file() else None)
            # Leaves room for downloads, which matter more
            await asyncio.sleep(pause)
