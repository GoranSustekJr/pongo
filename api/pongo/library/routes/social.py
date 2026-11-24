"""Friends: people find each other by name or invite code, follow each other, and see
and follow the playlists each chooses to show on their profile.

People are known to each other by their friend code, never by their uid or email.
Shared playlists are read from the owner's synced library, so they stay up to date.
"""
import secrets

import psycopg
from fastapi import APIRouter, Depends, HTTPException, Request

from library import db, limits, listen
from library.auth.tokens import Session, current_session

router = APIRouter(prefix="/social")

# No 0/O or 1/I, so codes read out loud or typed don't get mixed up
_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
CODE_LENGTH = 8
MAX_RESULTS = 20


def normalize_code(text: str) -> str:
    """The friend code in what the user typed or pasted, such as a pongo://friend/ link."""
    text = (text or "").strip().rstrip("/").rsplit("/", 1)[-1]
    return "".join(c for c in text.upper() if c.isalnum())


def summarize(key: str, data: dict) -> dict:
    """A playlist's title and size from its synced data, without its tracks."""
    tracks = [t for t in data.get("tracks") or [] if not t.get("hidden")]
    return {
        "key": key,
        "title": data.get("title") or "",
        "count": len(tracks),
        "has_cover": bool(data.get("cover")),
        # Stands in for a cover the owner didn't set
        "image": next((t.get("image") for t in tracks if t.get("image")), None),
    }


def shown_tracks(data: dict) -> list[dict]:
    """The tracks others see: the owner's hidden ones stay private."""
    fields = ("stid", "title", "artists", "image", "album")
    return [{f: t.get(f) for f in fields} for t in data.get("tracks") or [] if not t.get("hidden")]


async def _code(uid: str) -> str:
    """The user's friend code, made on first use."""
    row = await db.fetch_one("SELECT friend_code FROM users WHERE uid = %s", (uid,))
    if row and row[0]:
        return row[0]
    while True:
        code = "".join(secrets.choice(_ALPHABET) for _ in range(CODE_LENGTH))
        try:
            await db.execute(
                "UPDATE users SET friend_code = %s WHERE uid = %s AND friend_code IS NULL", (code, uid)
            )
        except psycopg.errors.UniqueViolation:
            continue
        row = await db.fetch_one("SELECT friend_code FROM users WHERE uid = %s", (uid,))
        return row[0]


async def _person(code: str) -> tuple[str, str, str | None]:
    """The uid, name and picture of the enabled user with friend [code]. Raises 404."""
    row = await db.fetch_one(
        "SELECT uid, name, picture FROM users WHERE friend_code = %s AND NOT disabled", (normalize_code(code),)
    )
    if row is None:
        raise HTTPException(status_code=404, detail="no_such_person")
    return row


async def _following(uid: str, others: list[str]) -> set[str]:
    rows = await db.fetch_all(
        "SELECT followee FROM follow WHERE uid = %s AND followee = ANY(%s)", (uid, others)
    )
    return {r[0] for r in rows}


async def _people(uid: str, rows) -> list[dict]:
    """Summaries of the users in rows of (uid, name, picture, friend_code)."""
    following = await _following(uid, [r[0] for r in rows])
    people = []
    for other, name, picture, code in rows:
        people.append({
            "code": code or await _code(other), "name": name or "", "picture": picture,
            "following": other in following, "you": other == uid,
        })
    return people


async def _shared(owner: str, key: str, viewer: str) -> dict:
    """The synced data of [owner]'s playlist [key] if [viewer] may see it. Raises 404."""
    row = await db.fetch_one(
        """
        SELECT s.data FROM sync_item s
        WHERE s.uid = %s AND s.kind = 'online_playlist' AND s.key = %s AND s.data IS NOT NULL
          AND (s.uid = %s OR EXISTS (SELECT 1 FROM shared_playlist p WHERE p.uid = s.uid AND p.key = s.key))
        """,
        (owner, key, viewer),
    )
    if row is None:
        raise HTTPException(status_code=404, detail="not_shared")
    return row[0]


async def _body(request: Request) -> dict:
    try:
        data = await request.json()
    except ValueError:
        data = None
    return data if isinstance(data, dict) else {}


@router.post("/me")
async def me(session: Session = Depends(current_session)):
    """Your friend code, how many follow you and whom you follow, and the keys of the
    playlists you show on your profile."""
    code = await _code(session.uid)
    row = await db.fetch_one(
        """
        SELECT name, picture,
               (SELECT count(*) FROM follow WHERE followee = %s),
               (SELECT count(*) FROM follow WHERE uid = %s)
        FROM users WHERE uid = %s
        """,
        (session.uid, session.uid, session.uid),
    )
    shared = await db.fetch_all("SELECT key FROM shared_playlist WHERE uid = %s", (session.uid,))
    return {
        "code": code, "name": row[0] or "", "picture": row[1], "followers": row[2], "following": row[3],
        "shared": [r[0] for r in shared],
    }


