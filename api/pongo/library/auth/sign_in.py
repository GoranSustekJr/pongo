import asyncio
import logging
from datetime import datetime, timedelta, timezone

from google.auth.transport import requests as google_requests
from google.oauth2 import id_token

from library import config, db
from library.auth import apple, tokens

log = logging.getLogger(__name__)

_GOOGLE_AUDIENCE = {
    "ios": lambda: config.IOS_CLIENT_ID,
    "web": lambda: config.DESKTOP_CLIENT_ID,
}


def _verify_google(token: str, platform: str) -> dict:
    audience = _GOOGLE_AUDIENCE.get(platform, lambda: config.WEB_CLIENT_ID)()
    return id_token.verify_oauth2_token(token, google_requests.Request(), audience)


async def _identity(token: str, platform: str, is_apple: bool) -> dict:
    if is_apple:
        claims = await apple.exchange_code(token)
        return {
            "uid": claims["sub"],
            "email": claims.get("email"),
            "name": "",
            "picture": "",
            "hidden": str(claims.get("is_private_email", "false")).lower() == "true",
        }
    claims = await asyncio.to_thread(_verify_google, token, platform)
    return {
        "uid": claims["sub"],
        "email": claims.get("email"),
        "name": claims.get("name", ""),
        "picture": claims.get("picture", ""),
        "hidden": False,
    }


# A refresh token one version behind still works this long after the device moved on,
# for an app that renewed but didn't get to store the new token
ROTATION_GRACE = timedelta(minutes=5)


class NotAllowed(Exception):
    pass


async def _is_allowed(email: str | None) -> bool:
    email = (email or "").lower()
    if not email:
        return False
    if email in config.ALLOWED_EMAILS:
        return True
    return await db.fetch_one("SELECT 1 FROM allowed_emails WHERE email = %s", (email,)) is not None


async def _store_user_and_device(identity: dict, is_apple: bool, device_id: str) -> int:
    """Stores the user and device and returns the device's new refresh version."""
    enabled = await _is_allowed(identity["email"])
    async with db.pool.connection() as conn:
        exists = await (
            await conn.execute("SELECT 1 FROM users WHERE uid = %s", (identity["uid"],))
        ).fetchone()
        # Strangers aren't stored at all, so sign-in attempts can't fill the database
        if not enabled and not exists:
            raise NotAllowed(identity["email"])
        # An allowed email can turn on an account that already exists, never turn one off
        await conn.execute(
            """
            INSERT INTO users (uid, email, name, picture, apple_auth, hidden_auth, disabled)
            VALUES (%(uid)s, %(email)s, %(name)s, %(picture)s, %(apple)s, %(hidden)s, %(disabled)s)
            ON CONFLICT (uid) DO UPDATE
            SET disabled = users.disabled AND EXCLUDED.disabled
            """,
            {**identity, "apple": is_apple, "disabled": not enabled},
        )
        # Signing in again starts a new refresh version, so the device's older tokens stop working
        cursor = await conn.execute(
            """
            INSERT INTO user_device (uid, device_id) VALUES (%s, %s)
            ON CONFLICT (uid, device_id) DO UPDATE
            SET last_seen = now(), refresh_version = user_device.refresh_version + 1,
                refresh_rotated_at = now()
            RETURNING refresh_version
            """,
            (identity["uid"], device_id),
        )
        version = (await cursor.fetchone())[0]
        # Signing in on a device past the limit signs out the least recently used one
        await conn.execute(
            """
            DELETE FROM user_device WHERE uid = %(uid)s AND device_id IN (
                SELECT device_id FROM user_device WHERE uid = %(uid)s
                ORDER BY last_seen DESC
                OFFSET (SELECT max_devices FROM users WHERE uid = %(uid)s)
            )
            """,
            {"uid": identity["uid"]},
        )
    return version


async def sign_in(token: str, platform: str, device_id: str, is_apple: bool) -> dict | None:
    """Tokens for the account, or None if the sign-in token is invalid. Raises NotAllowed."""
    try:
        identity = await _identity(token, platform, is_apple)
    except Exception:
        log.exception("Sign in rejected (platform=%s, apple=%s)", platform, is_apple)
        return None

    version = await _store_user_and_device(identity, is_apple, device_id)
    uid, email = identity["uid"], identity["email"]
    return {
        "rt+JWT": tokens.create_refresh_token(uid, email, device_id, version),
        "at+JWT": tokens.create_access_token(uid, email, device_id),
        "st": tokens.create_stream_token(uid, device_id),
    }


async def _next_refresh_version(session: tokens.Session) -> int | None:
    """The version to issue the renewed refresh token for, or None to refuse.

    Using a token that is more than one version old, or one version old outside the
    grace period, means someone else has a copy, so the device is signed out.
    """
    async with db.pool.connection() as conn:
        row = await (
            await conn.execute(
                """
                SELECT refresh_version, refresh_rotated_at FROM user_device
                WHERE uid = %s AND device_id = %s FOR UPDATE
                """,
                (session.uid, session.device_id),
            )
        ).fetchone()
        if row is None:
            return None
        current, rotated_at = row
        if session.version == current:
            await conn.execute(
                """
                UPDATE user_device
                SET refresh_version = refresh_version + 1, refresh_rotated_at = now(), last_seen = now()
                WHERE uid = %s AND device_id = %s
                """,
                (session.uid, session.device_id),
            )
            return current + 1
        recent = rotated_at is not None and rotated_at > datetime.now(timezone.utc) - ROTATION_GRACE
        if session.version == current - 1 and recent:
            return current
        await conn.execute(
            "DELETE FROM user_device WHERE uid = %s AND device_id = %s",
            (session.uid, session.device_id),
        )
    log.warning("Old refresh token reused for user %s, signed out device %s", session.uid, session.device_id)
    return None


async def renew(refresh_token: str | None) -> dict | None:
    session = tokens.decode(refresh_token, "rt+JWT") if refresh_token else None
    if session is None or await tokens.session_status(session) == "unknown":
        return None
    version = await _next_refresh_version(session)
    if version is None:
        return None
    row = await db.fetch_one("SELECT email FROM users WHERE uid = %s", (session.uid,))
    return {
        "at": tokens.create_access_token(session.uid, row[0], session.device_id),
        "rt+JWT": tokens.create_refresh_token(session.uid, row[0], session.device_id, version),
        "st": tokens.create_stream_token(session.uid, session.device_id),
    }
