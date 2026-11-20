"""Keeps a user's library the same on all their devices.

The app sends the items it changed since it last synced and the cursor it got
then; the server keeps whichever change to an item is newest, and answers with
everything changed since the cursor, including the app's own changes, and the
newer version of any item whose change lost.
"""
import json
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException, Request

from library import db
from library.auth.tokens import Session, current_session

router = APIRouter()

KINDS = {
    "favourite", "online_playlist", "local_playlist",
    "played_track", "played_artist", "search", "sleep_alarm", "lyrics_delay", "setting", "play_count",
}
MAX_CHANGES = 500
MAX_ITEM_BYTES = 2_000_000
MAX_KEY_LENGTH = 200
PAGE_SIZE = 500
# A device whose clock runs ahead can't make its changes win for longer than this
MAX_CLOCK_AHEAD = timedelta(minutes=5)


def _parse_change(change: dict) -> tuple[str, str, str | None, datetime]:
    kind, key, data = change.get("kind"), change.get("key"), change.get("data")
    if kind not in KINDS or not isinstance(key, str) or not 0 < len(key) <= MAX_KEY_LENGTH:
        raise HTTPException(status_code=422, detail="Bad sync item")
    encoded = None if data is None else json.dumps(data)
    if encoded is not None and len(encoded) > MAX_ITEM_BYTES:
        raise HTTPException(status_code=413, detail="Sync item too large")
    try:
        changed_at = datetime.fromtimestamp(int(change["changed_at"]) / 1000, timezone.utc)
    except (KeyError, TypeError, ValueError, OverflowError, OSError):
        raise HTTPException(status_code=422, detail="Bad sync time")
    return kind, key, encoded, min(changed_at, datetime.now(timezone.utc) + MAX_CLOCK_AHEAD)


@router.post("/sync")
async def sync(request: Request, session: Session = Depends(current_session)):
    body = await request.json()
    if not isinstance(body, dict):
        raise HTTPException(status_code=422, detail="Bad sync request")
    changes = body.get("changes") or []
    if not isinstance(changes, list) or len(changes) > MAX_CHANGES:
        raise HTTPException(status_code=413, detail="Too many sync items")
    cursor = body.get("cursor") or 0
    if not isinstance(cursor, int) or isinstance(cursor, bool):
        raise HTTPException(status_code=422, detail="Bad cursor")
    parsed = [_parse_change(change if isinstance(change, dict) else {}) for change in changes]

    async with db.pool.connection() as conn:
        # One sync per user at a time, so changes commit in seq order and a pull can't skip any
        await conn.execute("SELECT pg_advisory_xact_lock(hashtext(%s))", (session.uid,))
        lost = []
        for kind, key, data, changed_at in parsed:
            stored = await conn.execute(
                """
                INSERT INTO sync_item (uid, kind, key, data, changed_at)
                VALUES (%s, %s, %s, %s::jsonb, %s)
                ON CONFLICT (uid, kind, key) DO UPDATE
                SET data = EXCLUDED.data, changed_at = EXCLUDED.changed_at, seq = nextval('sync_seq')
                WHERE sync_item.changed_at < EXCLUDED.changed_at
                RETURNING seq
                """,
                (session.uid, kind, key, data, changed_at),
            )
            if await stored.fetchone() is None:
                lost.append((kind, key))
        rows = await (
            await conn.execute(
                """
                SELECT kind, key, data, changed_at, seq FROM sync_item
                WHERE uid = %s AND seq > %s ORDER BY seq LIMIT %s
                """,
                (session.uid, cursor, PAGE_SIZE + 1),
            )
        ).fetchall()
        more = len(rows) > PAGE_SIZE
        rows = rows[:PAGE_SIZE]
        # The app already has these, or will get them on a later page; otherwise it
        # wouldn't learn that its change lost
        pulled = {(kind, key) for kind, key, *_ in rows}
        lost = [item for item in lost if item not in pulled]
        if lost:
            winners = await (
                await conn.execute(
                    """
                    SELECT kind, key, data, changed_at, seq FROM sync_item
                    WHERE uid = %s AND (kind, key) IN (SELECT * FROM unnest(%s::text[], %s::text[]))
                    """,
                    (session.uid, [kind for kind, _ in lost], [key for _, key in lost]),
                )
            ).fetchall()
        else:
            winners = []

    return {
        "changes": [
            {
                "kind": kind,
                "key": key,
                "data": data,
                "changed_at": int(changed_at.timestamp() * 1000),
            }
            for kind, key, data, changed_at, _ in rows + winners
        ],
        "cursor": rows[-1][4] if rows else cursor,
        "more": more,
    }