@router.post("/search")
async def search(request: Request, session: Session = Depends(current_session)):
    """People on this server whose name contains the query, or whose friend code it is."""
    limits.check(limits.people_searches, session.uid)
    query = str((await _body(request)).get("query") or "").strip()
    if len(query) < 2:
        return {"people": []}
    rows = await db.fetch_all(
        """
        SELECT uid, name, picture, friend_code FROM users
        WHERE NOT disabled AND uid <> %s AND (friend_code = %s OR name ILIKE %s)
        ORDER BY friend_code = %s DESC, name
        LIMIT %s
        """,
        (session.uid, normalize_code(query), f"%{_like(query)}%", normalize_code(query), MAX_RESULTS),
    )
    return {"people": await _people(session.uid, rows)}


def _like(text: str) -> str:
    return text.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_")


@router.post("/profile")
async def profile(request: Request, session: Session = Depends(current_session)):
    """A person, their follower counts and the playlists they show."""
    other, name, picture = await _person((await _body(request)).get("code"))
    counts = await db.fetch_one(
        """
        SELECT (SELECT count(*) FROM follow WHERE followee = %s),
               (SELECT count(*) FROM follow WHERE uid = %s),
               EXISTS (SELECT 1 FROM follow WHERE uid = %s AND followee = %s),
               EXISTS (SELECT 1 FROM follow WHERE uid = %s AND followee = %s)
        """,
        (other, other, session.uid, other, other, session.uid),
    )
    rows = await db.fetch_all(
        """
        SELECT s.key, s.data FROM shared_playlist p
        JOIN sync_item s ON s.uid = p.uid AND s.kind = 'online_playlist' AND s.key = p.key
        WHERE p.uid = %s AND s.data IS NOT NULL
        ORDER BY p.shared_at DESC
        """,
        (other,),
    )
    return {
        "code": await _code(other), "name": name or "", "picture": picture, "you": other == session.uid,
        "followers": counts[0], "following_count": counts[1], "following": counts[2], "follows_you": counts[3],
        "playlists": [summarize(key, data) for key, data in rows],
    }


@router.post("/follow")
async def follow(request: Request, session: Session = Depends(current_session)):
    data = await _body(request)
    other, _, _ = await _person(data.get("code"))
    if other == session.uid:
        raise HTTPException(status_code=422, detail="yourself")
    if data.get("follow", True):
        await db.execute("INSERT INTO follow (uid, followee) VALUES (%s, %s) ON CONFLICT DO NOTHING",
                         (session.uid, other))
    else:
        await db.execute("DELETE FROM follow WHERE uid = %s AND followee = %s", (session.uid, other))
    return {"following": bool(data.get("follow", True))}


@router.post("/people")
async def people(request: Request, session: Session = Depends(current_session)):
    """Whom you follow, or with "followers", who follows you."""
    followers = (await _body(request)).get("which") == "followers"
    rows = await db.fetch_all(
        f"""
        SELECT u.uid, u.name, u.picture, u.friend_code FROM follow f
        JOIN users u ON u.uid = f.{"uid" if followers else "followee"}
        WHERE f.{"followee" if followers else "uid"} = %s AND NOT u.disabled
        ORDER BY f.created DESC
        """,
        (session.uid,),
    )
    return {"people": await _people(session.uid, rows)}


@router.post("/playlist")
async def playlist(request: Request, session: Session = Depends(current_session)):
    """A playlist someone shows on their profile, with its tracks."""
    data = await _body(request)
    owner, name, picture = await _person(data.get("code"))
    key = str(data.get("key") or "")
    content = await _shared(owner, key, session.uid)
    counts = await db.fetch_one(
        """
        SELECT (SELECT count(*) FROM playlist_follow WHERE owner = %s AND key = %s),
               EXISTS (SELECT 1 FROM playlist_follow WHERE uid = %s AND owner = %s AND key = %s)
        """,
        (owner, key, session.uid, owner, key),
    )
    return {
        **summarize(key, content),
        "owner": {"code": await _code(owner), "name": name or "", "picture": picture, "you": owner == session.uid},
        "cover": content.get("cover"),
        "tracks": shown_tracks(content),
        "followers": counts[0], "followed": counts[1],
    }


@router.post("/cover")
async def cover(request: Request, session: Session = Depends(current_session)):
    """The cover of a shared playlist, as base64 JPEG, kept out of the lists for their size."""
    data = await _body(request)
    owner, _, _ = await _person(data.get("code"))
    return {"cover": (await _shared(owner, str(data.get("key") or ""), session.uid)).get("cover")}


