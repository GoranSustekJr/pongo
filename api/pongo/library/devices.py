"""Moves playback between a user's devices that have the app open.

Each open app keeps a socket to the server and says what it's called; the server tells
all of a user's open devices which of them are open. To move playback, one device
sends its queue to another of the user's devices, which plays it on and answers; the
server only passes these messages on, between devices of the same user, and keeps
nothing.
"""
import logging
from dataclasses import dataclass
from typing import Awaitable, Callable

log = logging.getLogger(__name__)

Send = Callable[[dict], Awaitable[None]]

# What one device may send another: its queue, an answer to one, or a request for one
RELAYED = ("transfer", "answer", "request")
MAX_NAME_LENGTH = 60
MAX_DEVICES = 20


@dataclass
class Device:
    device_id: str
    name: str
    send: Send


class Hub:
    def __init__(self) -> None:
        # Each user's open devices, by device ID
        self.users: dict[str, dict[str, Device]] = {}

    def listing(self, uid: str) -> list[dict]:
        return [
            {"device_id": d.device_id, "name": d.name}
            for d in sorted(self.users.get(uid, {}).values(), key=lambda d: d.name.lower())
        ]

    async def _announce(self, uid: str) -> None:
        listing = self.listing(uid)
        for device in list(self.users.get(uid, {}).values()):
            await self._send(device, {"type": "devices", "devices": listing, "you": device.device_id})

    async def _send(self, device: Device, message: dict) -> bool:
        try:
            await device.send(message)
            return True
        except Exception:
            log.info("A device's socket closed while sending to it")
            return False

    async def connect(self, uid: str, device_id: str, name: str, send: Send) -> Device | None:
        """Adds an open device, replacing an older connection of the same one."""
        devices = self.users.setdefault(uid, {})
        if device_id not in devices and len(devices) >= MAX_DEVICES:
            return None
        device = Device(device_id=device_id, name=(name or "").strip()[:MAX_NAME_LENGTH] or "Device", send=send)
        devices[device_id] = device
        await self._announce(uid)
        return device

    async def disconnect(self, uid: str, device: Device) -> None:
        devices = self.users.get(uid, {})
        # A newer connection of the same device stays
        if devices.get(device.device_id) is not device:
            return
        del devices[device.device_id]
        if not devices:
            self.users.pop(uid, None)
        await self._announce(uid)

    async def handle(self, uid: str, device: Device, message: dict) -> None:
        kind = message.get("type")
        if kind == "ping":
            await self._send(device, {"type": "pong"})
            return
        if kind not in RELAYED:
            return
        target = self.users.get(uid, {}).get(str(message.get("to") or ""))
        if target is None or target is device:
            await self._send(device, {"type": "undelivered", "id": message.get("id"), "of": kind})
            return
        relayed = {**message, "from": device.device_id, "from_name": device.name}
        relayed.pop("to", None)
        if not await self._send(target, relayed):
            await self._send(device, {"type": "undelivered", "id": message.get("id"), "of": kind})


hub = Hub()
