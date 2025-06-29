from library.db import db, select

def get_tracks_duration(stids: list):
    try:
        connection, cur = db.connect()