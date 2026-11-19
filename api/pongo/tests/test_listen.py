import asyncio

import pytest

from library import listen


def _member(uid, inbox):
    async def send(message):
        inbox.append(message)
    return listen.Member(uid=uid, name=uid.title(), picture="", send=send)


@pytest.fixture
def hub():
    return listen.Hub()


def _run(coroutine):
    return asyncio.run(coroutine)


def test_a_guest_gets_the_queue_and_playback_when_joining(hub):
    async def scenario():
        host_inbox, guest_inbox = [], []
        session = await hub.create(_member("host", host_inbox))
        await hub.handle(session, "host", {"type": "queue", "items": [1]})
        await hub.handle(session, "host", {"type": "playback", "position": 3})
        assert await hub.join(session, _member("guest", guest_inbox))
        kinds = [m["type"] for m in guest_inbox]
        assert kinds == ["welcome", "session", "queue", "playback"]
        assert guest_inbox[0]["uid"] == "guest"
        assert [m["uid"] for m in guest_inbox[1]["members"]] == ["host", "guest"]
        assert hub.find(session.code.lower()) is session
    _run(scenario())


def test_guests_only_do_what_they_were_allowed(hub):
    async def scenario():
        host_inbox, guest_inbox = [], []
        session = await hub.create(_member("host", host_inbox), ["add"])
        await hub.join(session, _member("guest", guest_inbox))
        await hub.handle(session, "guest", {"type": "request", "request": {"next": {}}})
        assert guest_inbox[-1] == {"type": "denied", "kind": "next"}
        await hub.handle(session, "guest", {"type": "request", "request": {"add": {"stid": "1"}}})
        assert host_inbox[-1]["type"] == "request" and host_inbox[-1]["from"] == "guest"
        # Only the host publishes the queue
        await hub.handle(session, "guest", {"type": "queue", "items": []})
        assert session.queue is None
    _run(scenario())


def test_a_guest_can_have_rights_of_their_own(hub):
    async def scenario():
        host_inbox, guest_inbox = [], []
        session = await hub.create(_member("host", host_inbox))
        await hub.join(session, _member("guest", guest_inbox))
        await hub.handle(session, "host", {
            "type": "rights", "rights": ["add", "bogus"], "overrides": {"guest": ["playback"], "stranger": ["add"]},
        })
        assert session.rights == {"add"}
        assert session.overrides == {"guest": {"playback"}}
        await hub.handle(session, "guest", {"type": "request", "request": {"pause": {}}})
        assert host_inbox[-1]["type"] == "request"
        await hub.handle(session, "guest", {"type": "request", "request": {"add": {}}})
        assert guest_inbox[-1]["type"] == "denied"
    _run(scenario())


def test_the_host_passes_the_aux(hub):
    async def scenario():
        host_inbox, guest_inbox = [], []
        session = await hub.create(_member("host", host_inbox))
        await hub.join(session, _member("guest", guest_inbox))
        await hub.handle(session, "host", {"type": "handover", "to": "guest"})
        assert session.host == "guest"
        assert guest_inbox[-1]["host"] == "guest"
    _run(scenario())


def test_the_first_guest_hosts_when_the_host_leaves_and_the_last_ends_it(hub):
    async def scenario():
        session = await hub.create(_member("host", []))
        await hub.join(session, _member("a", []))
        await hub.join(session, _member("b", []))
        await hub.leave(session, "host")
        assert session.host == "a"
        await hub.leave(session, "a")
        await hub.leave(session, "b")
        assert hub.find(session.code) is None
    _run(scenario())


def test_a_dropped_host_has_a_while_to_come_back(hub, monkeypatch):
    monkeypatch.setattr(listen, "RECONNECT_SECONDS", 0.01)

    async def scenario():
        host = _member("host", [])
        session = await hub.create(host)
        await hub.join(session, _member("guest", []))
        await hub.disconnected(session, "host", host.send)
        assert session.host == "host"
        await hub.join(session, _member("host", []))
        await asyncio.sleep(0.03)
        assert session.host == "host"
        # Gone for good this time
        await hub.disconnected(session, "host", session.members["host"].send)
        await asyncio.sleep(0.03)
        assert session.host == "guest"
    _run(scenario())
