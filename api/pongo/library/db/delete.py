def delete_account(uid, connection, cursor):
    try:
        # Delete from users table
        qry = "DELETE FROM users WHERE uid = %s"
        cursor.execute(qry, (uid, ))
        
        # Delete from user_device table
        qry2 = "DELETE FROM user_device WHERE uid = %s"
        cursor.execute(qry2, (uid, ))
        
        connection.commit()
    except Exception as e:
        print(e)