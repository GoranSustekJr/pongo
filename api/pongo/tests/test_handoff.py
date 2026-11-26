import asyncio

from library import devices


def _device(hub, uid, device_id, name):
    received = []

    async def send(message):
        received.append(message)

    device = asyncio.run(hub.connect(uid, device_id, name, send))
    return device, received


def test_open_devices_are_announced_to_each_other_only():
    hub = devices.Hub()
    phone, phone_got = _device(hub, "u1", "p", "iPhone")
    mac, mac_got = _device(hub, "u1", "m", "Mac")
    _, stranger_got = _device(hub, "u2", "s", "Other")
    assert mac_got[-1]["devices"] == [{"device_id": "p", "name": "iPhone"}, {"device_id": "m", "name": "Mac"}]
    assert phone_got[-1]["devices"] == mac_got[-1]["devices"]
    assert stranger_got[-1]["devices"] == [{"device_id": "s", "name": "Other"}]
    asyncio.run(hub.disconnect("u1", mac))
    assert phone_got[-1]["devices"] == [{"device_id": "p", "name": "iPhone"}]


def test_a_transfer_reaches_only_the_users_chosen_device():
    hub = devices.Hub()
    phone, phone_got = _device(hub, "u1", "p", "iPhone")
    mac, mac_got = _device(hub, "u1", "m", "Mac")
    stranger, stranger_got = _device(hub, "u2", "s", "Other")
    asyncio.run(hub.handle("u1", phone, {"type": "transfer", "to": "m", "id": "1", "state": {"a": 1}}))
    assert mac_got[-1] == {"type": "transfer", "id": "1", "state": {"a": 1}, "from": "p", "from_name": "iPhone"}
    # Another user's device can't be reached
    asyncio.run(hub.handle("u2", stranger, {"type": "transfer", "to": "m", "id": "2"}))
    assert stranger_got[-1] == {"type": "undelivered", "id": "2", "of": "transfer"}
    assert mac_got[-1]["id"] == "1"


def test_other_messages_are_not_relayed():
    hub = devices.Hub()
    phone, phone_got = _device(hub, "u1", "p", "iPhone")
    mac, mac_got = _device(hub, "u1", "m", "Mac")
    count = len(mac_got)
    asyncio.run(hub.handle("u1", phone, {"type": "devices", "to": "m"}))
    asyncio.run(hub.handle("u1", phone, {"type": "ping"}))
    assert len(mac_got) == count and phone_got[-1] == {"type": "pong"}


def test_a_reconnecting_device_replaces_its_old_connection():
    hub = devices.Hub()
    old, _ = _device(hub, "u1", "p", "iPhone")
    new, _ = _device(hub, "u1", "p", "iPhone")
    asyncio.run(hub.disconnect("u1", old))
    assert hub.listing("u1") == [{"device_id": "p", "name": "iPhone"}]


def test_two_devices_transfer_over_the_socket(monkeypatch):
    from fastapi import FastAPI
    from fastapi.testclient import TestClient

    from library.auth import tokens
    from library.routes import handoff

    monkeypatch.setattr(devices, "hub", devices.Hub())

    def decode(token, typ):
        uid, device_id = token.split(":")
        return tokens.Session(uid=uid, device_id=device_id)

    async def status(_):
        return "ok"

    monkeypatch.setattr(tokens, "decode", decode)
    monkeypatch.setattr(tokens, "session_status", status)
    monkeypatch.setattr(handoff.limits.sockets, "allow", lambda _: True)
    app = FastAPI()
    app.include_router(handoff.router)
    client = TestClient(app)
    with client.websocket_connect("/devices") as phone:
        phone.send_json({"at+JWT": "u1:p", "name": "iPhone"})
        assert phone.receive_json()["devices"] == [{"device_id": "p", "name": "iPhone"}]
        with client.websocket_connect("/devices") as mac:
            mac.send_json({"at+JWT": "u1:m", "name": "Mac"})
            assert len(mac.receive_json()["devices"]) == 2
            assert len(phone.receive_json()["devices"]) == 2
            phone.send_json({"type": "transfer", "to": "m", "id": "1", "state": {"items": []}, "position": 3})
            got = mac.receive_json()
            assert got["type"] == "transfer" and got["from_name"] == "iPhone" and got["position"] == 3
            mac.send_json({"type": "answer", "to": got["from"], "id": "1", "ok": True})
            assert phone.receive_json() == {"type": "answer", "id": "1", "ok": True, "from": "m", "from_name": "Mac"}
        assert phone.receive_json()["devices"] == [{"device_id": "p", "name": "iPhone"}]
