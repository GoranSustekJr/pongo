"""Applies the numbered SQL files in migrations/ that the database hasn't seen yet.

database/init only runs when the database is first created; changes after that
go here, one file each, applied in order at startup.
"""
import logging
from pathlib import Path

from library import db

log = logging.getLogger(__name__)

MIGRATIONS_DIR = Path(__file__).resolve().parent.parent / "migrations"
# Any constant works; it only keeps two starting servers from migrating at once
_LOCK_ID = 7_220_116


async def apply_pending(directory: Path = MIGRATIONS_DIR) -> list[str]:
    """Applies pending migrations, each in its own transaction. Returns their names."""
    applied = []
    async with db.pool.connection() as conn:
        await conn.execute("SELECT pg_advisory_lock(%s)", (_LOCK_ID,))
        try:
            await conn.execute(
                """
                CREATE TABLE IF NOT EXISTS schema_migrations (
                    name     text PRIMARY KEY,
                    applied  timestamptz NOT NULL DEFAULT now()
                )
                """
            )
            await conn.commit()
            cursor = await conn.execute("SELECT name FROM schema_migrations")
            done = {row[0] for row in await cursor.fetchall()}
            # So each migration below commits on its own instead of inside this read
            await conn.commit()
            for path in sorted(directory.glob("*.sql")):
                if path.name in done:
                    continue
                async with conn.transaction():
                    await conn.execute(path.read_text())
                    await conn.execute(
                        "INSERT INTO schema_migrations (name) VALUES (%s)", (path.name,)
                    )
                log.info("Applied migration %s", path.name)
                applied.append(path.name)
        finally:
            await conn.execute("SELECT pg_advisory_unlock(%s)", (_LOCK_ID,))
    return applied
