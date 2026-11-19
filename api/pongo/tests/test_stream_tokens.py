import asyncio

import pytest
from fastapi import HTTPException

from library.auth import tokens


@pytest.fixture(autouse=True)
def every_device_is_signed_in(monkeypatch):
    async def ok(_):
        return "ok"

    monkeypatch.setattr(tokens, "session_status", ok)


def _check(token):
    asyncio.run(tokens.check_stream_token(token))


def test_a_fresh_stream_token_is_accepted():
    _check(tokens.create_stream_token("user", "phone"))


def test_stream_tokens_expire(monkeypatch):
    token = tokens.create_stream_token("user", "phone")
    later = tokens.time.time() + tokens.STREAM_TTL.total_seconds() + 1
    monkeypatch.setattr(tokens.time, "time", lambda: later)
    with pytest.raises(HTTPException):
        _check(token)


def test_a_changed_stream_token_is_refused():
    uid, device, expires, signature = tokens.create_stream_token("user", "phone").split(".")
    # A later expiry, or another device, breaks the signature
    for forged in [
        f"{uid}.{device}.{int(expires) + 999}.{signature}",
        f"{uid}.{tokens._b64('tablet')}.{expires}.{signature}",
    ]:
        with pytest.raises(HTTPException):
            _check(forged)


def test_the_old_token_format_is_refused():
    with pytest.raises(HTTPException):
        _check(f"{tokens._b64('user')}.{tokens._b64('phone')}.deadbeef")


def test_access_and_refresh_tokens_are_not_interchangeable():
    access = tokens.create_access_token("user", "a@b.c", "phone")
    refresh = tokens.create_refresh_token("user", "a@b.c", "phone", 3)
    assert tokens.decode(access, "at+JWT").uid == "user"
    assert tokens.decode(refresh, "rt+JWT").device_id == "phone"
    assert tokens.decode(refresh, "rt+JWT").version == 3
    assert tokens.decode(access, "rt+JWT") is None
    assert tokens.decode(refresh, "at+JWT") is None
