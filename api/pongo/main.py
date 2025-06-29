import uvicorn, json, asyncio, databases, logging, requests, base64, subprocess, os

from fastapi import FastAPI, Request, Response, WebSocket, HTTPException, Header, WebSocketDisconnect
from fastapi.responses import StreamingResponse, FileResponse, JSONResponse
from typing import Set
from concurrent.futures import ThreadPoolExecutor
from starlette.status import HTTP_206_PARTIAL_CONTENT
from fastapi.middleware.cors import CORSMiddleware
from dateutil.relativedelta import relativedelta

from library.db import db, select, delete, insert
from library.auth import sign_in, jwt, apple_auth
from library.spotify import search, playlist, album, artist, suggestion, serialized, recommendation, history, track
from library.track import add_track
from dotenv import load_dotenv


project_home = os.getenv('PONGO_PROJECT_HOME_FOLDER')

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Adjust this for your production environment
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# logger.debug
# Set up the logger
#logger = logging.getLogger("uvicorn.error")
#logger.setLevel(logging.DEBUG)  # You can adjust the level as needed

# Create a handler for logging to the console
#console_handler = logging.StreamHandler()
#console_handler.setLevel(logging.DEBUG)

# Create a formatter for the log message
#formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
#console_handler.setFormatter(formatter)

# Add the handler to the logger
#logger.addHandler(console_handler)


# Processing tracks
processing_videos: Set[str] = set()


# Add track to db executor
executor = ThreadPoolExecutor()



# Download track
@app.post('/download_track/{stid}')
async def download_track(stid: str, request: Request):
    try:
        print(1)
        data = await request.json()
        uid = jwt.validate_token(data["at+JWT"])
        print(2)
        if uid != None and uid != "Disabled":
            connection, cur = db.connect()
            
            # Get plan
            premium = select.is_premium(uid, connection, cur)
            
            if premium:
                # Get and retun the data
                song_bytea = bytes(select.select_audio(stid, connection, cur))

                db.close_connection(connection)
            
                return Response(content=song_bytea.decode('latin1'), media_type='audio/mp4')
            else:
                # Return 403
                raise HTTPException(status_code=403, detail="Not premium")   
        elif uid == "Disabled":
            raise HTTPException(status_code=401, detail="Disabled")             
        else:
            raise HTTPException(status_code=401, detail="User does not exist")
    except HTTPException as http_exc:
        db.close_connection(connection)
        raise http_exc
    except Exception as e:
        print(e)
        db.close_connection(connection)
        raise HTTPException(status_code=500, details="Internal Server Error")
    
    

# Send track
def song_data_stream(song_bytea, start: int, end: int):
    chunk_size = 1024 * 1024  # 1MB
    while start < end:
        yield song_bytea[start:min(start + chunk_size, end)]
        start += chunk_size

# Android  
@app.get('/play_song/android/{stid}')
async def play_song(stid: str, request: Request, range: str = Header(None)):
    try:
        headers = request.headers
        
        if True:
            connection, cur = db.connect()
            song_bytea = bytes(select.select_audio(stid, connection, cur))
        
            return Response(content=song_bytea, media_type="audio/mpeg")
        else:
            raise HTTPException(status_code=401, detail="User does not exist")
    except HTTPException as http_exc:
        raise http_exc
    except Exception as e:
        print(e)
        raise HTTPException(status_code=500, detail="Internal server error")
    
    
    

# Apple
@app.get('/play_song/{stid}')
async def play_song(stid: str, request: Request, range: str = Header(None)):
    try:
        headers = request.headers
        if True:
            connection, cur = db.connect()
            song_bytea = bytes(select.select_audio(stid, connection, cur))

            db.close_connection(connection)

            if song_bytea is None:
                raise HTTPException(status_code=404, detail="Audio file not found")

            total_length = len(song_bytea)
            start = 0
            end = total_length

            if range:
                # Parse the range header
                range_header = range.strip().split("=")[-1]
                range_start, range_end = range_header.split("-")
                start = int(range_start) if range_start else 0
                end = int(range_end) if range_end else total_length - 1

                # Ensure range values are valid
                if start >= total_length or start > end:
                    raise HTTPException(status_code=416, detail="Requested Range Not Satisfiable")

                response_status = 206  # Partial content
            else:
                response_status = 200  # OK

            # Stream the specific byte range
            response = StreamingResponse(
                song_data_stream(song_bytea, start, end + 1),  # Adjust for the end byte
                media_type='audio/aac',
                status_code=response_status
            )

            # Set headers for partial content support
            response.headers['Content-Range'] = f"bytes {start}-{end}/{total_length}"
            response.headers['Accept-Ranges'] = 'bytes'
            response.headers['Content-Length'] = str(end - start + 1)  # Adjust for the correct length

            return response
        else:
            raise HTTPException(status_code=401, detail="User does not exist")
    except HTTPException as http_exc:
        raise http_exc
    except Exception as e:
        print(e)
        raise HTTPException(status_code=500, detail="Internal server error")
        
        

