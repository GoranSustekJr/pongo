import spotipy
from spotipy.oauth2 import SpotifyClientCredentials
from library.spotify import api_key_round_robin
from library.db import db, select


##### Deprecated  ########
def suggest(market: str, stids: list, personal_rec: bool, pongo_rec: bool): # DEPRECATED!
    try:
        # Initialize vars
        tracks_data = None
        artists_data = None
        playlists_data = None
        new_releases_data = None
        
        eu_tracks_data = None
        eu_artists_data = None

        if pongo_rec:
            # Pongo recommendations
            # Auth with spotify
            api_key = api_key_round_robin.get_api_key()
            client_credentials_manager = SpotifyClientCredentials(client_id=api_key["client_id"], client_secret=api_key["client_secret"])
            
            # Send the request
            sp = spotipy.Spotify(client_credentials_manager=client_credentials_manager)    
            seed_tracks = select.select_random_tracks(5, connection, cur)
            tracks_data = sp.recommendations(limit=50, market=market, seed_tracks=','.join(seed_track[0] for seed_track in seed_tracks))
            
            # Connect to db
            connection, cur = db.connect()

            # Extract the artists
            artists = set()
            for track in tracks_data["tracks"]:
                if track["artists"]:
                    for artist in track["artists"]:
                        artists.add(artist["id"])

            # Get the rest of data
            artists_data = sp.artists(list(artists)[:25])
            playlists_data = sp.featured_playlists(country=market, limit=50)
            new_releases_data = sp.new_releases(country=market, limit=50)

        if personal_rec and len(stids) != 0:
            # End-user recommendetions
            # Spotify auth
            api_key = api_key_round_robin.get_api_key()
            client_credentials_manager = SpotifyClientCredentials(client_id=api_key["client_id"], client_secret=api_key["client_secret"])

            # Send the request
            sp = spotipy.Spotify(client_credentials_manager=client_credentials_manager)
            eu_tracks_data = sp.recommendations(limit=50, market=market, seed_tracks=stids)

            # Extract artists
            eu_artists = set()
            for track in eu_tracks_data["tracks"]:
                if track["artists"]:
                    for artist in track["artists"]:
                        eu_artists.add(artist["id"])

            # Request to spotify to get artists
            eu_artists_data = sp.artists(list(eu_artists)[:30])

        # If user does not want to see some data, don't return it
        if personal_rec == False and len(stids) == 0:
            eu_tracks_data = {"tracks": []}
            eu_artists_data = {"artists": []}
        if pongo_rec == False:
            tracks_data = {"tracks": []}
            artists_data = {"artists": []}
            new_releases_data = {"albums": {"items": []}}
            playlists_data = {"playlists": {"items": []}}
        
        # Tidy up and return
        db.close_connection(connection)
        return {"tracks": tracks_data, "artists": artists_data, "playlists": playlists_data, "albums": new_releases_data, "eu_tracks": eu_tracks_data, "eu_artists": eu_artists_data}
    except Exception as e:
        print(e)
        db.close_connection(connection)
        return None