from library.auth import jwt
from library.db import select, db

# Request access token
def request_access_token(uid, refresh_token):
    try:
        connection, cur = db.connect()
        email = select.select_user_email(uid, connection, cur)
        db.close_connection(connection)
        access_token = jwt.create_access_token(email, uid, [], refresh_token)
        return access_token
    except Exception as e:
        print(e)
        return None
        
        
# Request refresh token
def request_refresh_token(uid, device_id):
    try:
        connection, cur = db.connect()
        email = select.select_user_email(uid, connection, cur)
        db.close_connection(connection)
        refresh_token = jwt.create_refresh_token(email, uid, [], device_id)
        return refresh_token
    except Exception as e:
        print(e)
        return None