@app.get('/play_song_caching/{stid}')
async def play_song_caching(stid: str, request: Request, range: str = Header(None)):
    try:
        headers = request.headers
        #uid = jwt.validate_token(headers["Authorization"])
        #print("UID; ", uid)
        #if uid != None:
        if True:
            connection, cur = db.connect()
            song_bytea = bytes(select.select_audio(stid, connection, cur))
            
            db.close_connection(connection)

            if song_bytea is None:
                raise HTTPException(status_code=404, detail="Audio file not found")

            total_length = len(song_bytea)
            start = 0
            end = total_length

            if range:
                # Parse the range header
                range_header = range.strip().split("=")[-1]
                range_start, range_end = range_header.split("-")
                start = int(range_start) if range_start else 0
                end = int(range_end) if range_end else total_length - 1

                # Ensure range values are valid
                if start >= total_length or start > end:
                    raise HTTPException(status_code=416, detail="Requested Range Not Satisfiable")

                response_status = 206  # Partial content
            else:
                response_status = 200  # OK

            # Stream the specific byte range
            response = StreamingResponse(
                song_data_stream(song_bytea, start, end),  # Adjust for the end byte
                media_type='audio/aac',
                status_code=response_status
            )

            # Set headers for partial content support
            response.headers['Content-Range'] = f"bytes {start}-{end}/{total_length}"
            response.headers['Accept-Ranges'] = 'bytes'
            response.headers['Content-Length'] = str(end - start)  # Adjust for the correct length

            return response
        else:
            raise HTTPException(status_code=401, detail="User does not exist")
    except HTTPException as http_exc:
        raise http_exc
    except Exception as e:
        print(e)
        raise HTTPException(status_code=500, detail="Internal server error")
        

# Sign in a user
@app.post('/bed1684d6d16802154bba513a5f0980dd3dc4b612aeb6a05433c28f55936ca7d') 
async def signin(request: Request):
    try:
        # Sign the user in
        data = await request.json()
        connection, cur = db.connect()
        refresh_token, access_token = sign_in.verify_user(data["id_token"], data["platform"], data["device_id"], data["apple"], connection, cur)
        db.close_connection(connection)
        return {"rt+JWT": refresh_token, "at+JWT": access_token}
    except Exception as e:
        print(e)
        db.close_connection(connection)
        raise HTTPException(status_code=500, detail="Internal Server Error")


# Renew token
@app.post('/renew_at')
async def renew_at(request: Request):
    try:
        # Get the data and renew
        data = await request.json()
        
        refresh_token = data["jwt"]
        access_token = sign_in.renew_access_token(refresh_token)

        if access_token == None:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Refresh token expired")
        else:
            return {"at": access_token}
    except HTTPException as http_exc:
        raise http_exc
    except Exception as e:
        print("error", e)
        raise HTTPException(status_code=500, detail="Internal server error")


# Get user data
@app.post('/user_data')
async def user_data(request: Request):
    try:
        # Get the data and verify user
        data = await request.json()
        uid = jwt.validate_token(data["at+JWT"], bypass=True)
        print("UID; ", uid)
        if uid != None:
            connection, cur = db.connect()
            user_data = select.select_user_data(uid, connection, cur)
            db.close_connection(connection)
            if user_data != None:
                if user_data["email"] == None and user_data["name"] == None and user_data["picture"] == None:
                    raise HTTPException(status_code=401, detail="User does not exist")
                else:
                    return Response(
                            json.dumps(user_data, ensure_ascii=False).encode('utf-8'),
                            media_type="application/json;charset=utf-8"
                            )
            else:
                raise HTTPException(status_code=401, detail="User does not exist")
        elif uid == "Disabled":
            raise HTTPException(status_code=401, detail="Disabled")      
        else:
            raise HTTPException(status_code=401, detail="Access token expired")
    except HTTPException as http_exc:
        db.close_connection(connection)
        raise http_exc
    except Exception as e:
        print("OH no: ", e)
        raise HTTPException(status_code=500, detail="Internal server error")


