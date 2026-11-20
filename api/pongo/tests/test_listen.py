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


def test_a_majority_votes_the_song_off(hub):
    async def scenario():
        host_inbox, a_inbox, b_inbox = [], [], []
        session = await hub.create(_member("host", host_inbox), ["vote"])
        await hub.join(session, _member("a", a_inbox))
        await hub.join(session, _member("b", b_inbox))
        await hub.handle(session, "host", {"type": "playback", "entry": "e1"})
        await hub.handle(session, "a", {"type": "vote"})
        assert a_inbox[-1] == {"type": "votes", "entry": "e1", "voters": ["a"], "needed": 2}
        assert not any(m["type"] == "request" for m in host_inbox)
        await hub.handle(session, "b", {"type": "vote"})
        assert [m for m in host_inbox if m["type"] == "request"][-1]["request"] == {"next": {}}
        # A new song starts the count again
        await hub.handle(session, "a", {"type": "vote"})
        await hub.handle(session, "host", {"type": "playback", "entry": "e2"})
        assert session.votes == set()
    _run(scenario())


def test_votes_need_the_right(hub):
    async def scenario():
        guest_inbox = []
        session = await hub.create(_member("host", []))
        await hub.join(session, _member("guest", guest_inbox))
        await hub.handle(session, "host", {"type": "playback", "entry": "e1"})
        await hub.handle(session, "guest", {"type": "vote"})
        assert guest_inbox[-1] == {"type": "denied", "kind": "vote"}
    _run(scenario())


def test_reactions_go_to_the_others_but_not_too_often(hub):
    async def scenario():
        host_inbox = []
        session = await hub.create(_member("host", host_inbox))
        await hub.join(session, _member("guest", []))
        await hub.handle(session, "guest", {"type": "react", "emoji": "🔥"})
        await hub.handle(session, "guest", {"type": "react", "emoji": "🔥"})
        await hub.handle(session, "guest", {"type": "react", "emoji": "💩"})
        reactions = [m for m in host_inbox if m["type"] == "reaction"]
        assert reactions == [{"type": "reaction", "from": "guest", "emoji": "🔥"}]
    _run(scenario())


def test_guests_suggest_songs_and_hear_back(hub):
    async def scenario():
        host_inbox, guest_inbox = [], []
        session = await hub.create(_member("host", host_inbox))
        await hub.join(session, _member("guest", guest_inbox))
        add = {"add": {"track": {"id": "1"}, "next": False}}
        await hub.handle(session, "guest", {"type": "suggest", "request": add})
        assert host_inbox[-1] == {"type": "suggestion", "from": "guest", "request": add}
        # Only songs to add can be suggested
        await hub.handle(session, "guest", {"type": "suggest", "request": {"clearUpcoming": {}}})
        assert guest_inbox[-1] == {"type": "denied", "kind": "suggest"}
        await hub.handle(session, "host", {"type": "answer", "to": "guest", "accepted": True, "title": "One"})
        assert guest_inbox[-1] == {"type": "answered", "accepted": True, "title": "One"}
    _run(scenario())
