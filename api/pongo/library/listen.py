"""Listening together: friends follow one person's queue, each on their own phone and account.

The host's app publishes its queue and where it is in it; the server keeps the latest of
each and passes them on to the guests, whose apps play along. Guests ask for changes,
such as skipping or adding a song. The server checks the rights the host gave them and
passes what they may do on to the host's app, which makes the change and publishes it.

Sessions live in memory and end once everyone has left. Someone whose connection drops
has RECONNECT_SECONDS to come back before the session moves on without them: a host who
doesn't come back hands the session to the guest who joined first.
"""
import asyncio
import contextlib
import logging
import secrets
import time
from dataclasses import dataclass, field
from typing import Awaitable, Callable

log = logging.getLogger(__name__)

# What a host can let guests do: add songs, play/pause/skip/seek, remove and reorder
# songs, change shuffle and repeat, and start something else in place of the queue
RIGHTS = ("add", "playback", "manage", "modes", "takeover")

# The right each request needs, by its kind
NEEDS = {
    "togglePlayback": "playback", "play": "playback", "pause": "playback", "next": "playback",
    "previous": "playback", "seek": "playback", "skip": "playback",
    "add": "add",
    "remove": "manage", "move": "manage", "playNext": "manage", "clearUpcoming": "manage",
    "shuffle": "modes", "repeatMode": "modes",
    "replace": "takeover", "single": "takeover", "mix": "takeover",
}

# No 0/O or 1/I, which are easy to mix up when reading a code out
_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
CODE_LENGTH = 6
RECONNECT_SECONDS = 30
MAX_MEMBERS = 20
MAX_SESSIONS = 500

Send = Callable[[dict], Awaitable[None]]


@dataclass
class Member:
    uid: str
    name: str
    picture: str
    # How to reach the member's app; None while their connection is down
    send: Send | None = None
    joined: float = field(default_factory=time.monotonic)

    @property
    def present(self) -> bool:
        return self.send is not None


@dataclass
class Session:
    code: str
    host: str
    members: dict[str, Member] = field(default_factory=dict)
    # What guests may do, and what particular guests may do instead
    rights: set[str] = field(default_factory=set)
    overrides: dict[str, set[str]] = field(default_factory=dict)
    # The host's latest queue and playback, for guests who join later
    queue: dict | None = None
    playback: dict | None = None
    # Waits for someone who dropped, then moves on without them
    timers: dict[str, asyncio.Task] = field(default_factory=dict)

    def rights_of(self, uid: str) -> set[str]:
        if uid == self.host:
            return set(RIGHTS)
        return self.overrides.get(uid, self.rights)

    def present(self) -> list[Member]:
        return sorted((m for m in self.members.values() if m.present), key=lambda m: m.joined)

    def describe(self) -> dict:
        """The session as the apps show it: who's in it, who hosts and who may do what."""
        return {
            "type": "session",
            "code": self.code,
            "host": self.host,
            "rights": sorted(self.rights),
            "members": [
                {
                    "uid": m.uid, "name": m.name, "picture": m.picture, "present": m.present,
                    "rights": sorted(self.rights_of(m.uid)), "custom": m.uid in self.overrides,
                }
                for m in sorted(self.members.values(), key=lambda m: m.joined)
            ],
        }


def _rights(value) -> set[str]:
    return {right for right in value if right in RIGHTS} if isinstance(value, list) else set()


