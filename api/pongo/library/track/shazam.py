import asyncio
import tempfile
from pathlib import Path

from shazamio import Shazam

from library import config
from library.track.downloads import _audio_duration, _run

SAMPLE_SECONDS = 10


async def recognize(audio_path: str) -> dict:
    """Identify the song from a sample taken from its middle."""
    start = max(0.0, await _audio_duration(Path(audio_path)) / 2 - SAMPLE_SECONDS / 2)
    config.TEMP_DIR.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(dir=config.TEMP_DIR) as folder:
        sample = Path(folder) / "sample.ogg"
        await _run(
            "ffmpeg", "-v", "error", "-ss", str(start), "-t", str(SAMPLE_SECONDS),
            "-i", audio_path, "-vn", "-c:a", "libvorbis", str(sample),
        )
        return await asyncio.wait_for(Shazam().recognize(str(sample)), timeout=30)
