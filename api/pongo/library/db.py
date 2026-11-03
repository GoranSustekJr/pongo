from psycopg_pool import AsyncConnectionPool

from library import config

pool = AsyncConnectionPool(config.DATABASE_URL, min_size=2, max_size=20, open=False)


async def fetch_one(query: str, params: tuple = ()):
    async with pool.connection() as conn:
        cur = await conn.execute(query, params)
        return await cur.fetchone()


async def fetch_all(query: str, params: tuple = ()):
    async with pool.connection() as conn:
        cur = await conn.execute(query, params)
        return await cur.fetchall()


async def execute(query: str, params: tuple = ()) -> None:
    async with pool.connection() as conn:
        await conn.execute(query, params)


async def track_durations(stids: list[str]) -> list[list]:
    """[[stid, duration], ...] for the given tracks that are already on the server."""
    if not stids:
        return []
    rows = await fetch_all(
        "SELECT stid, duration FROM track WHERE stid = ANY(%s)", (stids,)
    )
    return [[stid, duration] for stid, duration in rows]


async def track_duration(stid: str) -> float | None:
    row = await fetch_one("SELECT duration FROM track WHERE stid = %s", (stid,))
    return row[0] if row else None


async def track_audio_path(stid: str) -> str | None:
    row = await fetch_one(
        "SELECT a.path FROM track t JOIN audio a USING (auid) WHERE t.stid = %s",
        (stid,),
    )
    return row[0] if row else None
