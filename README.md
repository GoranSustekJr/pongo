# Pongo
<img src="https://github.com/user-attachments/assets/1e2f3144-12e1-4686-a65c-b3f1c9e73c8f" width="250" height="250" />

Pongo is a full stack application for free music streaming. Important to notice is that currently there is no tutorial or a simple way to install the app. If someone wants to try it out, fell free to aks by introducing yourself pongo.org@gmail.com


## Built with

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![FastAPI](https://img.shields.io/badge/fastapi-109989?style=for-the-badge&logo=FASTAPI&logoColor=white)
![Python](https://img.shields.io/badge/Python-FFD43B?style=for-the-badge&logo=python&logoColor=blue)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white)
![Nginx](https://img.shields.io/badge/Nginx-009639?style=for-the-badge&logo=nginx&logoColor=white)

## Demo video
- https://youtu.be/PcywrO85vYY, 3.3.2025.  
- https://youtube.com/shorts/tdU5W7BBnJc?feature=share, 28.7.2025. (Updated UI and new feature)

## Features

| Feature                          | Description                                 |
|----------------------------------|---------------------------------------------|
| Live lyrics                      | See synchronized lyrics in real time        |
| Mix mode                         | When single song is played, in the queue will be added 20 songs of similar atmosphere         |
| Show/Hide songs in playlist      | Toggle visibility of tracks in your playlist without having to remove them    |
| Sleep mode                       | Gradually increase/decrease volume for certain period of time to allow you smooth falling asleep and waking up            |
| Online/Offline playlists         | Access downloaded playlists without internet           |
| Performance-saving preferences   | Reduce UI intensity for smoother playback   |
| Search preferences               | Customize how search behaves and what it displays                |
| iOS, MacOS, Android supported    | Works across major platforms                |
| Apple/Google sign in             | Sign in easily and securly with your Apple or Google ID |
| See currently played artist/album| Info at a glance while listening            |
| Dynamic coloring                 | UI adapts to album art colors               |
| Currently played controls        | Swipe up for full controls                  |
| English/Deutsch/Hrvatski         | App available in 3 languages                |
| Pause by tapping on image        | Tap artwork to pause                        |
| Play next/previous on swipe      | Swipe navigation bar to change songs               |
| Account deletion                 | Three-tap account deletion from the app       |
| Liquid glass UI                  | Frosted, fluid visual design                |
| Queue management                 | Reorder or remove songs in the queue        |
| Repeat and shuffle               | Toggle repeat and shuffle modes             |
| Animations                       | Smooth transitions and effects              |



## How Does It Work?

### Server-Side Song Download 💾  

1. An **asynchronous function** is started, and the track/video ID is added to a set of currently downloading items.
2. If a **track ID** is provided, metadata is fetched from the **Spotify API** to determine the corresponding YouTube video ID.
3. A YouTube video URL is constructed:  
   `https://www.youtube.com/watch?v={yt_vid}`  
   and a temporary file path is prepared.
4. Both the URL and the file path are passed to **`yt-dlp`**, which downloads the audio.
5. Upon successful download, the **audio duration** is determined using `ffprobe` (required for iOS and macOS native audio players).
6. A **SHA-512 hash** is computed from the audio to check for duplicates in the database:
   - If the audio already exists, nothing is added, and temporary files are deleted.
   - If it's new, both the duration and audio file are inserted into the database before cleanup.
7. Finally, the track/video ID is removed from the set of currently downloading items.


### Audio Playback Flow 🎵  

1. The user starts by searching for a song.
2. When the desired track is tapped, a WebSocket connection is opened to the server’s `/test` endpoint.
3. The server checks if the track already exists in the database:
   - If it **does**, the server responds with `{"exists": "true"}` and the connection is closed.
   - If it **does not**, the server responds with `{"exists": "false"}` and the client waits while the song is downloaded.
4. Once the song becomes available, the server sends `{"exists": "true"}` to notify the client.
5. The selected track is then prepared locally on the user's device and passed to the native audio player.
6. The native audio player sends a request to the server’s `/play_song` endpoint, which responds with the audio stream.

### Mix Mode 🔀  

1. **Enable Mix Mode** in the app's preferences.
2. When a **single track** (not part of a playlist or album) is played, the standard [Audio Playback Flow](#-audio-playback-flow) is triggered.
3. After the track finishes, a WebSocket request is sent to:  
   `/cfc14e13ca191618a06bd94dd5976fccae585e36b3f651b467947288afb51ea8`
4. The server uses the track ID to fetch metadata from the **Spotify API**.
5. A search query is generated in the format:  
   `"<track name> - <artist 1>, <artist 2>, ..."`
6. This query is sent to YouTube's search endpoint. First valid **video ID** is extracted.
7. The video ID is used to retrieve the corresponding **YouTube Mix playlist ID**.
8. A YouTube URL is constructed:  
   `https://www.youtube.com/watch?v={yt_vid}&list={mix_id}&index=1`
9. This URL is passed to `yt-dlp`, which downloads the **first 20 songs** in the mix.
10. As each song is downloaded, the server sends metadata back to the client, which adds the track to the playback queue under **Mix #N**.
