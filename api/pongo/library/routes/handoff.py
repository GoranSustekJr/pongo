"""The socket each open app keeps, to move playback between a user's devices;
library.devices holds the open devices."""
import json
import logging

from fastapi import APIRouter, WebSocket, WebSocketDisconnect

from library import devices, limits
from library.auth import tokens

log = logging.getLogger(__name__)

router = APIRouter()

# A queue of a long playlist is the largest message
MAX_MESSAGE_BYTES = 4_000_000


@router.websocket("/devices")
async def device_socket(websocket: WebSocket):
    """The first message signs in and names the device, {"at+JWT": ..., "name": ...};
    those after it go to the user's other devices."""
    if not limits.sockets.allow(limits.client_ip(websocket)):
        await websocket.close(code=1013, reason="Too many connections")
        return
    await websocket.accept()
    auth = None
    device = None
    try:
        first = json.loads(await websocket.receive_text())
        auth = tokens.decode(str(first.get("at+JWT") or ""), "at+JWT")
        if auth is None or await tokens.session_status(auth) != "ok":
            await websocket.send_text(json.dumps({"type": "error", "error": "expired"}))
            await websocket.close()
            return

        async def send(message: dict) -> None:
            await websocket.send_text(json.dumps(message))

        device = await devices.hub.connect(auth.uid, auth.device_id, str(first.get("name") or ""), send)
        if device is None:
            await websocket.send_text(json.dumps({"type": "error", "error": "full"}))
            await websocket.close()
            return
        while True:
            text = await websocket.receive_text()
            if len(text) > MAX_MESSAGE_BYTES:
                continue
            try:
                message = json.loads(text)
            except ValueError:
                continue
            if isinstance(message, dict):
                await devices.hub.handle(auth.uid, device, message)
    except (WebSocketDisconnect, ValueError, KeyError):
        pass
    except Exception:
        log.exception("A device socket failed")
    finally:
        if auth is not None and device is not None:
            await devices.hub.disconnect(auth.uid, device)
