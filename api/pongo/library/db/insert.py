import subprocess
from library.db import select

# Insert new user
def insert_new_user(uid, email, name, picture, apple_auth, hidden_auth, connection, cursor):
    try:
        new_uid = False
        qry_select = "SELECT uid FROM users WHERE uid = %s"
        cursor.execute(qry_select, (uid, ))
        user_id = cursor.fetchone()
        if user_id == None:
            # Insert to the users table
            qry_insert = "INSERT INTO users ( uid, email, created, name, picture, max_devices, apple_auth, hidden_auth, disabled ) VALUES ( %s, %s, CURRENT_TIMESTAMP, %s, %s, 1, %s, %s, %s ) RETURNING uid"
            cursor.execute(qry_insert, (uid, email, name, picture, apple_auth, hidden_auth, True, ))
            user_id = cursor.fetchone()[0]

            # Give the basic subscription
            qry_insert_subscription = "INSERT INTO subscription ( uid, sid, start_time, expire_time ) VALUES ( %s, 'basic', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP )"
            cursor.execute(qry_insert_subscription, (uid, ))
            connection.commit()
            new_uid = True
        return user_id, new_uid
    except Exception as e:
        print(e)
        connection.rollback()
        return None
    
    
# Insert 1 month of premium
def insert_premium(uid, start_time, expire_time, connection, cursor):
    try:
        qry = "UPDATE subscription SET sid = 'premium', start_time = %s, expire_time = %s WHERE uid = %s"
        cursor.execute(qry, (start_time, expire_time, uid))
        connection.commit()
    except Exception as e:
        print(e)
        connection.rollback()


# Insert spotify track id (stid)
def insert_stid(stid, ytvid, connection, cursor):
    try:
        new = False
        qry_check = "SELECT ytvid FROM track WHERE stid = %s"

        cursor.execute(qry_check, (stid, ))

        ytvid_temp = cursor.fetchone()
        if ytvid_temp == None:
            new = True
            qry = "INSERT INTO track ( stid, ytvid ) VALUES ( %s, %s )" # Returning new youtube video id
            cursor.execute(qry, (stid, ytvid, ))
            connection.commit()
        return new
    except Exception as e:
        print(e)
        connection.rollback()
        return False


# Insert track audio
def insert_track_audio(audio, stid, connection, cursor):
    try:
        cmd = ["sha512sum", audio]
        sha512sum = subprocess.run(cmd, capture_output=True, text=True).stdout.split()[0] # Get audio checksum
        qry_select = "SELECT auid FROM audio WHERE hash = %s" # Try to get auid ( audio id )
        cursor.execute(qry_select, (sha512sum, ))
        auid = cursor.fetchone()
        if auid == None:
            qry_insert = "INSERT INTO audio ( audio, hash ) VALUES ( %s, %s ) RETURNING auid"
            audio_data = None
            with open(audio, 'rb') as file:
                audio_data = file.read()
            cursor.execute(qry_insert, (audio_data, sha512sum, ))
            auid = cursor.fetchone()

        qry_connect = "INSERT INTO track_id_audio_id ( stid, auid ) VALUES ( %s, %s )"
        cursor.execute(qry_connect, (stid, auid, ))
        connection.commit()
    except Exception as e:
        connection.rollback()
        print(e)


# Insert track duration
def insert_track_duration(duration, stid, connection, cursor):
    try:
        qry_select = "SELECT duration FROM duration WHERE stid = %s"
        cursor.execute(qry_select, (stid, ))
        dstid = cursor.fetchone()

        if dstid == None:
            qry_insert = "INSERT INTO duration ( stid, duration ) VALUES ( %s, %s )"
            cursor.execute(qry_insert, (stid, duration, ))
            connection.commit()
    except Exception as e:
        print(e)
        connection.rollback()
        



# Insert device for an uid
def insert_device(uid, device_id, connection, cursor):
    try:
        max_devices = select.select_max_devices_for_uid(uid, connection, cursor)
        devices = select.select_devices_for_uid(uid, connection, cursor)
        removed = False
        
        # Remove one device_id if there are too many
        if len(devices) >= max_devices[0]:

            dev_id = device_id
            for device in devices:
                if device[0] != device_id:
                    dev_id = device[0]
            
            qry = "DELETE FROM user_device WHERE uid = %s AND device_id = %s"
            cursor.execute(qry, (uid, dev_id, ))
            connection.commit()
            
        # Insert device_id
        qry2 = "INSERT INTO user_device ( uid, device_id ) VALUES ( %s, %s )"
        cursor.execute(qry2, (uid, device_id, ))
        connection.commit()
    except Exception as e:
        print(e)