@app.post('/search_spotify')
async def search_spotify(request: Request):
    try:
        # Get the data and verify user
        data = await request.json()
        uid = jwt.validate_token(data["at+JWT"])
        if uid != None and uid != "Disabled":
            tracks = search.search(data["query"], data["market"])
            return Response(
                    json.dumps(tracks, ensure_ascii=False).encode('utf-8'),
                    media_type="application/json;charset=utf-8"
                    )
        elif uid == "Disabled":
            raise HTTPException(status_code=401, detail="Disabled")      
        else:
            raise HTTPException(status_code=401, detail="User does not exist")
    except HTTPException as http_exc:
        raise http_exc
    except Exception as e:
        print(e)
        raise HTTPException(status_code=500, detail="Internal Server Error")


@app.post('/get_playlist')
async def get_spotify_playlist(request: Request):
    try:
        # Get the data and verify user
        data = await request.json()
        uid = jwt.validate_token(data["at+JWT"])
        if uid != None and uid != "Disabled":
            playlist_data = playlist.get_playlist(data["spid"])
            return Response(
                    json.dumps(playlist_data, ensure_ascii=False).encode('utf-8'),
                    media_type="application/json;charset=utf-8"
                    )
        elif uid == "Disabled":
            raise HTTPException(status_code=401, detail="Disabled")      
        else:
            raise HTTPException(status_code=401, detail="User does not exist")
    #    return tracks
    except HTTPException as http_exc:
        raise http_exc
    except Exception as e:
        print(e)
        raise HTTPException(status_code=500, detail="Internal Server Error")


@app.post('/get_playlist_shuffle')
async def get_spotify_playlist_shuffle(request: Request):
    try:
        # Get the data and verify user
        data = await request.json()
        uid = jwt.validate_token(data["at+JWT"])
        if uid != None and uid != "Disabled":
            playlist_data = playlist.get_playlist_shuffle(data["spid"])
            return Response(
                    json.dumps(playlist_data, ensure_ascii=False).encode('utf-8'),
                    media_type="application/json;charset=utf-8"
                    )
        elif uid == "Disabled":
            raise HTTPException(status_code=401, detail="Disabled")      
        else:
            raise HTTPException(status_code=401, detail="User does not exist")
    #    return tracks
    except HTTPException as http_exc:
        raise http_exc
    except Exception as e:
        print(e)
        raise HTTPException(status_code=500, detail="Internal Server Error")


@app.post('/get_album') # Album tracks
async def get_spotify_album(request: Request):
    try:
        # Get the data and verify user
        data = await request.json()
        uid = jwt.validate_token(data["at+JWT"])
        if uid != None and uid != "Disabled":
            album_data = album.get_album(data["salid"])
            return Response(
                    json.dumps(album_data, ensure_ascii=False).encode('utf-8'),
                    media_type="application/json;charset=utf-8"
                    )
        elif uid == "Disabled":
            raise HTTPException(status_code=401, detail="Disabled")      
        else:
            raise HTTPException(status_code=401, detail="User does not exist")
    except HTTPException as http_exc:
        raise http_exc
    except Exception as e:
        print(e)
        raise HTTPException(status_code=500, detail="Internal Server Error")
    
    
@app.post('/get_online_playlist_tracks') # Online playlist tracks
async def get_online_playlist_tracks(request: Request):
    try:
        # Get the data and verify user
        data = await request.json()
        uid = jwt.validate_token(data["at+JWT"])
        if uid != None and uid != "Disabled":
            online_playlist_data = playlist.get_online_playlist_tracks(data["stids"])
            return Response(
                    json.dumps(online_playlist_data, ensure_ascii=False).encode('utf-8'),
                    media_type="application/json;charset=utf-8"
                    )
        elif uid == "Disabled":
            raise HTTPException(status_code=401, detail="Disabled")      
        else:
            raise HTTPException(status_code=401, detail="User does not exist")
    except HTTPException as http_exc:
        raise http_exc
    except Exception as e:
        print(e)
        raise HTTPException(status_code=500, detail="Internal Server Error")
    