class Hub:
    def __init__(self):
        self.sessions: dict[str, Session] = {}

    def _new_code(self) -> str:
        while True:
            code = "".join(secrets.choice(_ALPHABET) for _ in range(CODE_LENGTH))
            if code not in self.sessions:
                return code

    def find(self, code: str) -> Session | None:
        return self.sessions.get(str(code).strip().upper())

    async def create(self, host: Member, rights=None) -> Session | None:
        if len(self.sessions) >= MAX_SESSIONS:
            return None
        session = Session(code=self._new_code(), host=host.uid, rights=_rights(rights or []))
        session.members[host.uid] = host
        self.sessions[session.code] = session
        await self._send(host, {"type": "welcome", "uid": host.uid})
        await self._send(host, session.describe())
        return session

    async def join(self, session: Session, member: Member) -> bool:
        """Adds [member], or reconnects them; returns False when the session is full."""
        known = session.members.get(member.uid)
        if known is None:
            if len(session.present()) >= MAX_MEMBERS:
                return False
            session.members[member.uid] = member
        else:
            known.send, known.name, known.picture = member.send, member.name, member.picture
            member = known
        if timer := session.timers.pop(member.uid, None):
            timer.cancel()
        await self._send(member, {"type": "welcome", "uid": member.uid})
        await self._broadcast(session, session.describe())
        # A guest starts where everyone is
        if member.uid != session.host:
            if session.queue is not None:
                await self._send(member, session.queue)
            if session.playback is not None:
                await self._send(member, session.playback)
        return True

    async def handle(self, session: Session, uid: str, message: dict) -> None:
        kind = message.get("type")
        member = session.members.get(uid)
        if member is None:
            return
        if kind == "ping":
            await self._send(member, {"type": "pong", "t": message.get("t"), "server": time.time()})
        elif kind in ("queue", "playback") and uid == session.host:
            if kind == "queue":
                session.queue = message
            else:
                session.playback = message
            await self._broadcast(session, message, skip=uid)
        elif kind == "request" and uid != session.host:
            await self._request(session, member, message.get("request"))
        elif kind == "rights" and uid == session.host:
            session.rights = _rights(message.get("rights"))
            overrides = message.get("overrides")
            if isinstance(overrides, dict):
                session.overrides = {
                    guest: _rights(rights) for guest, rights in overrides.items()
                    if guest in session.members and guest != session.host
                }
            await self._broadcast(session, session.describe())
        elif kind == "handover" and uid == session.host:
            target = session.members.get(str(message.get("to")))
            if target is not None and target.present and target.uid != uid:
                await self._hand_over(session, target)

    async def _request(self, session: Session, member: Member, request) -> None:
        if not isinstance(request, dict) or len(request) != 1:
            return
        kind = next(iter(request))
        needed = NEEDS.get(kind)
        host = session.members.get(session.host)
        if needed is None or needed not in session.rights_of(member.uid) or host is None or not host.present:
            await self._send(member, {"type": "denied", "kind": kind})
            return
        await self._send(host, {"type": "request", "from": member.uid, "request": request})

    async def _hand_over(self, session: Session, to: Member) -> None:
        session.host = to.uid
        session.overrides.pop(to.uid, None)
        await self._broadcast(session, session.describe())

    async def leave(self, session: Session, uid: str) -> None:
        """[uid] left on purpose: a host hands over to the guest who joined first."""
        member = session.members.get(uid)
        if member is None:
            return
        member.send = None
        await self._moved_on(session, uid)

    async def disconnected(self, session: Session, uid: str, send: Send) -> None:
        """[uid]'s connection dropped; they have a while to come back."""
        member = session.members.get(uid)
        # A newer connection of the same user replaced this one
        if member is None or member.send is not send:
            return
        member.send = None
        await self._broadcast(session, session.describe())
        if timer := session.timers.pop(uid, None):
            timer.cancel()
        session.timers[uid] = asyncio.create_task(self._wait_for(session, uid))

    async def _wait_for(self, session: Session, uid: str) -> None:
        await asyncio.sleep(RECONNECT_SECONDS)
        session.timers.pop(uid, None)
        member = session.members.get(uid)
        if member is not None and not member.present:
            await self._moved_on(session, uid)

    async def _moved_on(self, session: Session, uid: str) -> None:
        present = session.present()
        if not present:
            self.end(session)
            return
        if uid == session.host:
            await self._hand_over(session, present[0])
        else:
            await self._broadcast(session, session.describe())

    def end(self, session: Session) -> None:
        for timer in session.timers.values():
            timer.cancel()
        self.sessions.pop(session.code, None)

    async def _broadcast(self, session: Session, message: dict, skip: str | None = None) -> None:
        for member in session.present():
            if member.uid != skip:
                await self._send(member, message)

    @staticmethod
    async def _send(member: Member, message: dict) -> None:
        if member.send is None:
            return
        # A connection that just dropped is noticed by its own reader
        with contextlib.suppress(Exception):
            await member.send(message)


hub = Hub()