@router.post("/follow_playlist")
async def follow_playlist(request: Request, session: Session = Depends(current_session)):
    """Adds a shared playlist to your library, or with follow false, removes it."""
    data = await _body(request)
    owner, _, _ = await _person(data.get("code"))
    key = str(data.get("key") or "")
    if owner == session.uid:
        raise HTTPException(status_code=422, detail="yours")
    if data.get("follow", True):
        await _shared(owner, key, session.uid)
        await db.execute(
            "INSERT INTO playlist_follow (uid, owner, key) VALUES (%s, %s, %s) ON CONFLICT DO NOTHING",
            (session.uid, owner, key),
        )
    else:
        await db.execute("DELETE FROM playlist_follow WHERE uid = %s AND owner = %s AND key = %s",
                         (session.uid, owner, key))
    return {"followed": bool(data.get("follow", True))}


@router.post("/followed_playlists")
async def followed_playlists(session: Session = Depends(current_session)):
    """The shared playlists in your library, while their owners still show them."""
    rows = await db.fetch_all(
        """
        SELECT u.uid, u.name, u.picture, u.friend_code, s.key, s.data FROM playlist_follow f
        JOIN shared_playlist p ON p.uid = f.owner AND p.key = f.key
        JOIN sync_item s ON s.uid = f.owner AND s.kind = 'online_playlist' AND s.key = f.key
        JOIN users u ON u.uid = f.owner
        WHERE f.uid = %s AND s.data IS NOT NULL AND NOT u.disabled
        ORDER BY f.created DESC
        """,
        (session.uid,),
    )
    playlists = []
    for owner, name, picture, code, key, data in rows:
        playlists.append({
            **summarize(key, data),
            "owner": {"code": code or await _code(owner), "name": name or "", "picture": picture, "you": False},
        })
    return {"playlists": playlists}


@router.post("/share_playlist")
async def share_playlist(request: Request, session: Session = Depends(current_session)):
    """Shows one of your online playlists on your profile, or with shared false, hides it.
    Hiding it also takes it out of the libraries of those who added it, until it's shown again."""
    data = await _body(request)
    key = str(data.get("key") or "")
    if not key or len(key) > 64:
        raise HTTPException(status_code=422, detail="no_key")
    if data.get("shared", True):
        await db.execute("INSERT INTO shared_playlist (uid, key) VALUES (%s, %s) ON CONFLICT DO NOTHING",
                         (session.uid, key))
    else:
        await db.execute("DELETE FROM shared_playlist WHERE uid = %s AND key = %s", (session.uid, key))
    return {"shared": bool(data.get("shared", True))}


async def _related(uid: str, other: str) -> bool:
    """Whether either of the two follows the other."""
    row = await db.fetch_one(
        "SELECT EXISTS (SELECT 1 FROM follow WHERE (uid = %s AND followee = %s) OR (uid = %s AND followee = %s))",
        (uid, other, other, uid),
    )
    return bool(row and row[0])


@router.post("/invite")
async def invite(request: Request, session: Session = Depends(current_session)):
    """Asks the person with friend code `code` to listen along with the user's session
    `session`. Only people who follow each other one way or the other can ask."""
    data = await _body(request)
    other, _, _ = await _person(data.get("code"))
    if other == session.uid:
        raise HTTPException(status_code=422, detail="yourself")
    limits.check(limits.people_searches, session.uid)
    listening = listen.hub.find(str(data.get("session") or ""))
    inviter = listening.members.get(session.uid) if listening else None
    if listening is None or inviter is None or not inviter.present:
        raise HTTPException(status_code=404, detail="no_session")
    if not await _related(session.uid, other):
        raise HTTPException(status_code=403, detail="not_friends")
    if other in {m.uid for m in listening.present()}:
        return {"ok": True, "already": True}
    if not await listen.hub.invite(listening, inviter, await _code(session.uid), other):
        raise HTTPException(status_code=429, detail="too_many_invites")
    return {"ok": True}


@router.post("/invites")
async def invites(session: Session = Depends(current_session)):
    """The user's invitations to listen together that are still open."""
    return {"invites": [i.describe() for i in listen.hub.invites_for(session.uid)]}


@router.post("/answer_invite")
async def answer_invite(request: Request, session: Session = Depends(current_session)):
    """Accepts or declines the invitation to session `session`; whoever asked is told."""
    data = await _body(request)
    row = await db.fetch_one("SELECT name FROM users WHERE uid = %s", (session.uid,))
    await listen.hub.answer(
        session.uid, (row[0] if row else "") or "", str(data.get("session") or "").strip().upper(),
        data.get("accept") is True,
    )
    return {"ok": True}
