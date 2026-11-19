"""The socket the apps listen together over; library.listen holds the sessions."""
import json
import logging

from fastapi import APIRouter, WebSocket, WebSocketDisconnect

from library import db, limits, listen
from library.auth import tokens

log = logging.getLogger(__name__)

router = APIRouter()

# A queue of a long playlist is the largest message
MAX_MESSAGE_BYTES = 2_000_000


async def _member(uid: str, websocket: WebSocket) -> listen.Member:
    row = await db.fetch_one("SELECT name, picture FROM users WHERE uid = %s", (uid,))
    name, picture = (row[0] or "", row[1] or "") if row else ("", "")

    async def send(message: dict) -> None:
        await websocket.send_text(json.dumps(message))

    return listen.Member(uid=uid, name=name, picture=picture, send=send)


@router.websocket("/listen")
async def listen_together(websocket: WebSocket):
    """The first message signs in and creates a session, {"create": {"rights": [...]}},
    or joins one, {"join": "<code>"}; those after it go to the session."""
    if not limits.sockets.allow(limits.client_ip(websocket)):
        await websocket.close(code=1013, reason="Too many connections")
        return
    await websocket.accept()
    session = None
    member = None
    try:
        first = json.loads(await websocket.receive_text())
        auth = tokens.decode(str(first.get("at+JWT") or ""), "at+JWT")
        if auth is None or await tokens.session_status(auth) != "ok":
            await websocket.send_text(json.dumps({"type": "error", "error": "expired"}))
            await websocket.close()
            return
        member = await _member(auth.uid, websocket)
        if "create" in first:
            options = first["create"] if isinstance(first["create"], dict) else {}
            session = await listen.hub.create(member, options.get("rights"))
            if session is None:
                await websocket.send_text(json.dumps({"type": "error", "error": "busy"}))
                await websocket.close()
                return
        else:
            session = listen.hub.find(str(first.get("join") or ""))
            if session is None or not await listen.hub.join(session, member):
                error = "notfound" if session is None else "full"
                session = None
                await websocket.send_text(json.dumps({"type": "error", "error": error}))
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
            if not isinstance(message, dict):
                continue
            if message.get("type") == "leave":
                await listen.hub.leave(session, auth.uid)
                session = None
                await websocket.close()
                return
            await listen.hub.handle(session, auth.uid, message)
    except (WebSocketDisconnect, ValueError, KeyError):
        pass
    except Exception:
        log.exception("Listening together failed")
    finally:
        if session is not None and member is not None:
            await listen.hub.disconnected(session, member.uid, member.send)
