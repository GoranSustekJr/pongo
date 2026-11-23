"""Username and password accounts, for servers without Google sign-in.

Passwords are hashed with scrypt from the standard library. There's no email, so a
forgotten password is reset by whoever runs the server, who can also create accounts
on a server where people can't sign up by themselves:
    docker compose exec api python -m library.auth.passwords reset <username>
    docker compose exec api python -m library.auth.passwords create <username>
"""
import asyncio
import base64
import hashlib
import hmac
import re
import secrets

from library import db

# 32 MB and about 0.1 s per hash; sign-ins are rate limited per IP
_N, _R, _P = 2**15, 8, 1
_MAXMEM = 64 * 1024 * 1024
MIN_PASSWORD = 8
MAX_PASSWORD = 1024
_USERNAME = re.compile(r"^[a-z0-9][a-z0-9._@+-]{2,63}$")


class InvalidInput(ValueError):
    pass


def normalize_username(username: str | None) -> str:
    name = (username or "").strip().lower()
    if not _USERNAME.match(name):
        raise InvalidInput(
            "Usernames are 3 to 64 letters, numbers and . _ @ + -, starting with a letter or number"
        )
    return name


def check_password(password: str | None) -> str:
    password = password or ""
    if not MIN_PASSWORD <= len(password) <= MAX_PASSWORD:
        raise InvalidInput(f"Passwords need at least {MIN_PASSWORD} characters")
    return password


def _b64(data: bytes) -> str:
    return base64.b64encode(data).decode()


def _scrypt(password: str, salt: bytes, n: int, r: int, p: int) -> bytes:
    return hashlib.scrypt(password.encode(), salt=salt, n=n, r=r, p=p, maxmem=_MAXMEM, dklen=32)


def hash_password(password: str) -> str:
    salt = secrets.token_bytes(16)
    key = _scrypt(password, salt, _N, _R, _P)
    return f"scrypt${_N}${_R}${_P}${_b64(salt)}${_b64(key)}"


def verify_password(password: str, stored: str) -> bool:
    try:
        scheme, n, r, p, salt, key = stored.split("$")
        if scheme != "scrypt":
            return False
        actual = _scrypt(password, base64.b64decode(salt), int(n), int(r), int(p))
        return hmac.compare_digest(actual, base64.b64decode(key))
    except (ValueError, TypeError):
        return False


# Checked against when the username doesn't exist, so the answer takes as long
_DUMMY = hash_password(secrets.token_hex(16))


async def find(username: str, password: str) -> str | None:
    """The uid of the account if [password] is right for [username]."""
    row = await db.fetch_one("SELECT uid, hash FROM password_account WHERE username = %s", (username,))
    stored = row[1] if row else _DUMMY
    ok = await asyncio.to_thread(verify_password, password, stored)
    return row[0] if row and ok else None


async def taken(username: str) -> bool:
    return await db.fetch_one("SELECT 1 FROM password_account WHERE username = %s", (username,)) is not None


async def set_password(uid: str, password: str) -> None:
    hashed = await asyncio.to_thread(hash_password, password)
    await db.execute("UPDATE password_account SET hash = %s, changed = now() WHERE uid = %s", (hashed, uid))


def _ask_password() -> str:
    """Asks twice on a terminal; piped in (docker compose exec -T), reads one line."""
    import getpass
    import sys

    if sys.stdin.isatty():
        password = getpass.getpass("New password: ")
        if getpass.getpass("Again: ") != password:
            raise SystemExit("The passwords don't match")
    else:
        password = sys.stdin.readline().rstrip("\n")
    try:
        return check_password(password)
    except InvalidInput as error:
        raise SystemExit(str(error))


async def _reset(username: str) -> None:
    row = await db.fetch_one(
        "SELECT uid FROM password_account WHERE username = %s", (normalize_username(username),)
    )
    if row is None:
        raise SystemExit(f"No password account called {username}")
    await set_password(row[0], _ask_password())
    # Signs the account out everywhere, so a stolen session ends too
    await db.execute("DELETE FROM user_device WHERE uid = %s", (row[0],))
    print(f"Password changed for {username}; its devices were signed out")


async def _create(username: str) -> None:
    username = normalize_username(username)
    if await taken(username):
        raise SystemExit(f"{username} already exists")
    hashed = hash_password(_ask_password())
    uid = "pw_" + secrets.token_hex(16)
    async with db.pool.connection() as conn:
        await conn.execute(
            "INSERT INTO users (uid, email, name, disabled) VALUES (%s, %s, %s, false)",
            (uid, username, username.split("@")[0]),
        )
        await conn.execute(
            "INSERT INTO password_account (uid, username, hash) VALUES (%s, %s, %s)", (uid, username, hashed)
        )
    print(f"Created {username}")


async def _main(command: str, username: str) -> None:
    await db.pool.open(wait=True)
    try:
        await (_create if command == "create" else _reset)(username)
    finally:
        await db.pool.close()


if __name__ == "__main__":
    import sys

    if len(sys.argv) != 3 or sys.argv[1] not in ("create", "reset"):
        raise SystemExit("Usage: python -m library.auth.passwords create|reset <username>")
    asyncio.run(_main(sys.argv[1], sys.argv[2]))
