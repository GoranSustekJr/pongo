import spotipy
from spotipy.oauth2 import SpotifyClientCredentials
from library.spotify import api_key_round_robin
from library.db import db, select

def get_categories(market: str, category_num: int, locale: str):
    try:
        # Initialization of the spotify connection 
        api_key = api_key_round_robin.get_api_key()
        client_credentials_manager = SpotifyClientCredentials(client_id=api_key["client_id"], client_secret=api_key["client_secret"])
        sp = spotipy.Spotify(client_credentials_manager=client_credentials_manager)
        
        # Get the categories
        categories = sp.categories(country=market, limit=category_num, locale=locale)
        
        return categories
    except Exception as e:
        print(e)
        return None
    

def search_category(category_id: str):
    try:
        # Initialization of the spotify connection 
        api_key = api_key_round_robin.get_api_key()
        client_credentials_manager = SpotifyClientCredentials(client_id=api_key["client_id"], client_secret=api_key["client_secret"])
        sp = spotipy.Spotify(client_credentials_manager=client_credentials_manager)
        
        # Get the categories
        playlists = sp.category_playlists(category_id=category_id, limit=20)
        
        return playlists
    except Exception as e:
        print(e)
        return None
    

def new_releases(market: str):
    try:
        # Initialization of the spotify connection 
        api_key = api_key_round_robin.get_api_key()
        client_credentials_manager = SpotifyClientCredentials(client_id=api_key["client_id"], client_secret=api_key["client_secret"])
        sp = spotipy.Spotify(client_credentials_manager=client_credentials_manager)
        
        # Get new releases
        new_releases = sp.new_releases(country=market, limit=50)
        
        return new_releases
    except Exception as e:
        print(e)
        return None