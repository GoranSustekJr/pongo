from datetime import datetime, timedelta, timezone
import jwt
from library.db import db, select
from dotenv import load_dotenv
import os

# Load .env
load_dotenv()

# Get .env vars
secret = os.getenv('JWT_SECRET')
iss = os.getenv('JWT_ISSUER')


### Access Token
def create_access_token(gmail, uid, roles, refresh_token):
    try:
        decoded_jwt = jwt.decode(refresh_token, secret, algorithms=['HS512'])
        headers = {
            "alg": "HS512",
            "typ": "at+JWT"
            }

        payload = { # Specified in RFC7519 and RFC9068
                   "iss": iss, # Issuer
                   "exp": datetime.now(tz=timezone.utc) + timedelta(hours=2), # Expiration time of the token (exp)
                   # "aud": , # OPTIONAL!
                   "sub": str(gmail), # Client Gmail address 
                   "uid": uid, # User id; App specific
                   "iat": datetime.now(tz=timezone.utc), # Token was issued at (iad)
                   "jti": decoded_jwt.get('jti'), # JWT ID, OPTIONAL, using it for device id
                   "roles": roles # User roles, app specific
                   }
        access_token = jwt.encode(payload, secret, algorithm="HS512", headers=headers)
        return access_token
    except jwt.ExpiredSignatureError:
        return None # If None returned, refresh token is expired => user is NOT signed in
    except Exception as e:
        print(e)
        return None # If None returned, refresh token is expired => user is NOT signed in
        

        
### Refresh Token
def create_refresh_token(gmail, uid, roles, device_id):
    try:
        headers = {
            "alg": "HS512",
            "typ": "rt+JWT"
            }
        payload = { # Specified in RFC7519 and RFC9068
                   "iss": iss, # Issuer
                   "exp": datetime.now(tz=timezone.utc) + timedelta(days=90), # Expiration time of the token (exp) 
                   # "aud": , # OPTIONAL!
                   "sub": str(gmail), # Client Gmail address 
                   "uid": uid, # User id; App specific
                   "iat": datetime.now(tz=timezone.utc), # Token was issued at (iad)
                   "jti": device_id, # JWT ID, OPTIONAL, using it for device id
                   "roles": roles # User roles, app specific
                   }
        refresh_token = jwt.encode(payload, secret, algorithm="HS512", headers=headers)
        return refresh_token
    except Exception as e:
        print(e)
        return None
    
# Validate token
def validate_token(token, bypass=False):
    try:
        access_token = jwt.decode(token, secret, algorithms=['HS512'])

        # Get the device_id and uid
        device_id = access_token.get('jti')
        uid = access_token.get('uid')

        # Connect to db
        connection, cur = db.connect()

        # Check if disabled
        disabled = select.disabled(uid, connection, cur)
        if disabled and not bypass:
            raise PermissionError("Disabled")

        # Check if it is in the table
        devices = select.select_devices_for_uid(uid, connection, cur)        
        exists = False
        for device in devices:
            if device[0] == device_id:
                exists = True
        
        if exists == False:
            raise jwt.ExpiredSignatureError
        
        # Close the connection
        db.close_connection(connection)
        
        return access_token["uid"]
    except jwt.ExpiredSignatureError as e:
        print("A ", e)
        return None
    except PermissionError as e:
        print("B ", e)
        db.close_connection(connection)
        return "Disabled"
    except Exception as e:
        print("C ", e)
        db.close_connection(connection)
        return None
    
    
    
# Get uid from access_token
def get_uid_from_at(refresh_token):
    try:
        return jwt.decode(refresh_token, options={"verify_signature": False})["uid"]
    except Exception as e:
        print(e)
        return None
    