@app.post('/get_serialized_tracks') # Album tracks
async def get_serialized_tracks(request: Request):
    try:
        # Get the data and verify user
        data = await request.json()
        uid = jwt.validate_token(data["at+JWT"])
        if uid != None and uid != "Disabled":
            album_data = serialized.get_serialized_tracks(data["stids"])
            return Response(
                    json.dumps(album_data, ensure_ascii=False).encode('utf-8'),
                    media_type="application/json;charset=utf-8"
                    )
        elif uid == "Disabled":
            raise HTTPException(status_code=401, detail="Disabled")      
        else:
            raise HTTPException(status_code=401, detail="User does not exist")
    except HTTPException as http_exc:
        raise http_exc
    except Exception as e:
        print(e)
        raise HTTPException(status_code=500, detail="Internal Server Error")


@app.post('/get_visualizer_data')
async def get_visualizer_data(request: Request):
    try:
        return FileResponse(
            path=f"{project_home}/pongo/library/track/temp/output.json",
            filename="output.json",  # Name of the file for the client
            media_type="application/json"  # Adjust the media type if necessary
        )
    except HTTPException as http_exc:
        raise http_exc
    except Exception as e:
        print(e)
        raise HTTPException(status_code=500, detail="Internal Server Error")

@app.post('/get_serialized_shuffle')
async def get_spotify_album_shuffle(request: Request):
    try:
        # Get the data and verify user
        data = await request.json()
        uid = jwt.validate_token(data["at+JWT"])
        if uid != None and uid != "Disabled":
            album_data = serialized.get_serialized_shuffle(data["stids"])
            return Response(
                    json.dumps(album_data, ensure_ascii=False).encode('utf-8'),
                    media_type="application/json;charset=utf-8"
                    )
        elif uid == "Disabled":
            raise HTTPException(status_code=401, detail="Disabled")      
        else:
            raise HTTPException(status_code=401, detail="User does not exist")
    #    return tracks
    except HTTPException as http_exc:
        raise http_exc
    except Exception as e:
        print(e)
        raise HTTPException(status_code=500, detail="Internal Server Error")
    

@app.post('/get_album_data')
async def get_spotify_album(request: Request):
    try:
        # Get the data and verify user
        data = await request.json()
        uid = jwt.validate_token(data["at+JWT"])
        if uid != None and uid != "Disabled":
            album_data = album.get_album_data(data["salid"])
            return Response(
                    json.dumps(album_data, ensure_ascii=False).encode('utf-8'),
                    media_type="application/json;charset=utf-8"
                    )
        elif uid == "Disabled":
            raise HTTPException(status_code=401, detail="Disabled")      
        else:
            raise HTTPException(status_code=401, detail="User does not exist")
    except HTTPException as http_exc:
        raise http_exc
    except Exception as e:
        print(e)
        raise HTTPException(status_code=500, detail="Internal Server Error")


# Get album shuffle
@app.post('/get_album_shuffle')
async def get_spotify_album_shuffle(request: Request):
    try:
        # Get the data and verify user
        data = await request.json()
        uid = jwt.validate_token(data["at+JWT"])
        if uid != None and uid != "Disabled":
            album_data = album.get_album_shuffle(data["said"])
            return Response(
                    json.dumps(album_data, ensure_ascii=False).encode('utf-8'),
                    media_type="application/json;charset=utf-8"
                    )
        elif uid == "Disabled":
            raise HTTPException(status_code=401, detail="Disabled")      
        else:
            raise HTTPException(status_code=401, detail="User does not exist")
    #    return tracks
    except HTTPException as http_exc:
        raise http_exc
    except Exception as e:
        print(e)
        raise HTTPException(status_code=500, detail="Internal Server Error")


