"""Fetch tracks onto the server. Each track downloads once, however many clients wait."""
import asyncio
import contextlib
import hashlib
import logging
import secrets
import shutil
import tempfile
import threading
import time
from collections import deque
from collections.abc import AsyncIterator
from pathlib import Path

import httpx
from cachetools import TTLCache

from library import config, db, limits
from library.metadata import deezer
from library.track import loudness, matcher, mood
from library.track.partial import CHUNK, Partial

log = logging.getLogger(__name__)

# A streamed download's file stays a while after a player last asked for it, for pausing and seeking
STREAM_KEEP = 3600
# Others only briefly, for a player that asks just after the download finished
UNSTREAMED_KEEP = 60
# How long a player waits for a download to start before giving up on streaming it
STREAM_START_TIMEOUT = 60

_tasks: dict[str, asyncio.Task] = {}
# The file each download writes, kept for players after the track is stored
_partials: dict[str, Partial] = {}
_waiters: dict[str, int] = {}
_downloading: set[str] = set()
# Tracks with no YouTube match, so mixes and retries don't search for them again right away
_no_match: TTLCache = TTLCache(maxsize=5000, ttl=3600)
_slots = asyncio.Semaphore(config.MAX_CONCURRENT_DOWNLOADS)
# Moods aren't needed to play a track, so they're analyzed after it's stored, one at a time
_analyzing = asyncio.Semaphore(1)
_analyses: set[asyncio.Task] = set()
# yt-dlp loaded once per worker thread and player client: starting it takes most of a second
_loaded = threading.local()
# YouTube slows down single requests for large ranges, so audio comes in parts this big
_RANGE = 10 * 1024 * 1024


class TrackUnavailable(Exception):
    pass


class NotStreamable(Exception):
    """The track should be played from the library, once it's there, rather than streamed."""


def _streams_dir() -> Path:
    return config.TEMP_DIR / "streams"


def clear_streams() -> None:
    """Deletes the files of downloads from before a restart."""
    shutil.rmtree(_streams_dir(), ignore_errors=True)


async def _run(*command: str) -> str:
    process = await asyncio.create_subprocess_exec(
        *command, stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE
    )
    stdout, stderr = await process.communicate()
    if process.returncode != 0:
        raise TrackUnavailable(f"{command[0]} failed: {stderr.decode(errors='replace')[-500:]}")
    return stdout.decode()


def _client_options(client: str) -> list[str]:
    options = []
    if client != "default":
        options += ["--extractor-args", f"youtube:player_client={client}"]
    if config.YTDLP_COOKIES_FILE:
        options += ["--cookies", config.YTDLP_COOKIES_FILE]
    return options


async def _download_audio_with(video_id: str, folder: Path, client: str) -> Path:
    command = [
        "yt-dlp", "--no-playlist", "--no-progress", "--quiet",
        # iOS can't play the webm/opus YouTube often serves, so always end up with m4a
        "-f", "ba[ext=m4a]/ba/b", "-x", "--audio-format", "m4a",
        "-o", str(folder / "audio.%(ext)s"), *_client_options(client),
    ]
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


def _audio_source(video_id: str, client: str) -> tuple[str, dict, int]:
    """Blocking. The URL of the video's m4a audio, the headers to fetch it with and the size
    of the parts to fetch it in, found by a yt-dlp kept loaded in this thread."""
    instances = getattr(_loaded, "instances", None)
    if instances is None:
        instances = _loaded.instances = {}
    ydl = instances.get(client)
    if ydl is None:
        import yt_dlp

        options = {"quiet": True, "no_warnings": True, "noplaylist": True, "format": "ba[ext=m4a]"}
        if client != "default":
            options["extractor_args"] = {"youtube": {"player_client": [client]}}
        if config.YTDLP_COOKIES_FILE:
            options["cookiefile"] = config.YTDLP_COOKIES_FILE
        ydl = instances[client] = yt_dlp.YoutubeDL(options)
    info = ydl.extract_info(f"https://www.youtube.com/watch?v={video_id}", download=False)
    part = (info.get("downloader_options") or {}).get("http_chunk_size") or _RANGE
    return info["url"], info.get("http_headers") or {}, part


