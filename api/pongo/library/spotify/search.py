import spotipy
from spotipy.oauth2 import SpotifyClientCredentials
from library.spotify import api_key_round_robin

def search(query: str, market: str):
    try:
        # Search the spotify API
        api_key = api_key_round_robin.get_api_key()
        client_credentials_manager = SpotifyClientCredentials(client_id=api_key["client_id"], client_secret=api_key["client_secret"])
        
        sp = spotipy.Spotify(client_credentials_manager=client_credentials_manager)
        search = sp.search(query, limit=50, type='track,album,artist,playlist', market=market)
        return search
    except Exception as e:
        print(e)
        return None