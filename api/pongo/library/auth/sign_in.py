import asyncio
import logging

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


async def _store_user_and_device(identity: dict, is_apple: bool, device_id: str) -> None:
    enabled = (identity["email"] or "").lower() in config.ALLOWED_EMAILS
    async with db.pool.connection() as conn:
        # An allow-listed email can turn on an account that already exists, never turn one off
        await conn.execute(
            """
            INSERT INTO users (uid, email, name, picture, apple_auth, hidden_auth, disabled)
            VALUES (%(uid)s, %(email)s, %(name)s, %(picture)s, %(apple)s, %(hidden)s, %(disabled)s)
            ON CONFLICT (uid) DO UPDATE
            SET disabled = users.disabled AND EXCLUDED.disabled
            """,
            {**identity, "apple": is_apple, "disabled": not enabled},
        )
        await conn.execute(
            """
            INSERT INTO user_device (uid, device_id) VALUES (%s, %s)
            ON CONFLICT (uid, device_id) DO UPDATE SET last_seen = now()
            """,
            (identity["uid"], device_id),
        )
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


async def sign_in(token: str, platform: str, device_id: str, is_apple: bool) -> dict | None:
    try:
        identity = await _identity(token, platform, is_apple)
    except Exception:
        log.exception("Sign in rejected (platform=%s, apple=%s)", platform, is_apple)
        return None

    await _store_user_and_device(identity, is_apple, device_id)
    uid, email = identity["uid"], identity["email"]
    return {
        "rt+JWT": tokens.create_refresh_token(uid, email, device_id),
        "at+JWT": tokens.create_access_token(uid, email, device_id),
        "st": tokens.create_stream_token(uid, device_id),
    }


async def renew(refresh_token: str | None) -> dict | None:
    session = tokens.decode(refresh_token, "rt+JWT") if refresh_token else None
    if session is None or await tokens.session_status(session) == "unknown":
        return None
    row = await db.fetch_one("SELECT email FROM users WHERE uid = %s", (session.uid,))
    return {
        "at": tokens.create_access_token(session.uid, row[0], session.device_id),
        "st": tokens.create_stream_token(session.uid, session.device_id),
    }