async def _pipe_audio_loaded(video_id: str, partial: Partial, client: str) -> None:
    """Downloads into `partial` with the loaded yt-dlp, which skips starting one per track."""
    url, headers, part = await asyncio.to_thread(_audio_source, video_id, client)
    async with httpx.AsyncClient(headers=headers, timeout=30, follow_redirects=True) as http:
        with partial.path.open("wb") as file:
            total = None
            while total is None or partial.written < total:
                start = partial.written
                request_range = {"Range": f"bytes={start}-{start + part - 1}"}
                async with http.stream("GET", url, headers=request_range) as response:
                    response.raise_for_status()
                    total = int(response.headers.get("content-range", "/0").rsplit("/", 1)[-1] or 0)
                    async for data in response.aiter_bytes(CHUNK):
                        partial.append(file, data)
                if not total or partial.written == start:
                    break


async def _pipe_audio_with(video_id: str, partial: Partial, client: str) -> None:
    try:
        await _pipe_audio_loaded(video_id, partial, client)
        return
    except Exception as error:
        # Players may already have bytes a fresh download couldn't continue
        if partial.written:
            raise TrackUnavailable(f"Download of {video_id} broke off: {error}") from error
        log.info("Loaded yt-dlp couldn't download %s with %s, running it instead: %s",
                 video_id, client, error)
    process = await asyncio.create_subprocess_exec(
        "yt-dlp", "--no-playlist", "--no-progress", "--quiet",
        # YouTube's m4a is a fragmented MP4, which players can follow while it downloads
        "-f", "ba[ext=m4a]", "-o", "-", *_client_options(client),
        f"https://www.youtube.com/watch?v={video_id}",
        stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE,
    )
    errors = asyncio.create_task(process.stderr.read())
    try:
        with partial.path.open("wb") as file:
            while data := await process.stdout.read(CHUNK):
                partial.append(file, data)
        returncode = await process.wait()
    except BaseException:
        with contextlib.suppress(ProcessLookupError):
            process.kill()
        errors.cancel()
        raise
    if returncode != 0:
        raise TrackUnavailable(f"yt-dlp failed: {(await errors).decode(errors='replace')[-500:]}")


async def _pipe_audio(video_id: str, partial: Partial) -> None:
    """Downloads into `partial`, trying each of YTDLP_PLAYER_CLIENTS like _download_audio."""
    for client in config.YTDLP_PLAYER_CLIENTS:
        try:
            await _pipe_audio_with(video_id, partial, client)
            return
        except TrackUnavailable as error:
            # Another client could send different bytes than a player already has
            if partial.written or client == config.YTDLP_PLAYER_CLIENTS[-1]:
                raise
            log.info("%s client failed for %s, trying the next: %s", client, video_id, error)


async def _download_streamable(video_id: str, folder: Path, partial: Partial) -> Path:
    """Downloads into `partial`, so players can stream it, then makes the library's file of it.

    Falls back to a plain download for audio that can't be piped, such as when YouTube has no m4a.
    """
    partial.folder.mkdir(parents=True, exist_ok=True)
    try:
        await _pipe_audio(video_id, partial)
        partial.complete()
    except (TrackUnavailable, ValueError) as error:
        partial.fail(str(error))
        log.info("Couldn't download %s while streaming it, downloading it whole: %s", video_id, error)
        return await _download_audio(video_id, folder)
    # The library keeps plain MP4s with their index up front, which start playing quickest
    audio = folder / "audio.m4a"
    await _run("ffmpeg", "-v", "error", "-i", str(partial.path), "-map", "0:a", "-c", "copy",
               "-movflags", "+faststart", str(audio))
    return audio


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


def _analyze_later(auid: int, path: Path) -> None:
    async def analyze():
        async with _analyzing:
            await mood.save(auid, await mood.analyze(path))

    task = asyncio.create_task(analyze())
    _analyses.add(task)
    task.add_done_callback(_analyses.discard)


async def _fetch(stid: str, chosen: str | None = None) -> float:
    """Downloads and stores the track's audio: from the video [chosen], replacing what's
    stored, or else a user's earlier choice, or else the best YouTube match. A failure is
    remembered with its reason, for apps to show."""
    try:
        return await _fetch_audio(stid, chosen)
    except asyncio.CancelledError:
        raise
    except Exception as error:
        if isinstance(error, deezer.DeezerError):
            reason = "catalog"
        elif isinstance(error, TrackUnavailable) and stid in _no_match:
            reason = "no_match"
        else:
            reason = "download"
        try:
            await db.record_track_failure(stid, reason)
        except Exception:
            log.exception("Couldn't record the failed download of %s", stid)
        raise


