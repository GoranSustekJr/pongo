import spotipy, subprocess, os

from unidecode import unidecode
from library.spotify import api_key_round_robin
from spotipy.oauth2 import SpotifyClientCredentials
from library.db import db, insert
from typing import Set
from datetime import datetime
from dotenv import load_dotenv

project_home = os.getenv('PONGO_PROJECT_HOME_FOLDER')

def add_track_to_db(stid: str, processing_videos: Set[str], connection, cursor, yt_vid: str = None):
    try:
        now = datetime.now()
        # If getting it with only youtube video id
        if yt_vid != None:
            print("shit")
            # Download the video
            video_url = f"https://www.youtube.com/watch?v={yt_vid}"
            outtmplPath = f"{project_home}/pongo/library/track/temp/{now}-{yt_vid}.m4a"
            
            command = ["yt-dlp", "-f", "bestaudio", "-o", f"{project_home}/pongo/library/track/temp/{now}-{yt_vid}.m4a", video_url] 
            try:
                subprocess.run(command, check=True)
            except subprocess.CalledProcessError as e:
                print(f"Command failed with error: {e}")
            except Exception as e:
                print(f"An unexpected error occurred: {e}")
            
            # Get the length
            length = get_audio_length(outtmplPath)
            new_ytvid = insert.insert_stid(yt_vid, yt_vid.strip(), connection, cursor)
            
            # Insert to db
            if new_ytvid:
                insert.insert_track_audio(outtmplPath, yt_vid, connection, cursor)
                insert.insert_track_duration(length, yt_vid, connection, cursor)
            
            # Clean up
            processing_videos.remove(yt_vid)
            db.close_connection(connection)
            os.remove(outtmplPath)
        else:
            print(1)
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
            qry = unidecode(track["name"] + ' - ' + ', '.join(artists))
            print(2, qry)
            # Get the tracks video id / vid
            cmd = [f"{project_home}/pongo/yt.sh", "-s", f"'{qry}'"]
            video_ids = subprocess.run(cmd, capture_output=True, text=True).stdout.split('\n')

            video_id = video_ids[0]
            print(3, video_id)
            print("SHJFHS")
            
            cgd = ["yt-dlp", "--list-formats", f"https://www.youtube.com/watch?v={video_id}"]
            gy = subprocess.run(cmd, capture_output=True, text=True).stdout
            print(gy)
        
            # Download the video
            for i in range(1):
                video_id = video_ids[i]
                video_url = f"https://www.youtube.com/watch?v={video_id}"
                outtmplPath = f"{project_home}/pongo/library/track/temp/{now}-{video_id}.m4a"
                cmmd = ["yt-dlp", "-F", video_url]
                subprocess.run(cmmd, check=True)
                command = ["yt-dlp", "-f", "bestaudio[protocol!=m3u8]", "-o", f"{project_home}/pongo/library/track/temp/{now}-{video_id}.m4a", video_url] ### For some reason ba[ext=m4a] does not work
                print(4) # "-f", "ba[ext=m4a]",
                try:
                    subprocess.run(command, check=True)
                    break
                except subprocess.CalledProcessError as e:
                    print(f"Command failed with error: {e}")
                except Exception as e:
                    print(f"An unexpected error occurred: {e}")
                    
            print(5)
            # Get the length
            length = get_audio_length(outtmplPath)
            new_ytvid = insert.insert_stid(stid, video_id.strip(), connection, cursor)
            
            # Insert to db
            if new_ytvid:
                insert.insert_track_audio(outtmplPath, stid, connection, cursor)
                insert.insert_track_duration(length, stid, connection, cursor)
            
            # Clean up
            processing_videos.remove(stid)
            db.close_connection(connection)
            os.remove(outtmplPath)
    except Exception as e:
        print("Errorrrrr: ", e)
        db.close_connection(connection)
        os.remove(outtmplPath)


def get_audio_length(file_path):
    # ffprobe command to get duration
    command = [
        "ffprobe",
        "-v", "error",
        "-show_entries", "format=duration",
        "-of", "default=noprint_wrappers=1:nokey=1",
        file_path
    ]
    result = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    duration = float(result.stdout.strip())
    return duration