# Get suggestions -> Deprecated
@app.post('/get_suggestions')
async def get_suggestions(request: Request):
    try:
        # Get the data and verify user
        data = await request.json()
        uid = jwt.validate_token(data["at+JWT"])
        if uid != None and uid != "Disabled":
            suggestions = suggestion.suggest(data["market"], data["stids"], data["personal_rec"], data["pongo_rec"])
            return Response(
                    json.dumps(suggestions, ensure_ascii=False).encode('utf-8'),
                    media_type="application/json;charset=utf-8"
                    )
        else:
            raise HTTPException(status_code=401, detail="User does not exist")
    #    return tracks
    except HTTPException as http_exc:
        raise http_exc
    except Exception as e:
        print(e)
        raise HTTPException(status_code=500, detail="Internal Server Error") 
    
    
# Shazam a song
@app.post('/6a2f5d49dda86647d136751f354f0bbfbd76a414a283b18f211b34f911029e0e')
async def shazam_a_song(request: Request):
    try:
        # Get the data and verify user
        data = await request.json()
        uid = jwt.validate_token(data["at+JWT"])
        if uid != None and uid != "Disabled":
            found_track = await track.shazam(data["stid"])
            return Response(
                    json.dumps(found_track, ensure_ascii=False).encode('utf-8'),
                    media_type="application/json;charset=utf-8"
                    )
        elif uid == "Disabled":
            raise HTTPException(status_code=401, detail="Disabled")      
        else:
            raise HTTPException(status_code=401, detail="User does not exist")
    #    return tracks
    except HTTPException as http_exc:
        raise http_exc
    except Exception as e:
        print(e)
        raise HTTPException(status_code=500, detail="Internal Server Error") 
    




@app.post('/get_track_duration')
async def get_track_duration(request: Request):
    try:
        # Get the data and verify user
        data = await request.json()
        uid = jwt.validate_token(data["at+JWT"])
        if uid != None and uid != "Disabled":            
            duration = select.select_track_duration(data["stid"], connection, cur)
            db.close_connection(connection)
            return Response(
                    json.dumps({"duration": duration}, ensure_ascii=False).encode('utf-8'),
                    media_type="application/json;charset=utf-8"
                    )
        elif uid == "Disabled":
            raise HTTPException(status_code=401, detail="Disabled")      
        else:
            raise HTTPException(status_code=401, detail="User does not exist")
    #    return tracks
    except HTTPException as http_exc:
        raise http_exc
    except Exception as e:
        print(e)
        raise HTTPException(status_code=500, detail="Internal Server Error")


@app.post('/get_tracks_duration')
async def get_tracks_duration(request: Request):
    try:
        # Get the data and verify user
        data = await request.json()

        uid = jwt.validate_token(data["at+JWT"])
        if uid != None and uid != "Disabled":
            connection, cur = db.connect()
            duration = select.select_track_duration(data["stid"], connection, cur)
            db.close_connection(connection)

            return Response(
                    json.dumps({"duration": duration}, ensure_ascii=False).encode('utf-8'),
                    media_type="application/json;charset=utf-8"
                    )
        elif uid == "Disabled":
            raise HTTPException(status_code=401, detail="Disabled")      
        else:
            raise HTTPException(status_code=401, detail="User does not exist")
    except HTTPException as http_exc:
        raise http_exc
    except Exception as e:
        print(e)
        raise HTTPException(status_code=500, detail="Internal Server Error")
    
    