async def _fetch_audio(stid: str, chosen: str | None) -> float:
    started = time.monotonic()
    full = await deezer.full_track(stid)
    track = {
        "title": full["title"],
        "artist": full["artist"]["name"],
        "duration": full.get("duration", 0),
    }
    if chosen is None:
        chosen = await db.chosen_video(stid)
    if chosen is not None:
        video_id, match_score = chosen, 1.0
        log.info("Using the chosen video %s for %s (%s - %s)", video_id, stid, track["artist"], track["title"])
    else:
        match = await asyncio.to_thread(matcher.find_video, track)
        if match is None:
            _no_match[stid] = True
            raise TrackUnavailable(f"No YouTube match for {track}")
        video_id, match_score = match
        log.info("Matched %s (%s - %s) to %s, score %.2f",
                 stid, track["artist"], track["title"], video_id, match_score)

    config.TEMP_DIR.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(dir=config.TEMP_DIR) as folder:
        audio = await _download_streamable(video_id, Path(folder), _partials[stid])
        downloaded = time.monotonic()
        duration, level = await asyncio.gather(_audio_duration(audio), loudness.measure(audio))
        sha256, path, size = await asyncio.to_thread(_store_file, audio)

    async with db.pool.connection() as conn:
        # Different catalog tracks can resolve to the same audio
        cursor = await conn.execute(
            """
            INSERT INTO audio (sha256, path, size_bytes, loudness, loudness_checked)
            VALUES (%s, %s, %s, %s, true)
            ON CONFLICT (sha256) DO UPDATE SET path = EXCLUDED.path
            RETURNING auid
            """,
            (sha256, path, size, level),
        )
        auid = (await cursor.fetchone())[0]
        await conn.execute(
            """
            INSERT INTO track (stid, ytvid, auid, duration, title, artists, isrc, match_score)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            ON CONFLICT (stid) DO UPDATE SET ytvid = EXCLUDED.ytvid, auid = EXCLUDED.auid,
                duration = EXCLUDED.duration, match_score = EXCLUDED.match_score
            """,
            (stid, video_id, auid, duration, track["title"], track["artist"],
             full.get("isrc"), match_score),
        )
        await conn.execute("DELETE FROM track_failure WHERE stid = %s", (stid,))
    _analyze_later(auid, Path(path))
    log.info("Fetched %s in %.1f s, %.1f s of it after the download",
             stid, time.monotonic() - started, time.monotonic() - downloaded)
    return duration


async def _fetch_with_slot(stid: str, chosen: str | None = None) -> float:
    partial = _partials[stid]
    try:
        async with _slots:
            _downloading.add(stid)
            try:
                return await (_fetch(stid) if chosen is None else _fetch(stid, chosen))
            finally:
                _downloading.discard(stid)
    finally:
        if not partial.finished:
            partial.fail("The download stopped")
        partial.used = time.monotonic()
        _keep(stid, partial)


def _keep(stid: str, partial: Partial) -> None:
    """Deletes a finished download's file once players are done with it."""
    left = partial.used + (STREAM_KEEP if partial.streamed else UNSTREAMED_KEEP) - time.monotonic()
    if left > 0:
        asyncio.get_running_loop().call_later(left, _keep, stid, partial)
        return
    if _partials.get(stid) is partial:
        del _partials[stid]
    shutil.rmtree(partial.folder, ignore_errors=True)


def _forget(stid: str, task: asyncio.Task) -> None:
    if _tasks.get(stid) is task:
        del _tasks[stid]


def _start(stid: str, owner: str | None, chosen: str | None = None) -> asyncio.Task:
    """The download of the track, starting it if there's none. Raises TrackUnavailable."""
    task = _tasks.get(stid)
    # A finished task stays listed until its done callback runs
    if task is not None and not task.done():
        return task
    if owner is not None and not limits.downloads.allow(owner):
        raise TrackUnavailable(f"Download limit reached for user {owner}")
    _partials[stid] = Partial(_streams_dir() / f"{stid}-{secrets.token_hex(4)}")
    # Runs independently of the caller, so a client hanging up mid-download doesn't waste the work
    task = asyncio.create_task(_fetch_with_slot(stid, chosen))
    _tasks[stid] = task
    task.add_done_callback(lambda done: _forget(stid, done))
    return task


@contextlib.contextmanager
def _waiting(stid: str, task: asyncio.Task):
    _waiters[stid] = _waiters.get(stid, 0) + 1
    try:
        yield
    finally:
        _waiters[stid] -= 1
        if not _waiters[stid]:
            del _waiters[stid]
            # Nobody wants it any more, so drop it unless its download already started
            if not task.done() and stid not in _downloading:
                _forget(stid, task)
                task.cancel()


