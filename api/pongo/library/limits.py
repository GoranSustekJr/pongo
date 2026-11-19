"""In-memory rate limits. They reset when the server restarts, which is fine for abuse
protection on a single small server."""
import logging
import re
import time
from collections import deque

from fastapi import HTTPException
from starlette.requests import HTTPConnection

from library import config


class SlidingWindow:
    """Allows `limit` events per key in any `seconds` long window."""

    def __init__(self, limit: int, seconds: float, max_keys: int = 10_000):
        self.limit, self.seconds, self.max_keys = limit, seconds, max_keys
        self._events: dict[str, deque[float]] = {}

    def allow(self, key: str) -> bool:
        now = time.monotonic()
        events = self._events.get(key)
        if events is None:
            if len(self._events) >= self.max_keys:
                self._prune(now)
            events = self._events[key] = deque()
        while events and events[0] <= now - self.seconds:
            events.popleft()
        if len(events) >= self.limit:
            return False
        events.append(now)
        return True

    def _prune(self, now: float) -> None:
        for key in [k for k, e in self._events.items() if not e or e[-1] <= now - self.seconds]:
            del self._events[key]
        # Still full of active keys: forget the oldest rather than grow without bound
        while len(self._events) >= self.max_keys:
            del self._events[next(iter(self._events))]


sign_ins = SlidingWindow(config.SIGN_INS_PER_MINUTE, 60)
requests = SlidingWindow(config.REQUESTS_PER_MINUTE, 60)
sockets = SlidingWindow(config.SOCKETS_PER_MINUTE, 60)
downloads = SlidingWindow(config.DOWNLOADS_PER_HOUR, 3600)


def check(window: SlidingWindow, key: str) -> None:
    if not window.allow(key):
        raise HTTPException(status_code=429, detail="Too many requests")


def client_ip(connection: HTTPConnection) -> str:
    # Behind Caddy, uvicorn's proxy headers make this the real client address
    return connection.client.host if connection.client else "unknown"


class HideStreamTokens(logging.Filter):
    """Cuts stream tokens out of logged request paths, where anyone reading the
    logs could otherwise play music with them until they expire."""

    _TOKEN = re.compile(r"(st=|/stream/)[^/&\s\"]+")

    def filter(self, record: logging.LogRecord) -> bool:
        if isinstance(record.args, tuple):
            record.args = tuple(
                self._TOKEN.sub(r"\1***", arg) if isinstance(arg, str) else arg for arg in record.args
            )
        return True