# Mix
@app.websocket('/cfc14e13ca191618a06bd94dd5976fccae585e36b3f651b467947288afb51ea8')
async def get_mix(websocket: WebSocket):
    await websocket.accept()
    
    try:
        # Get the data and verify user
        data = await websocket.receive_text()

        data = json.loads(data)
        uid = jwt.validate_token(data["at+JWT"])
        if uid != None and uid != "Disabled":
            # Get the Spotify track qry
            qry = track.track_query(data["stid"])


            if (qry != None):
                # Get the YouTube mix
                cmd = [f"{project_home}/pongo/yt-playlist.sh", "-S", f"'{qry}'"]
                mix_id = subprocess.run(cmd, capture_output=True, text=True).stdout.split('\n')[0]
                
                print(qry)
                
                print("MIX ID: ", mix_id)

                # If not null get the video_ids
                if mix_id != "" and mix_id != None:
                    # Get the YouTube video id of the song just played
                    connection, cur = db.connect()
                    yt_vid = select.select_ytvid(data["stid"], connection, cur)
                    db.close_connection(connection)
                    
                    if yt_vid != None:
                        # Get the video_ids
                        yt_qry = f"https://www.youtube.com/watch?v={yt_vid}&list={mix_id}&index=1"
                        
                        command = ["yt-dlp", "-j", "--flat-playlist", "--playlist-end", "21", yt_qry]
                        result = subprocess.run(command, capture_output=True, text=True)
                        
                        # Extract the ids out of the returned data
                        yt_vids = [json.loads(line)["id"] for line in result.stdout.strip().split("\n")][1:]
                        
                        print([json.loads(line)["id"] for line in result.stdout.strip().split("\n")])
                        
                        if len(yt_vids) != 0:
                            # If the song exists return it with duration, when not download it for each video id
                            for yt_vid in yt_vids:
                                # Get if exists
                                connection, cur = db.connect()
                                stid = select.check_if_ytvid_exists(yt_vid, connection, cur)
                                db.close_connection(connection)
                                

                                if stid != None:
                                    # Get the duration --> iOS
                                    connection, cur = db.connect()
                                    duration = select.select_track_duration(stid, connection, cur)
                                    db.close_connection(connection)

                                    # Return data
                                    await websocket.send_json({"duration": duration, "ytvid": stid})
                                else:
                                    # Add and download it
                                    processing_videos.add(yt_vid)

                                    await add_async_to_db(yt_vid, yt_vid = yt_vid)

                                    # Get the duration
                                    duration = select.select_track_duration(yt_vid, connection, cur)

                                    # Return the data
                                    await websocket.send_json({"duration": duration, "ytvid": yt_vid})
            # Finally/Errorcause close the connection 
            await websocket.close() 
        elif uid == "Disabled":
            raise HTTPException(status_code=401, detail="Disabled")
        else:
            raise HTTPException(status_code=401, detail="User does not exist")
        await websocket.close()
    except HTTPException as http_exc:
        raise http_exc
    except Exception as e:
        print(e)
        raise HTTPException(status_code=500, detail="Internal Server Error")




@app.websocket('/concenating_stids') # Concenating stids like playlist or album
async def concenating_stids(websocket: WebSocket):
    await websocket.accept()
    try:
        # Get the data and verify user
        data = await websocket.receive_text()
        # AAA
        data = json.loads(data)
        uid = jwt.validate_token(data["at+JWT"])
        if uid != None and uid != "Disabled":
            connection, cur = db.connect() # Init the db connection
            for i in range(data["stids"]): 
                message = await websocket.receive_text()
                message = json.loads(message)
                stid = message["stid"]
                duration = select.select_track_duration(stid, connection, cur)
                if duration:
                    await websocket.send_json({"duration": duration})
                else:

                    processing_videos.add(stid)

                    await add_async_to_db(stid)

                    duration = select.select_track_duration(stid, connection, cur)

                    await websocket.send_json({"duration": duration})

        elif uid == "Disabled":
            await websocket.send_json({"Status": "Disabled"})   
        else:
            await websocket.send_json({"Status": "Unauthorized"})
        await websocket.close()
    except HTTPException as http_exc:
        db.close_connection(connection)
        raise http_exc
    except WebSocketDisconnect:
        print("Client dissconected")
        db.close_connection(connection)  
                

@app.websocket('/test') # Check if song exists via websocket
async def check_song_existance_websocket_testt(websocket: WebSocket):
    await websocket.accept()
    try:
        # Get the data and verify user
        data = await websocket.receive_text()

        data = json.loads(data)
        uid = jwt.validate_token(data["at+JWT"])
        if uid != None and uid != "Disabled":
            connection, cur = db.connect()
            stid = data["stid"]
            ytvid = select.select_ytvid(stid, connection, cur)

            if ytvid:
                await websocket.send_json({"exists": "true"})

                duration = select.select_track_duration(stid, connection, cur)
                db.close_connection(connection)

                await websocket.send_text(json.dumps({"exists": "true", "duration": duration}))

            else:

                if stid not in processing_videos:

                    await websocket.send_json({"exists": "false"})
                    processing_videos.add(stid)
                    await add_async_to_db(stid)

                    duration = select.select_track_duration(stid, connection, cur)
                    await websocket.send_text(json.dumps({"exists": "true", "duration": duration}))
                    db.close_connection(connection)
                else:
                    db.close_connection(connection)
        elif uid == "Disabled":
            await websocket.send_json({"Status": "Disabled"})
        else:
            await websocket.send_json({"exists": "expired"})
        await websocket.close()
    except HTTPException as http_exc:
        db.close_connection(connection)
        raise http_exc
    except WebSocketDisconnect:
        print("Client dissconected")
        db.close_connection(connection)


