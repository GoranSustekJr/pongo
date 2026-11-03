import time
from pathlib import Path

import httpx
import jwt

from library import config

APPLE_TOKEN_URL = "https://appleid.apple.com/auth/token"


def _client_secret() -> str:
    now = int(time.time())
    return jwt.encode(
        {
            "iss": config.APPLE_TEAM_ID,
            "iat": now,
            "exp": now + 600,
            "aud": "https://appleid.apple.com",
            "sub": config.APPLE_CLIENT_ID,
        },
        Path(config.APPLE_PRIVATE_KEY_PATH).read_text(),
        algorithm="ES256",
        headers={"kid": config.APPLE_KEY_ID},
    )


async def exchange_code(authorization_code: str) -> dict:
    """Trade the app's authorization code for the user's identity claims."""
    async with httpx.AsyncClient(timeout=15) as client:
        response = await client.post(
            APPLE_TOKEN_URL,
            data={
                "client_id": config.APPLE_CLIENT_ID,
                "client_secret": _client_secret(),
                "code": authorization_code,
                "grant_type": "authorization_code",
            },
        )
    response.raise_for_status()
    # The token came straight from Apple over TLS, which is what authenticates it (OIDC 3.1.3.7)
    return jwt.decode(response.json()["id_token"], options={"verify_signature": False})
