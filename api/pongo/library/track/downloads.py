"""Fetch tracks onto the server. Each track downloads once, however many clients wait."""
import asyncio
import hashlib
import logging
import shutil
import tempfile
from collections import deque
from collections.abc import AsyncIterator
from pathlib import Path

from cachetools import TTLCache

from library import config, db, limits
from library.metadata import deezer
from library.track import matcher

log = logging.getLogger(__name__)

_tasks: dict[str, asyncio.Task] = {}
_waiters: dict[str, int] = {}
_downloading: set[str] = set()
# Tracks with no YouTube match, so mixes and retries don't search for them again right away
_no_match: TTLCache = TTLCache(maxsize=5000, ttl=3600)
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


async def _download_audio_with(video_id: str, folder: Path, client: str) -> Path:
    command = [
        "yt-dlp", "--no-playlist", "--no-progress", "--quiet",
        # iOS can't play the webm/opus YouTube often serves, so always end up with m4a
        "-f", "ba[ext=m4a]/ba/b", "-x", "--audio-format", "m4a",
        "-o", str(folder / "audio.%(ext)s"),
    ]
    if client != "default":
        command += ["--extractor-args", f"youtube:player_client={client}"]
    if config.YTDLP_COOKIES_FILE:
        command += ["--cookies", config.YTDLP_COOKIES_FILE]
    await _run(*command, f"https://www.youtube.com/watch?v={video_id}")
    return folder / "audio.m4a"


async def _download_audio(video_id: str, folder: Path) -> Path:
    """Tries each of YTDLP_PLAYER_CLIENTS in turn; "default" is yt-dlp's own choice."""
    # yt-dlp's default clients make it wait about 5 seconds before every download,
    # so a quicker client goes first and the default is the fallback
    for client in config.YTDLP_PLAYER_CLIENTS[:-1]:
        try:
            return await _download_audio_with(video_id, folder, client)
        except TrackUnavailable as error:
            log.info("%s client failed for %s, trying the next: %s", client, video_id, error)
            for leftover in folder.iterdir():
                leftover.unlink()
    return await _download_audio_with(video_id, folder, config.YTDLP_PLAYER_CLIENTS[-1])


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
        _no_match[stid] = True
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
        _downloading.add(stid)
        try:
            return await _fetch(stid)
        finally:
            _downloading.discard(stid)


def _forget(stid: str, task: asyncio.Task) -> None:
    if _tasks.get(stid) is task:
        del _tasks[stid]


async def ensure_track(stid: str, owner: str | None = None) -> float:
    """Duration of the track, downloading it first if needed. Raises TrackUnavailable.

    A new download counts towards the hourly download limit of `owner`, a user id.
    """
    duration = await db.track_duration(stid)
    if duration is not None:
        return duration
    if stid in _no_match:
        raise TrackUnavailable(f"No YouTube match for {stid}, checked within the last hour")

    task = _tasks.get(stid)
    if task is None and owner is not None and not limits.downloads.allow(owner):
        raise TrackUnavailable(f"Download limit reached for user {owner}")
    if task is None:
        # Runs independently of the caller, so a client hanging up mid-download doesn't waste the work
        task = asyncio.create_task(_fetch_with_slot(stid))
        _tasks[stid] = task
        task.add_done_callback(lambda done: _forget(stid, done))
    _waiters[stid] = _waiters.get(stid, 0) + 1
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
    finally:
        _waiters[stid] -= 1
        if not _waiters[stid]:
            del _waiters[stid]
            # Nobody wants it any more, so drop it unless its download already started
            if not task.done() and stid not in _downloading:
                _forget(stid, task)
                task.cancel()


async def _duration_or_none(stid: str, owner: str | None) -> float | None:
    try:
        return await ensure_track(stid, owner)
    except TrackUnavailable as error:
        log.warning("Track %s unavailable: %s", stid, error)
        return None


async def ensure_tracks(
    stids: asyncio.Queue[str | None], ahead: int | None = None, owner: str | None = None
) -> AsyncIterator[tuple[str, float | None]]:
    """Yields (stid, duration or None if unavailable) for each queued stid, in order, until a None.

    Fetches up to `ahead` (default MAX_CONCURRENT_DOWNLOADS) tracks ahead of the one being
    waited on, but only from stids already queued, so a caller can still send them one at a time.
    """
    ahead = ahead or config.MAX_CONCURRENT_DOWNLOADS
    pending: deque[tuple[str, asyncio.Task]] = deque()
    ended = False
    try:
        while not ended or pending:
            while not ended and len(pending) < ahead and (
                not pending or not stids.empty()
            ):
                stid = await stids.get()
                if stid is None:
                    ended = True
                else:
                    pending.append((stid, asyncio.create_task(_duration_or_none(stid, owner))))
            if pending:
                stid, task = pending.popleft()
                yield stid, await task
    finally:
        # Downloads already started still finish and are stored; the rest are dropped
        for _, task in pending:
            task.cancel()


def queue_of(stids: list[str]) -> asyncio.Queue[str | None]:
    queue = asyncio.Queue()
    for stid in [*stids, None]:
        queue.put_nowait(stid)
    return queue