async def add_async_to_db(stid: str, yt_vid: str = None):
    try:
        connection, cur = db.connect()
        connection.autocommit = False
        print("Adding async to db")
        loop = asyncio.get_event_loop()
        await loop.run_in_executor(executor, add_track.add_track_to_db, stid, processing_videos, connection, cur, yt_vid)
    except Exception as e:
        print("NIGGER; ", e)
        

# Download a playlist
@app.post('/download_a_playlist')
async def download_a_playlist(request: Request):
    try:
        # Get the data and verify user
        data = await request.json()
        uid = jwt.validate_token(data["at+JWT"])
        if uid != None and uid != "Disabled":
            connection, cur = db.connect()
            
            premium = select.is_premium(uid, connection, cur)
            
            if premium:
                stids = data["stids"]
            
                # Get the existing stids
                
                existings_stids = select.select_existing_stids(', '.join(f"'{stid}'" for stid in stids), connection, cur)
                db.close_connection(connection)

                # Download the missing tracks
                to_download = [stid for stid in stids if (stid, ) not in existings_stids]

                for stid in to_download:
                    await add_async_to_db(stid)
            
                # Return it
                connection, cur = db.connect()
                tracks = select.select_audio_and_duration(stids, connection, cur)
                db.close_connection(connection)
                        
                return Response(
                        json.dumps(tracks, ensure_ascii=False).encode('utf-8'),
                        media_type="application/json;charset=utf-8"
                        )
            else:
                # Return 403
                raise HTTPException(status_code=403, detail="Not premium")
        elif uid == "Disabled":
            raise HTTPException(status_code=401, detail="Disabled")      
        else:
            raise HTTPException(status_code=401, detail="User does not exist")
    #    return tracks
    except HTTPException as http_exc:
        raise http_exc
    except Exception as e:
        print(e)
        raise HTTPException(status_code=500, detail="Internal Server Error") 



@app.post('/get_artist_metadata')
async def search_spotify(request: Request):
    try:
        # Get the data and verify user
        data = await request.json()

        uid = jwt.validate_token(data["at+JWT"])
        if uid != None and uid != "Disabled":

            artist_data = artist.get_artist_metadata(data["said"], data["market"])

            return Response(
                    json.dumps(artist_data, ensure_ascii=False).encode('utf-8'),
                    media_type="application/json;charset=utf-8"
                    )
        elif uid == "Disabled":
            raise HTTPException(status_code=401, detail="Disabled")      
        else:
            raise HTTPException(status_code=401, detail="User does not exist")
    #    return tracks
    except HTTPException as http_exc:
        raise http_exc
    except Exception as e:
        print(e)
        raise HTTPException(status_code=500, detail="Internal Server Error")


# Get artist images
@app.post('/caf5cc332d474f35ff74e94af44f2a7801b620b2ce0196560e038b511d14986e')
async def get_artist_images(request: Request):
    try:
        # Get the data and verify user
        data = await request.json()

        uid = jwt.validate_token(data["at+JWT"])
        if uid != None and uid != "Disabled":

            artist_data = artist.get_artist_images(data["said"])

            return Response(
                    json.dumps(artist_data, ensure_ascii=False).encode('utf-8'),
                    media_type="application/json;charset=utf-8"
                    )
        elif uid == "Disabled":
            raise HTTPException(status_code=401, detail="Disabled")      
        else:
            raise HTTPException(status_code=401, detail="User does not exist")
    except HTTPException as http_exc:
        raise http_exc
    except Exception as e:
        print(e)
        raise HTTPException(status_code=500, detail="Internal Server Error")



