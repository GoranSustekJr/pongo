import spotipy, subprocess, os, asyncio, tempfile, io

from unidecode import unidecode
from library.spotify import api_key_round_robin
from spotipy.oauth2 import SpotifyClientCredentials
from library.db import db, insert, select
from typing import Set
from datetime import datetime
from shazamio import Shazam
from pydub import AudioSegment
from dotenv import load_dotenv

project_home = os.getenv('PONGO_PROJECT_HOME_FOLDER')

def track_query(stid: str):
    try:
        # Authenticate with spotify
        api_key = api_key_round_robin.get_api_key()
        client_credentials_manager = SpotifyClientCredentials(client_id=api_key["client_id"], client_secret=api_key["client_secret"])
    
        # Get spotify track
        sp = spotipy.Spotify(client_credentials_manager=client_credentials_manager)
        track = sp.track(stid)
        
        # Extract the artists
        artists = []
        for artist in track["artists"]:
            artists.append(artist["name"])
            
        # Build the query
        qry = unidecode(track["name"] + ' - ' + ', '.join(artists))
        
        return qry
    except Exception as e:
        print(e)
        return None
    
    
async def shazam(stid: str):
    try:
        # Get the audio
        connection, cur = db.connect()
        song_bytea = bytes(select.select_audio(stid, connection, cur))

        db.close_connection(connection)
        
        # Load the song into an AudioSegment
        song_file = io.BytesIO(song_bytea)
        audio = AudioSegment.from_file(song_file, format="m4a")
        # Get the length of the song in milliseconds
        song_length_ms = len(audio)
        
        # Start & end point in the middle of the song
        start_time_ms = len(audio) // 2 - 5000  
        end_time_ms = start_time_ms + 10000  
        
        # Extract 10 s for shazaming
        segment = audio[start_time_ms:start_time_ms + 10000]

        # Save the segment
        now = datetime.now()
        file_path = f"{project_home}/pongo/library/track/temp/{stid}-{now}.ogg"
        segment.export(file_path, format="ogg")
        
        # Shazam
        shazam = Shazam()
        out = await shazam.recognize(file_path)
        
        os.remove(file_path)

        return out
    except Exception as e:
        print(e)
        return None    