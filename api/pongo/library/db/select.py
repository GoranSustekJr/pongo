import base64
from datetime import datetime, timezone, timedelta

# Select user email
def select_user_email(uid, connection, cursor):
    try:
        qry = "SELECT email FROM users WHERE uid = %s"
        cursor.execute(qry, (uid, ))
        return cursor.fetchone()[0]
    except Exception as e:
        print(e)
        return None

# Is current plan premium
def is_premium(uid, connection, cursor):
    try:
        qry = "SELECT sid, expire_time FROM subscription WHERE uid = %s"
        cursor.execute(qry, (uid, ))
        data = cursor.fetchone()
        if (data[0] == "premium") and ((datetime.fromisoformat(str(data[1])).astimezone(timezone.utc) - datetime.now(timezone.utc)).total_seconds() > 0):
            return True, datetime.fromisoformat(str(data[1])).astimezone(timezone.utc)
        else:
            return False, datetime.now(timezone.utc)
    except Exception as e:
        print(e)
        return False, datetime.now(timezone.utc)
    
# Check if YouTube video is downladed
def check_if_ytvid_exists(yt_vid, connection, cursor):
    try:
        qry = "SELECT stid FROM track WHERE ytvid = %s LIMIT 1"
        cursor.execute(qry, (yt_vid, ))
        data = cursor.fetchone()[0]
        return data    
    except Exception as e:
        print("HHHHHHH", e)
        return None


# Select user data
def select_user_data(uid, connection, cursor):
    try:
        qry = "SELECT email, name, picture, hidden_auth FROM users WHERE uid = %s"
        cursor.execute(qry, (uid, ))
        data = cursor.fetchone()
        return {"email": data[0], "name": data[1], "picture": data[2], "hidden_auth": data[3]}
    except Exception as e:
        print(e)
        return None


# Select track id
def select_ytvid(stid, connection, cursor):
    try:
        qry = "SELECT ytvid FROM track WHERE stid = %s"
        cursor.execute(qry, (stid, ))
        return cursor.fetchone()[0]
    except Exception as e:
        print("SHITTTSS; ", e)
        return None

# Select track duration
def select_track_duration(stid, connection, cursor):
    try:
        qry = "SELECT duration FROM duration WHERE stid = %s"
        cursor.execute(qry, (stid, ))
        duration = cursor.fetchone()[0]
        return duration
    except Exception as e:
        print("TTTTT", e)
        return None
    
# Select if account disabled
def disabled(uid, connection, cursor):
    try:
        qry = "SELECT disabled FROM users WHERE uid = %s"
        cursor.execute(qry, (uid, ))
        return cursor.fetchone()[0]
    except Exception as e:
        print(e)
        return None


# Select audio
def select_audio(stid, connection, cursor):
    try:
        qry = "SELECT audio FROM track_id_audio_id tiai JOIN audio au ON tiai.auid = au.auid WHERE tiai.stid = %s"
        cursor.execute(qry, (stid, ))
        return cursor.fetchone()[0]
    except Exception as e:
        print(e)
        return None


# Select audios and durations
def select_audio_and_duration(stids, connection, cursor):
    try:
        # Placeholder
        placeholders = ', '.join(['%s'] * len(stids))
        
        # Query
        qry = f"""
        SELECT d.stid, d.duration, a.audio
        FROM duration d
        JOIN track_id_audio_id tiai ON d.stid = tiai.stid
        JOIN audio a ON tiai.auid = a.auid
        WHERE d.stid IN ({placeholders})
        """
        
        cursor.execute(qry, tuple(stids))
        results = cursor.fetchall()
        
        result_dict = {stid: (duration, base64.b64encode(bytes(audio)).decode('utf-8')) for stid, duration, audio in results}
        
        return result_dict    
    except Exception as e:
        print(e)
        return None


# Select existing stids
def select_existing_stids(stids, connection, cursor):
    try:
        print("STIDS; ", stids)
        qry = f"SELECT DISTINCT stid FROM track WHERE stid IN ( {stids} )"
        cursor.execute(qry, stids, )
        return cursor.fetchall()
    except Exception as e:
        print(e)
        return None
    
    
# Select tracks duration
def select_tracks_duration(stids, connection, cursor):
    try:
        qry = f"SELECT * FROM duration WHERE stid IN ( {stids} )"
        cursor.execute(qry, (stids, ))
        duration = cursor.fetchall()
        return duration
    except Exception as e:
        print("TTTTT", e)
        return None


# Select random tracks
def select_random_tracks(num: int, connection, cursor):
    try:
        qry = "SELECT stid FROM track ORDER BY RANDOM() LIMIT %s"
        cursor.execute(qry, (num, ))
        return cursor.fetchall()
    except Exception as e:
        print(e)
        return None


# Select all devices for an uid
def select_devices_for_uid(uid, connection, cursor):
    try:
        qry = "SELECT device_id FROM user_device WHERE uid = %s"
        cursor.execute(qry, (uid, ))
        return cursor.fetchall()
    except Exception as e:
        print(2, e)
        return None
    
    
# Select max num of devices for an uid
def select_max_devices_for_uid(uid, connection, cursor):
    try:
        qry = "SELECT max_devices FROM users WHERE uid = %s"
        cursor.execute(qry, (uid, ))
        return cursor.fetchone()
    except Exception as e:
        print(1, e)
        return None
    