# Get if premium
@app.post('/get_if_premium')
async def get_if_premium(request: Request):
    try:
        # Get the data and verify user
        data = await request.json()

        uid = jwt.validate_token(data["at+JWT"])
        if uid != None and uid != "Disabled":
            connection, cur = db.connect()
            print(uid)
            premium, expires = select.is_premium(uid, connection, cur)
            print(premium, expires)
            db.close_connection(connection)
            return Response(
                json.dumps({"premium": premium, "expires": expires.isoformat()}, ensure_ascii=False).encode('utf-8'),
                media_type="application/json;charset=utf-8"
            )
        elif uid == "Disabled":
            raise HTTPException(status_code=401, detail="Disabled")      
        else:
            raise HTTPException(status_code=401, detail="User does not exist")
    except HTTPException as http_exc:
        raise http_exc
    except Exception as e:
        print(e)
        raise HTTPException(status_code=500, detail="Internal Server Error")
            
            
# Buy premium
@app.post('/buy_premium')
async def buy_premium(request: Request):
    try:
        # Get the data and verify user
        data = await request.json()
        
        uid = jwt.validate_token(data["at+JWT"])
        if uid != None and uid != "Disabled":
            start_time = apple_auth.decode_receipt(data["serverVerificationData"], data["purchaseId"])
            
            print("ID WORKS", type(start_time))
            connection, cur = db.connect()
            insert.insert_premium(uid, start_time, start_time + relativedelta(months=1, days=2), connection, cur)
            db.close_connection(connection)
            
            return Response(
                json.dumps({"premium": True}, ensure_ascii=False).encode('utf-8'),
                media_type="application/json;charset=utf-8"
            )
        elif uid == "Disabled":
            raise HTTPException(status_code=401, detail="Disabled")      
        else:
            raise HTTPException(status_code=401, detail="User does not exist")
    except HTTPException as http_exc:
        raise http_exc
    except Exception as e:
        print(e)
        raise HTTPException(status_code=500, detail="Internal Server Error")
        
        

# get recommendation
@app.post('/get_recommendations')
async def get_spotify_recommendations(request: Request):
    try:
        # Get the data and verify user
        data = await request.json()

        uid = jwt.validate_token(data["at+JWT"])
        if uid != None and uid != "Disabled":
            categories = recommendation.get_categories(data["market"], data["category_num"], data["locale"])
            history_tracks = history.get_history_tracks(data["history"], data["market"])
            new_releases = recommendation.new_releases(data["market"])
            return Response(
                    json.dumps({"history": history_tracks, "categories": categories, "new_releases": new_releases}, ensure_ascii=False).encode('utf-8'),
                    media_type="application/json;charset=utf-8"
                    )
        elif uid == "Disabled":
            print("DISABLE")
            raise HTTPException(status_code=401, detail="Disabled")      
        else:
            raise HTTPException(status_code=401, detail="User does not exist")
    except HTTPException as http_exc:
        raise http_exc
    except Exception as e:
        print(e)
        raise HTTPException(status_code=500, detail="Internal Server Error")
    
    
    
# Delete users account
@app.post('/delete_account')
async def delete_account(request: Request):
    try:
        # Get the data and verify user
        data = await request.json()

        uid = jwt.validate_token(data["at+JWT"])
        if uid != None and uid != "Disabled":
            # Connect to db and query data
            connection, cur = db.connect()
            delete.delete_account(uid, connection, cur)
            db.close_connection(connection)
            return Response(
                    json.dumps({"deleted": "true"}, ensure_ascii=False).encode('utf-8'),
                    media_type="application/json;charset=utf-8"
                    )
        elif uid == "Disabled":
            raise HTTPException(status_code=401, detail="Disabled")      
        else:
            raise HTTPException(status_code=401, detail="User does not exist")
    #    return tracks
    except HTTPException as http_exc:
        raise http_exc
    except Exception as e:
        print(e)
        raise HTTPException(status_code=500, detail="Internal Server Error")


# Initialize the connection pool when the application starts
@app.on_event("startup")
def startup():
    db.connect()  # This ensures that the pool is initialized

# Clean up the pool connections when the application shuts down
@app.on_event("shutdown")
def shutdown():
    db.close_all_connections()  # Close all pooled connections


if __name__ == '__main__':
    uvicorn.run("main:app", host='127.0.0.1', port=8081)
