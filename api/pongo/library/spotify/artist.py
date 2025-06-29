import spotipy
from spotipy.oauth2 import SpotifyClientCredentials
from library.spotify import api_key_round_robin


def get_artist_metadata(said: str, market: str):
    try:
        # Auth with spotify
        api_key = api_key_round_robin.get_api_key()
        client_credentials_manager = SpotifyClientCredentials(client_id=api_key["client_id"], client_secret=api_key["client_secret"])

        # Do the requests
        sp = spotipy.Spotify(client_credentials_manager=client_credentials_manager)
        albums = sp.artist_albums(said, album_type="album,appears_on,single", limit=50)
        tracks = sp.artist_top_tracks(said, country=market)

        return {"albums": albums["items"], "tracks": tracks["tracks"]} #, "artists": artists["artists"]}
    except Exception as e:
        print(e)
        return None


def get_artist_images(said: str):
    try:
        # Auth
        api_key = api_key_round_robin.get_api_key()
        client_credentials_manager = SpotifyClientCredentials(client_id=api_key["client_id"], client_secret=api_key["client_secret"])

        # Search request
        sp = spotipy.Spotify(client_credentials_manager=client_credentials_manager)
        artist = sp.artist(said)
        
        return {"images": artist["images"]}
    except Exception as e:
        print(e)
        return None