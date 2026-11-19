import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient

from library import listen
from library.auth import tokens
from library.routes import listen as route


@pytest.fixture
def client(monkeypatch):
    async def ok(_session):
        return "ok"

    async def user(_query, params):
        return (params[0].title(), "")

    monkeypatch.setattr(tokens, "session_status", ok)
    monkeypatch.setattr(route.db, "fetch_one", user)
    monkeypatch.setattr(listen, "hub", listen.Hub())
    app = FastAPI()
    app.include_router(route.router)
    with TestClient(app) as client:
        yield client


def _token(uid):
    return tokens.create_access_token(uid, None, "device")


def _next(socket, kind):
    while True:
        message = socket.receive_json()
        if message["type"] == kind:
            return message


def test_a_friend_joins_follows_and_asks(client):
    with client.websocket_connect("/listen") as host:
        host.send_json({"at+JWT": _token("host"), "create": {"rights": ["add"]}})
        assert _next(host, "welcome")["uid"] == "host"
        code = _next(host, "session")["code"]
        host.send_json({"type": "queue", "snapshot": {"items": []}})
        with client.websocket_connect("/listen") as guest:
            guest.send_json({"at+JWT": _token("guest"), "join": code.lower()})
            members = _next(guest, "session")["members"]
            assert [m["name"] for m in members] == ["Host", "Guest"]
            assert _next(guest, "queue")["snapshot"] == {"items": []}
            guest.send_json({"type": "request", "request": {"pause": {}}})
            assert _next(guest, "denied")["kind"] == "pause"
            guest.send_json({"type": "request", "request": {"add": {"track": {}, "next": True}}})
            assert _next(host, "request")["from"] == "guest"
            guest.send_json({"type": "leave"})
        assert [m["present"] for m in _next(host, "session")["members"]] == [True, False]


def test_a_wrong_code_and_a_bad_token_are_refused(client):
    with client.websocket_connect("/listen") as socket:
        socket.send_json({"at+JWT": _token("a"), "join": "NOPE00"})
        assert socket.receive_json() == {"type": "error", "error": "notfound"}
    with client.websocket_connect("/listen") as socket:
        socket.send_json({"at+JWT": "bad", "create": {}})
        assert socket.receive_json() == {"type": "error", "error": "expired"}
