from fastapi import APIRouter, Depends, HTTPException, Request

from library import db, limits
from library.auth import sign_in, tokens
from library.auth.tokens import Session, current_session

router = APIRouter()


@router.post("/bed1684d6d16802154bba513a5f0980dd3dc4b612aeb6a05433c28f55936ca7d")
async def sign_in_route(request: Request):
    limits.check(limits.sign_ins, limits.client_ip(request))
    data = await request.json()
    device_id = data.get("device_id")
    if not device_id or not data.get("id_token"):
        raise HTTPException(status_code=400, detail="Missing id_token or device_id")
    try:
        result = await sign_in.sign_in(
            data["id_token"], data.get("platform", ""), device_id, bool(data.get("apple"))
        )
    except sign_in.NotAllowed:
        raise HTTPException(status_code=403, detail="This account isn't allowed on this server")
    if result is None:
        raise HTTPException(status_code=401, detail="Sign in failed")
    return result


@router.post("/renew_at")
async def renew_at(request: Request):
    limits.check(limits.sign_ins, limits.client_ip(request))
    data = await request.json()
    result = await sign_in.renew(data.get("jwt"))
    if result is None:
        raise HTTPException(status_code=401, detail="Refresh token expired")
    return result


@router.post("/user_data")
async def user_data(request: Request):
    data = await request.json()
    # Disabled users can still see their account
    session = await tokens.check_access_token(data.get("at+JWT"), allow_disabled=True)
    row = await db.fetch_one(
        "SELECT email, name, picture, hidden_auth FROM users WHERE uid = %s", (session.uid,)
    )
    if row is None:
        raise HTTPException(status_code=401, detail="User does not exist")
    return {"email": row[0], "name": row[1], "picture": row[2], "hidden_auth": row[3]}


@router.post("/delete_account")
async def delete_account(session: Session = Depends(current_session)):
    await db.execute("DELETE FROM users WHERE uid = %s", (session.uid,))
    return {"deleted": "true"}
