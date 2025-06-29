import spotipy
from spotipy.oauth2 import SpotifyClientCredentials
from library.spotify import api_key_round_robin
from library.db import db, select

def get_album(salid: str):
    try:
        # Get the API key and connect
        api_key = api_key_round_robin.get_api_key()
        client_credentials_manager = SpotifyClientCredentials(client_id=api_key["client_id"], client_secret=api_key["client_secret"])
        sp = spotipy.Spotify(client_credentials_manager=client_credentials_manager)

        # Get the tracks
        album = sp.album_tracks(salid,limit=50)

        # Get tracks durations
        connection, cur = db.connect()
        tracks = select.select_existing_stids(', '.join((f"'{track["id"]}'" for track in album["items"])), connection, cur)

        # Seperate the missing stids
        missing_tracks = []
        for track in album["items"]:
            stid = track["id"]
            if (stid, ) not in tracks:
                missing_tracks.append(stid)

        # Get the existing stids durations
        durations = select.select_tracks_duration(', '.join((f"'{track["id"]}'" for track in album["items"])), connection, cur)
        
        # Close the db connection and return the data
        db.close_connection(connection)
        return {"items": album["items"], "missing_tracks": missing_tracks, "durations": durations}
    except Exception as e:
        print(e)
        db.close_connection(connection)
        return None


def get_album_data(salid: str):
    try:
        api_key = api_key_round_robin.get_api_key()
        print(1.1)
        client_credentials_manager = SpotifyClientCredentials(client_id=api_key["client_id"], client_secret=api_key["client_secret"])
        print(1.2)
        sp = spotipy.Spotify(client_credentials_manager=client_credentials_manager)
        print(1.3)
        album = sp.album(salid)
        print(1.4)
        return album
    except Exception as e:
        print(e)
        return None


def get_album_shuffle(salid: str):
    try:
        api_key = api_key_round_robin.get_api_key()
        print(1.1)
        client_credentials_manager = SpotifyClientCredentials(client_id=api_key["client_id"], client_secret=api_key["client_secret"])
        sp = spotipy.Spotify(client_credentials_manager=client_credentials_manager)
        album = sp.album_tracks(salid,limit=50)
        connection, cur = db.connect()
        durations = select.select_tracks_duration(', '.join((f"'{track["id"]}'" for track in album["items"])), connection, cur)
        db.close_connection(connection)
        return {"durations": durations}
    except Exception as e:
        print(e)
        db.close_connection(connection)
        return None