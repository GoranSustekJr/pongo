import spotipy
from spotipy.oauth2 import SpotifyClientCredentials
from library.spotify import api_key_round_robin
from library.db import db, select

def get_playlist(spid: str):
    try:
        # Get the API key and connect
        api_key = api_key_round_robin.get_api_key()
        client_credentials_manager = SpotifyClientCredentials(client_id=api_key["client_id"], client_secret=api_key["client_secret"])
        sp = spotipy.Spotify(client_credentials_manager=client_credentials_manager)

        # Get the tracks
        playlist = sp.playlist_tracks(spid,fields="items(track(id,album(id,name,release_date,images),artists(name,id),name))",limit=100)
        playlist["items"] = [
            track for track in playlist["items"]
            if track.get("track") is not None and track["track"].get("id") is not None
        ]

        # Get tracks duration
        connection, cur = db.connect()
        tracks = select.select_existing_stids(', '.join((f"'{track["track"]["id"]}'" for track in playlist["items"])), connection, cur)

        # Seperate the missing stids
        missing_tracks = []
        for track in playlist["items"]:
            stid = track["track"]["id"]
            if (stid, ) not in tracks:
                missing_tracks.append(stid)
        
        # Get the existing stids duration
        durations = select.select_tracks_duration(', '.join((f"'{track["track"]["id"]}'" for track in playlist["items"])), connection, cur)
        
        # Close the db connection and return the data
        db.close_connection(connection)
        return {"items": playlist["items"], "missing_tracks": missing_tracks, "durations": durations}
    except Exception as e:
        print(e)
        db.close_connection(connection)
        return None


def get_playlist_shuffle(spid: str):
    try:
        # Auth
        api_key = api_key_round_robin.get_api_key()
        client_credentials_manager = SpotifyClientCredentials(client_id=api_key["client_id"], client_secret=api_key["client_secret"])

        # Spotify request
        sp = spotipy.Spotify(client_credentials_manager=client_credentials_manager)
        playlist = sp.playlist_tracks(spid,fields="items(track(id)",limit=100)
        
        # Get the existing durations
        connection, cur = db.connect()
        durations = select.select_tracks_duration(', '.join((f"'{track["track"]["id"]}'" for track in playlist["items"])), connection, cur)
        db.close_connection(connection)
        return {"durations": durations}
    except Exception as e:
        print(e)
        db.close_connection(connection)
        return None
    
