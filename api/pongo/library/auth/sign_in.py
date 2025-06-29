import requests as rq
from jwt import PyJWKClient
from google.auth.transport import requests
from google.oauth2 import id_token
from library.db import insert, select
from library.auth import auth
from library.auth import jwt as jwts
from library.auth import apple_auth
from dotenv import load_dotenv
import os

# Load .env
load_dotenv()

# Get .env vars
web_client_id = os.getenv('WEB_CLIENT_ID') # Web client id
ios_client_id = os.getenv('IOS_CLIENT_ID') # iOS client id
desktop_client_id = os.getenv('DESKTOP_CLIENT_ID') # Desktop client id

# Verify the user in order to log him in
def verify_user(token: str, platform: str, device_id: str, apple: bool, connection, cursor):
    try:
        hidden_auth = False
        if apple == False:
            if platform == "ios": # Checking the platform
                idinfo = id_token.verify_oauth2_token(token, requests.Request(), ios_client_id)
            elif platform == "web":
                idinfo = id_token.verify_oauth2_token(token, requests.Request(), desktop_client_id)
            else:
                idinfo = id_token.verify_oauth2_token(token, requests.Request(), web_client_id) # Authenticating with token obtained from google
        else:
            if platform == "ios":
                # Decode the apple token
                token = apple_auth.retrieve_user_info(token)

                # User and auth info
                idinfo = {
                    "sub": token["sub"],
                    "email": token["email"],
                    "name": "",
                    "picture": "",
                }
                
                # Is info hidden
                try:
                    hidden_auth = token["is_private_email"]
                except Exception as e:
                    print(e)

        # User data
        data = {
            "uid": idinfo["sub"],
            "email": idinfo["email"], 
            "name": idinfo["name"],
            "picture": idinfo["picture"],
        }

        # Insert if new user to db
        insert.insert_new_user(data["uid"], data["email"], data["name"], data["picture"], apple, hidden_auth, connection, cursor)

        # Insert if new device to db
        insert.insert_device(data["uid"], device_id, connection, cursor)

        # Generate and retun refresh and access token
        refresh_token = auth.request_refresh_token(data["uid"], device_id)
        access_token = auth.request_access_token(data["uid"], refresh_token)
        return refresh_token, access_token
    except Exception as e:
        print(e)
        
        
# Renew access token
def renew_access_token(refresh_token):
    try:
        # Extract the uid
        uid = jwts.get_uid_from_at(refresh_token)
        if uid is not None: # get and return the new access token
            access_token = auth.request_access_token(uid, refresh_token)

            return access_token
        else:
            return None
    except Exception as e:
        print(e)
        return None
