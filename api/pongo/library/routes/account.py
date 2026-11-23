from fastapi import APIRouter, Depends, HTTPException, Request

from library import config, db, limits
from library.auth import passwords, sign_in, tokens
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


@router.get("/server_info")
async def server_info():
    """What the apps show before signing in: the server's name and how to sign in."""
    return {
        "name": config.SERVER_NAME,
        "google": bool(config.IOS_CLIENT_ID),
        "passwords": config.PASSWORD_ACCOUNTS,
        "signup": config.OPEN_SIGNUP and config.PASSWORD_ACCOUNTS,
    }


async def _password_request(request: Request) -> dict:
    limits.check(limits.sign_ins, limits.client_ip(request))
    data = await request.json()
    if not data.get("device_id") or not data.get("username") or not data.get("password"):
        raise HTTPException(status_code=400, detail="Missing username, password or device_id")
    return data


@router.post("/auth/register")
async def register(request: Request):
    data = await _password_request(request)
    try:
        return await sign_in.register(data["username"], data["password"], data["device_id"], data.get("name", ""))
    except passwords.InvalidInput as error:
        raise HTTPException(status_code=400, detail=str(error))
    except sign_in.UsernameTaken:
        raise HTTPException(status_code=409, detail="That username is taken")
    except sign_in.NotAllowed:
        raise HTTPException(status_code=403, detail="This server doesn't let people create accounts")


@router.post("/auth/login")
async def password_login(request: Request):
    data = await _password_request(request)
    try:
        result = await sign_in.password_sign_in(data["username"], data["password"], data["device_id"])
    except sign_in.NotAllowed:
        raise HTTPException(status_code=403, detail="This server doesn't use passwords")
    if result is None:
        raise HTTPException(status_code=401, detail="Wrong username or password")
    return result


@router.post("/change_password")
async def change_password(request: Request):
    limits.check(limits.sign_ins, limits.client_ip(request))
    data = await request.json()
    session = await tokens.check_access_token(data.get("at+JWT"))
    row = await db.fetch_one("SELECT username FROM password_account WHERE uid = %s", (session.uid,))
    if row is None:
        raise HTTPException(status_code=400, detail="This account has no password")
    if await passwords.find(row[0], data.get("old_password") or "") != session.uid:
        raise HTTPException(status_code=401, detail="Wrong password")
    try:
        new = passwords.check_password(data.get("new_password"))
    except passwords.InvalidInput as error:
        raise HTTPException(status_code=400, detail=str(error))
    await passwords.set_password(session.uid, new)
    # Other devices sign in again with the new password
    await db.execute("DELETE FROM user_device WHERE uid = %s AND device_id <> %s", (session.uid, session.device_id))
    return {"changed": True}


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
        """
        SELECT u.email, u.name, u.picture, u.hidden_auth, p.uid IS NOT NULL FROM users u
        LEFT JOIN password_account p ON p.uid = u.uid WHERE u.uid = %s
        """,
        (session.uid,),
    )
    if row is None:
        raise HTTPException(status_code=401, detail="User does not exist")
    return {"email": row[0], "name": row[1], "picture": row[2], "hidden_auth": row[3], "password": row[4]}


@router.post("/delete_account")
async def delete_account(session: Session = Depends(current_session)):
    await db.execute("DELETE FROM users WHERE uid = %s", (session.uid,))
    return {"deleted": "true"}
