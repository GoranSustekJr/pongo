import base64
import hashlib
import hmac
import time
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone

import jwt
from fastapi import HTTPException, Request

from library import config, db

ALGORITHM = "HS512"
ACCESS_TTL = timedelta(hours=2)
REFRESH_TTL = timedelta(days=90)
STREAM_TTL = timedelta(days=7)


@dataclass
class Session:
    uid: str
    device_id: str
    # The device's refresh version a refresh token was issued for
    version: int = 0


def _encode(
    typ: str, uid: str, email: str | None, device_id: str, ttl: timedelta, version: int = 0
) -> str:
    now = datetime.now(tz=timezone.utc)
    payload = {
        "iss": config.JWT_ISSUER,
        "sub": str(email),
        "uid": uid,
        "jti": device_id,
        "ver": version,
        "iat": now,
        "exp": now + ttl,
    }
    return jwt.encode(
        payload, config.JWT_SECRET, algorithm=ALGORITHM, headers={"typ": typ}
    )


def create_access_token(uid: str, email: str | None, device_id: str) -> str:
    return _encode("at+JWT", uid, email, device_id, ACCESS_TTL)


def create_refresh_token(uid: str, email: str | None, device_id: str, version: int) -> str:
    return _encode("rt+JWT", uid, email, device_id, REFRESH_TTL, version)


def decode(token: str, typ: str) -> Session | None:
    """Verified session from a token, or None if it is invalid, expired or the wrong type."""
    try:
        if jwt.get_unverified_header(token).get("typ") != typ:
            return None
        claims = jwt.decode(token, config.JWT_SECRET, algorithms=[ALGORITHM])
        # Tokens from before refresh versions count as the first version
        return Session(uid=claims["uid"], device_id=claims["jti"], version=claims.get("ver", 0))
    except (jwt.InvalidTokenError, KeyError):
        return None


async def session_status(session: Session) -> str:
    """'ok', 'disabled' or 'unknown' (signed out, removed device or deleted account)."""
    row = await db.fetch_one(
        """
        SELECT u.disabled FROM users u
        JOIN user_device d ON d.uid = u.uid
        WHERE u.uid = %s AND d.device_id = %s
        """,
        (session.uid, session.device_id),
    )
    if row is None:
        return "unknown"
    return "disabled" if row[0] else "ok"


async def check_access_token(token: str | None, allow_disabled: bool = False) -> Session:
    session = decode(token, "at+JWT") if token else None
    if session is None:
        raise HTTPException(status_code=401, detail="Access token expired")
    status = await session_status(session)
    if status == "unknown":
        raise HTTPException(status_code=401, detail="User does not exist")
    if status == "disabled" and not allow_disabled:
        raise HTTPException(status_code=401, detail="Disabled")
    return session


async def current_session(request: Request) -> Session:
    """Route dependency: the app sends its access token in the JSON body."""
    data = await request.json()
    return await check_access_token(data.get("at+JWT"))


# Stream tokens go in the audio URL because the native player can't refresh a
# bearer token mid-queue. They expire after STREAM_TTL and the app gets a new one
# with every access token, and they are revoked by removing the device or
# disabling the user. They're signed with a key of their own, derived from the
# JWT secret, so neither kind of token can be forged from the other.
_STREAM_KEY = hmac.new(config.JWT_SECRET.encode(), b"pongo stream tokens", hashlib.sha256).digest()


def _b64(value: str) -> str:
    return base64.urlsafe_b64encode(value.encode()).decode().rstrip("=")


def _unb64(value: str) -> str:
    return base64.urlsafe_b64decode(value + "=" * (-len(value) % 4)).decode()


def _stream_signature(uid: str, device_id: str, expires: int) -> str:
    message = f"stream:{uid}:{device_id}:{expires}".encode()
    return hmac.new(_STREAM_KEY, message, hashlib.sha256).hexdigest()


def create_stream_token(uid: str, device_id: str) -> str:
    expires = int(time.time() + STREAM_TTL.total_seconds())
    return f"{_b64(uid)}.{_b64(device_id)}.{expires}.{_stream_signature(uid, device_id, expires)}"


async def check_stream_token(token: str | None) -> Session:
    try:
        encoded_uid, encoded_device, expires, signature = (token or "").split(".")
        session = Session(uid=_unb64(encoded_uid), device_id=_unb64(encoded_device))
        expires = int(expires)
    except ValueError:
        raise HTTPException(status_code=401, detail="Invalid stream token")
    expected = _stream_signature(session.uid, session.device_id, expires)
    if not hmac.compare_digest(signature, expected) or expires < time.time():
        raise HTTPException(status_code=401, detail="Invalid stream token")
    if await session_status(session) != "ok":
        raise HTTPException(status_code=401, detail="Invalid stream token")
    return session
