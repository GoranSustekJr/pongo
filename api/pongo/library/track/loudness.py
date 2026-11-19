"""Loudness of stored audio, so the app can play every track at a similar volume."""
import asyncio
import logging
import re
from pathlib import Path

from library import db

log = logging.getLogger(__name__)

# Loudness tracks are turned down to; louder streaming services use about the same
TARGET_LUFS = -14.0
# The app can only turn tracks down, and never by more than this
MAX_CUT_DB = -20.0
_INTEGRATED = re.compile(r"I:\s+(-?\d+(?:\.\d+)?) LUFS")


async def measure(path: Path) -> float | None:
    """Integrated loudness of the file in LUFS, or None if ffmpeg can't tell."""
    process = await asyncio.create_subprocess_exec(
        "ffmpeg", "-nostats", "-hide_banner", "-i", str(path),
        "-af", "ebur128=framelog=quiet", "-f", "null", "-",
        stdout=asyncio.subprocess.DEVNULL, stderr=asyncio.subprocess.PIPE,
    )
    _, stderr = await process.communicate()
    # The summary at the end repeats the integrated loudness; take the last one
    matches = _INTEGRATED.findall(stderr.decode(errors="replace"))
    if process.returncode != 0 or not matches:
        log.warning("Couldn't measure the loudness of %s", path)
        return None
    return float(matches[-1])


def gain_for(loudness: float | None) -> float:
    """Decibels to play a track at, to bring it down to TARGET_LUFS."""
    if loudness is None:
        return 0.0
    return max(MAX_CUT_DB, min(0.0, TARGET_LUFS - loudness))


async def gains(stids: list[str]) -> dict[str, float]:
    """Gain in decibels of each of the tracks that are on the server."""
    rows = await db.fetch_all(
        "SELECT t.stid, a.loudness FROM track t JOIN audio a USING (auid) WHERE t.stid = ANY(%s)",
        (stids,),
    )
    return {stid: round(gain_for(value), 2) for stid, value in rows}


async def measure_stored(pause: float = 1.0) -> None:
    """Measures audio stored before loudness was measured, one file at a time."""
    while True:
        rows = await db.fetch_all(
            "SELECT auid, path FROM audio WHERE NOT loudness_checked ORDER BY auid LIMIT 20"
        )
        if not rows:
            return
        for auid, path in rows:
            value = await measure(Path(path)) if Path(path).is_file() else None
            await db.execute(
                "UPDATE audio SET loudness = %s, loudness_checked = true WHERE auid = %s",
                (value, auid),
            )
            # Leaves room for downloads, which matter more
            await asyncio.sleep(pause)
