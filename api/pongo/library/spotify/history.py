import spotipy
from spotipy.oauth2 import SpotifyClientCredentials
from library.spotify import api_key_round_robin
from library.db import db, select

def get_history_tracks(stids: list, market: str):
    try:
        if len(stids) > 0:
            # Initialization of the spotify connection 
            api_key = api_key_round_robin.get_api_key()
            client_credentials_manager = SpotifyClientCredentials(client_id=api_key["client_id"], client_secret=api_key["client_secret"])
            sp = spotipy.Spotify(client_credentials_manager=client_credentials_manager)
        
            # Get the tracks
            tracks = sp.tracks(stids, market=market)
        
            return tracks
        else:
            return None
    except Exception as e:
        print(e)
        return None