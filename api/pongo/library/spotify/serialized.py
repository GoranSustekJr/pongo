import spotipy
from spotipy.oauth2 import SpotifyClientCredentials
from library.spotify import api_key_round_robin
from library.db import db, select

def get_serialized_tracks(stids: list):
    try:
        # Get the API key and connect
        api_key = api_key_round_robin.get_api_key()
        client_credentials_manager = SpotifyClientCredentials(client_id=api_key["client_id"], client_secret=api_key["client_secret"])
        sp = spotipy.Spotify(client_credentials_manager=client_credentials_manager)

        # Get the tracks
        tracks = sp.tracks(stids)
        
        # Get tracks duration
        connection, cur = db.connect()
        existing_tracks = select.select_existing_stids(', '.join((f"'{stid}'" for stid in stids)), connection, cur)

        
        # Seperate the missing stids
        missing_tracks = []
        for stid in stids:
            if (stid, ) not in existing_tracks:
                missing_tracks.append(stid)
        
        # Get the existing stids duration
        print("HFDAJKSHFKAJFHDAKJFA; ", ', '.join((f"'{track[0]}'" for track in existing_tracks)))
        durations = select.select_tracks_duration(', '.join((f"'{track[0]}'" for track in existing_tracks)), connection, cur)
        
        # Close the db connection and return the data
        db.close_connection(connection)
        return {"tracks": tracks, "missing_tracks": missing_tracks, "durations": durations}
    except Exception as e:
        print(e)
        db.close_connection(connection)
        return None
    

def get_serialized_shuffle(stids: list):
    try:
        # Get the durations
        connection, cur = db.connect()
        durations = select.select_tracks_duration(', '.join(f"'{stid}'" for stid in stids), connection, cur)
        db.close_connection(connection)
        
        # init vars
        missing_tracks = []
        existing_tracks = []
        
        # Extract the missing tracks and existing durations
        for duration in durations:
            stid = duration[0]
            print(stid in stids)
            if stid in stids:
                existing_tracks.append(stid)
        for stid in stids:
            if stid not in existing_tracks:
                missing_tracks.append(stid)
        return {"durations": durations, "missing_tracks": missing_tracks}
    except Exception as e:
        print(e)
        db.close_connection(connection)
        return None