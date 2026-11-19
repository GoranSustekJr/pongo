"""A track's audio while it downloads, readable before it's complete.

YouTube's m4a audio is a fragmented MP4 with its index (the sidx box) right after
the header, so as soon as the first kilobytes arrive the whole file's layout is
known. That's enough for an HLS playlist of the fragments as byte ranges of the
file, which AVPlayer starts playing as soon as the first fragment is there.
"""
import asyncio
import secrets
import struct
import time
from pathlib import Path

CHUNK = 64 * 1024
# How long a reader waits for the next bytes before giving up on the download
STALL_TIMEOUT = 30
# The layout has to be in the first bytes, or the file can't be streamed
HEAD_LIMIT = 1 << 20


class Layout:
    """Where the parts of a fragmented MP4 are: the header, and each fragment."""

    def __init__(self, init_end: int, total: int, fragments: list[tuple[int, int, float]]):
        self.init_end = init_end
        self.total = total
        # (offset, size, seconds)
        self.fragments = fragments


def parse_layout(head: bytes) -> Layout | None:
    """The layout from the file's first bytes, or None until they hold the moov and sidx boxes.

    Raises ValueError for files that can't be streamed this way.
    """
    offset = 0
    init_end = None
    while offset + 8 <= len(head):
        size, kind = struct.unpack(">I4s", head[offset:offset + 8])
        header = 8
        if size == 1:
            if offset + 16 > len(head):
                return None
            size = struct.unpack(">Q", head[offset + 8:offset + 16])[0]
            header = 16
        if size < header:
            raise ValueError(f"Bad box size {size} at {offset}")
        if kind == b"moov":
            init_end = offset + size
        elif kind == b"sidx":
            end = offset + size
            if end > len(head):
                return None
            if init_end is None:
                raise ValueError("sidx before moov")
            return _layout_from_sidx(head[offset + header:end], init_end, end)
        elif kind in (b"moof", b"mdat"):
            raise ValueError(f"No sidx before the first {kind.decode()}")
        offset += size
    return None


def _layout_from_sidx(box: bytes, init_end: int, sidx_end: int) -> Layout:
    version = box[0]
    timescale = struct.unpack(">I", box[8:12])[0]
    if version == 0:
        first_offset = struct.unpack(">I", box[16:20])[0]
        position = 20
    else:
        first_offset = struct.unpack(">Q", box[20:28])[0]
        position = 28
    count = struct.unpack(">H", box[position + 2:position + 4])[0]
    position += 4
    if not count or not timescale:
        raise ValueError("Empty sidx")
    fragments = []
    start = sidx_end + first_offset
    for _ in range(count):
        reference, duration, _sap = struct.unpack(">III", box[position:position + 12])
        position += 12
        if reference & 0x80000000:
            raise ValueError("Nested sidx")
        fragments.append((start, reference, duration / timescale))
        start += reference
    return Layout(init_end, start, fragments)


def playlist(layout: Layout, name: str) -> str:
    """A VOD HLS playlist of the fragments, as byte ranges of the file called `name`.

    It's complete from the start, so AVPlayer doesn't treat it as live: a live
    playlist that already lists a few segments sometimes never starts playing.
    """
    lines = [
        "#EXTM3U",
        "#EXT-X-VERSION:7",
        f"#EXT-X-TARGETDURATION:{max(round(seconds) for _, _, seconds in layout.fragments)}",
        "#EXT-X-PLAYLIST-TYPE:VOD",
        "#EXT-X-INDEPENDENT-SEGMENTS",
        f'#EXT-X-MAP:URI="{name}",BYTERANGE="{layout.init_end}@0"',
    ]
    for offset, size, seconds in layout.fragments:
        lines += [f"#EXTINF:{seconds:.6f},", f"#EXT-X-BYTERANGE:{size}@{offset}", name]
    lines.append("#EXT-X-ENDLIST")
    return "\n".join(lines) + "\n"


def byte_range(header: str | None, total: int) -> tuple[int, int] | None:
    """The first range of a Range header as (start, end) inclusive, or None without one.

    Raises ValueError if the range can't be satisfied.
    """
    if not header:
        return None
    unit, _, ranges = header.partition("=")
    if unit.strip() != "bytes":
        raise ValueError(f"Unsupported range {header}")
    first, _, last = ranges.split(",")[0].strip().partition("-")
    if first:
        start = int(first)
        end = min(int(last), total - 1) if last else total - 1
    else:
        start, end = max(0, total - int(last)), total - 1
    if start > end or start >= total:
        raise ValueError(f"Unsatisfiable range {header}")
    return start, end


class Partial:
    """The audio file a download is writing, which readers can follow as it grows."""

    def __init__(self, folder: Path):
        # Made when the download starts
        self.folder = folder
        self.path = folder / "audio.m4a"
        # Names this file in URLs, so a player never gets bytes of a different download
        self.key = secrets.token_hex(6)
        self.written = 0
        self.layout: Layout | None = None
        # Why the download can't be streamed, or None while it still might be
        self.unstreamable: str | None = None
        self.finished = False
        self.failed = False
        # Whether a player asked for it, and when it last did
        self.streamed = False
        self.used = time.monotonic()
        self._head = b""
        self._changed = asyncio.Event()

    def _wake(self) -> None:
        self._changed.set()
        self._changed = asyncio.Event()

    def append(self, file, data: bytes) -> None:
        """Writes the next bytes of the download to `file`, the open partial file."""
        file.write(data)
        file.flush()
        self.written += len(data)
        if self.layout is None and self.unstreamable is None:
            self._head += data
            try:
                self.layout = parse_layout(self._head)
            except ValueError as error:
                self.unstreamable = str(error)
            if self.layout is None and len(self._head) > HEAD_LIMIT:
                self.unstreamable = "No layout at the start of the file"
            if self.layout is not None or self.unstreamable is not None:
                self._head = b""
        self._wake()

    def complete(self) -> None:
        """Marks the download as complete. Raises ValueError if it's shorter than its layout says."""
        if self.layout is not None and self.layout.total != self.written:
            reason = f"Expected {self.layout.total} bytes, got {self.written}"
            self.fail(reason)
            raise ValueError(reason)
        if self.layout is None and self.unstreamable is None:
            self.unstreamable = "No layout in the file"
        self.finished = True
        self._wake()

    def fail(self, reason: str) -> None:
        """Marks the download as failed, so readers stop waiting for more."""
        self.failed = True
        self.unstreamable = self.unstreamable or reason
        self.finished = True
        self._wake()

    async def wait(self, predicate, timeout: float = STALL_TIMEOUT) -> bool:
        """Waits until `predicate()` holds or the download ends, returning `predicate()`."""
        deadline = time.monotonic() + timeout
        while not (predicate() or self.finished):
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                break
            try:
                await asyncio.wait_for(self._changed.wait(), remaining)
            except TimeoutError:
                break
        return predicate()

    async def chunks(self, start: int, end: int):
        """The bytes from start to end inclusive, as they arrive."""
        position = start
        with self.path.open("rb") as file:
            file.seek(start)
            while position <= end:
                if self.written <= position:
                    if self.failed or not await self.wait(lambda: self.written > position):
                        raise RuntimeError(f"Download stopped at byte {position}")
                data = file.read(min(CHUNK, end + 1 - position, self.written - position))
                if not data:
                    raise RuntimeError("Short read")
                position += len(data)
                self.used = time.monotonic()
                yield data
