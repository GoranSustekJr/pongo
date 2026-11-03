"""Fetch tracks onto the server. Each track downloads once, however many clients wait."""
import asyncio
import hashlib
import logging
import shutil
import tempfile
from pathlib import Path

from library import config, db
from library.metadata import deezer
from library.track import matcher

log = logging.getLogger(__name__)

_tasks: dict[str, asyncio.Task] = {}
_slots = asyncio.Semaphore(config.MAX_CONCURRENT_DOWNLOADS)


class TrackUnavailable(Exception):
    pass


async def _run(*command: str) -> str:
    process = await asyncio.create_subprocess_exec(
        *command, stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE
    )
    stdout, stderr = await process.communicate()
    if process.returncode != 0:
        raise TrackUnavailable(f"{command[0]} failed: {stderr.decode(errors='replace')[-500:]}")
    return stdout.decode()


async def _download_audio(video_id: str, folder: Path) -> Path:
    command = [
        "yt-dlp", "--no-playlist", "--no-progress", "--quiet",
        # iOS can't play the webm/opus YouTube often serves, so always end up with m4a
        "-f", "ba[ext=m4a]/ba/b", "-x", "--audio-format", "m4a",
        "-o", str(folder / "audio.%(ext)s"),
    ]
    if config.YTDLP_COOKIES_FILE:
        command += ["--cookies", config.YTDLP_COOKIES_FILE]
    await _run(*command, f"https://www.youtube.com/watch?v={video_id}")
    return folder / "audio.m4a"


async def _audio_duration(path: Path) -> float:
    output = await _run(
        "ffprobe", "-v", "error", "-show_entries", "format=duration",
        "-of", "default=noprint_wrappers=1:nokey=1", str(path),
    )
    return float(output.strip())


def _store_file(path: Path) -> tuple[str, str, int]:
    """Move audio to its content-addressed home. Returns (sha256, path, size)."""
    digest = hashlib.sha256()
    with path.open("rb") as file:
        while chunk := file.read(1024 * 1024):
            digest.update(chunk)
    sha256 = digest.hexdigest()
    target = config.AUDIO_DIR / sha256[:2] / f"{sha256}.m4a"
    size = path.stat().st_size
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.move(path, target)
    return sha256, str(target), size


async def _fetch(stid: str) -> float:
    full = await deezer.full_track(stid)
    track = {
        "title": full["title"],
        "artist": full["artist"]["name"],
        "duration": full.get("duration", 0),
    }
    match = await asyncio.to_thread(matcher.find_video, track)
    if match is None:
        raise TrackUnavailable(f"No YouTube match for {track}")
    video_id, match_score = match
    log.info("Matched %s (%s - %s) to %s, score %.2f",
             stid, track["artist"], track["title"], video_id, match_score)

    config.TEMP_DIR.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(dir=config.TEMP_DIR) as folder:
        audio = await _download_audio(video_id, Path(folder))
        duration = await _audio_duration(audio)
        sha256, path, size = await asyncio.to_thread(_store_file, audio)

    async with db.pool.connection() as conn:
        # Different catalog tracks can resolve to the same audio
        cursor = await conn.execute(
            """
            INSERT INTO audio (sha256, path, size_bytes) VALUES (%s, %s, %s)
            ON CONFLICT (sha256) DO UPDATE SET path = EXCLUDED.path
            RETURNING auid
            """,
            (sha256, path, size),
        )
        auid = (await cursor.fetchone())[0]
        await conn.execute(
            """
            INSERT INTO track (stid, ytvid, auid, duration, title, artists, isrc, match_score)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            ON CONFLICT (stid) DO NOTHING
            """,
            (stid, video_id, auid, duration, track["title"], track["artist"],
             full.get("isrc"), match_score),
        )
    return duration


async def _fetch_with_slot(stid: str) -> float:
    async with _slots:
        return await _fetch(stid)


async def ensure_track(stid: str) -> float:
    """Duration of the track, downloading it first if needed. Raises TrackUnavailable."""
    duration = await db.track_duration(stid)
    if duration is not None:
        return duration

    task = _tasks.get(stid)
    if task is None:
        # Runs independently of the caller, so a client hanging up doesn't waste the work
        task = asyncio.create_task(_fetch_with_slot(stid))
        _tasks[stid] = task
        task.add_done_callback(lambda _: _tasks.pop(stid, None))
    try:
        return await asyncio.shield(task)
    except TrackUnavailable:
        raise
    except deezer.DeezerError as error:
        raise TrackUnavailable(str(error)) from error
    except asyncio.CancelledError:
        raise
    except Exception as error:
        log.exception("Failed to fetch track %s", stid)
        raise TrackUnavailable(str(error)) from error