async def ensure_track(stid: str, owner: str | None = None) -> float:
    """Duration of the track, downloading it first if needed. Raises TrackUnavailable.

    A new download counts towards the hourly download limit of `owner`, a user id.
    """
    duration = await db.track_duration(stid)
    if duration is not None:
        return duration
    if stid in _no_match:
        raise TrackUnavailable(f"No YouTube match for {stid}, checked within the last hour")

    task = _start(stid, owner)
    with _waiting(stid, task):
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


def prepare(stids: list[str], owner: str) -> tuple[int, bool]:
    """Starts downloading those of the tracks the server doesn't have, in the background,
    as far as the owner's download limit allows. Returns how many it started, and whether
    the limit stopped it."""
    started = 0
    for stid in stids:
        if stid in _no_match or stid in _tasks:
            continue
        try:
            task = _start(stid, owner)
        except TrackUnavailable:
            return started, True
        started += 1
        # Failures are recorded by _fetch; nobody waits for the result
        task.add_done_callback(lambda done: done.cancelled() or done.exception())
    return started, False


async def use_version(stid: str, video_id: str, owner: str | None = None) -> float:
    """Replaces the track's audio with that of the YouTube video [video_id], and keeps
    using that video when the track is downloaded again. Returns the new duration.

    The old audio stays until the new one is stored, so a failed download changes nothing.
    """
    running = _tasks.get(stid)
    if running is not None:
        # Let a download already under way finish first; its result is replaced below
        with contextlib.suppress(Exception):
            await asyncio.shield(running)
    old = await db.fetch_one("SELECT ytvid, auid, duration FROM track WHERE stid = %s", (stid,))
    if old is None or old[0] != video_id:
        task = _start(stid, owner, chosen=video_id)
        try:
            duration = await asyncio.shield(task)
        except TrackUnavailable:
            raise
        except Exception as error:
            log.exception("Failed to use video %s for %s", video_id, stid)
            raise TrackUnavailable(str(error)) from error
    else:
        duration = old[2]
    await db.execute(
        """
        INSERT INTO track_override (stid, ytvid, uid) VALUES (%s, %s, %s)
        ON CONFLICT (stid) DO UPDATE SET ytvid = EXCLUDED.ytvid, uid = EXCLUDED.uid, chosen_at = now()
        """,
        (stid, video_id, owner),
    )
    _no_match.pop(stid, None)
    if old is not None and old[0] != video_id:
        await _drop_unused_audio(old[1])
    return duration


async def _drop_unused_audio(auid: int) -> None:
    """Deletes audio no track uses any more, with its file."""
    row = await db.fetch_one(
        "DELETE FROM audio WHERE auid = %s AND NOT EXISTS (SELECT 1 FROM track WHERE auid = %s) RETURNING path",
        (auid, auid),
    )
    if row:
        with contextlib.suppress(OSError):
            Path(row[0]).unlink()
        log.info("Deleted audio %s, which no track uses any more", auid)


def streaming(stid: str) -> Partial | None:
    """The file of the track's current or recent download, if a player can still stream it."""
    partial = _partials.get(stid)
    return None if partial is None or partial.failed else partial


async def stream_track(stid: str, owner: str | None = None) -> Partial:
    """The track's download once players can start streaming it, starting the download if needed.

    It's the same download ensure_track waits for. Raises NotStreamable if the track should be
    played from the library instead, and TrackUnavailable if it can't be downloaded at all.
    """
    partial = streaming(stid)
    task = _tasks.get(stid)
    if partial is None:
        if await db.track_duration(stid) is not None:
            raise NotStreamable("The track is in the library")
        if stid in _no_match:
            raise TrackUnavailable(f"No YouTube match for {stid}, checked within the last hour")
        task = _start(stid, owner)
        partial = _partials[stid]
    partial.streamed = True
    partial.used = time.monotonic()
    if task is None or task.done():
        started = partial.layout is not None
    else:
        with _waiting(stid, task):
            started = await partial.wait(
                lambda: partial.layout is not None or partial.unstreamable is not None,
                STREAM_START_TIMEOUT,
            )
    if partial.failed or not started:
        if task is not None and task.done() and not task.cancelled() and task.exception():
            raise TrackUnavailable(str(task.exception()))
        raise NotStreamable(partial.unstreamable or "The download didn't start in time")
    return partial


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
