# Pongo
<img src="https://github.com/user-attachments/assets/1e2f3144-12e1-4686-a65c-b3f1c9e73c8f" width="250" height="250" />

Pongo is a full stack application for free music streaming. Important to notice is that currently there is no tutorial or a simple way to install the app. If someone wants to try it out, fell free to aks by introducing yourself pongo.org@gmail.com


## Built with

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![FastAPI](https://img.shields.io/badge/fastapi-109989?style=for-the-badge&logo=FASTAPI&logoColor=white)
![Python](https://img.shields.io/badge/Python-FFD43B?style=for-the-badge&logo=python&logoColor=blue)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Shazam API](https://img.shields.io/badge/Shazam-0088FF?style=for-the-badge&logo=Shazam&logoColor=white)

## Demo video
- https://youtu.be/PcywrO85vYY, 3.3.2025.  
- https://youtu.be/VLkgnx1HZGk, 28.7.2025. (Updated UI and new feature)

## Features

| Feature                          | Description                                                                                                     |
|----------------------------------|-----------------------------------------------------------------------------------------------------------------|
| Live lyrics                      | See synchronized lyrics in real time with the possibility of manual synchronization                             |
| Mix mode                         | When single song is played, in the queue will be added 20 songs of similar atmosphere                           |
| Show/Hide songs in playlist      | Toggle visibility of tracks in your playlist without having to remove them                                      |
| Sleep mode                       | Gradually increase/decrease volume for certain period of time to allow you smooth falling asleep and waking up  |
| Online/Offline playlists         | Access downloaded playlists without internet                                                                    |
| Performance-saving preferences   | Reduce UI intensity for smoother playback                                                                       |
| Search preferences               | Customize how search behaves and what it displays                                                               |
| iOS, MacOS, Android supported    | Works across major platforms                                                                                    |
| Apple/Google sign in             | Sign in easily and securly with your Apple or Google ID                                                         |
| See currently played artist/album| Info at a glance while listening                                                                                |
| Dynamic coloring                 | UI adapts to album art colors                                                                                   |
| Currently played controls        | Swipe up for full controls                                                                                      |
| English/Deutsch/Hrvatski         | App available in 3 languages                                                                                    |
| Pause by tapping on image        | Tap artwork to pause                                                                                            |
| Play next/previous on swipe      | Swipe navigation bar to change songs                                                                            |
| Account deletion                 | Three-tap account deletion from the app                                                                         |
| Liquid glass UI                  | Frosted, fluid visual design                                                                                    |
| Queue management                 | Reorder or remove songs in the queue                                                                            |
| Repeat and shuffle               | Toggle repeat and shuffle modes                                                                                 |
| Animations                       | Smooth transitions and effects                                                                                  |



## Running it

The API and database run in Docker; the iOS app connects to them over your network.

```sh
cp .env.example .env            # set DB_PASSWORD, JWT_SECRET, ALLOWED_EMAILS and the sign in ids
docker compose up -d --build
curl http://localhost:8081/health
```

Then create `frontend/.env` with the server address (use your computer's LAN address, not localhost, for a phone):

```
iosClientID=<Google iOS OAuth client id>
androidClientID=
desktopClientID=
desktopClientSecred=
SERVER_URL=http://192.168.1.10:8081/
SERVER_URL_WSS=ws://192.168.1.10:8081/
```

and run the app with `flutter run --release` from `frontend/`. Accounts start disabled unless their email is in `ALLOWED_EMAILS`; enable others with `scripts/enable_user.sh someone@example.com`.

### Reaching it from the internet

Over the internet the server is only served over HTTPS, through [Caddy](https://caddyserver.com), which gets a Let's Encrypt certificate for your hostname (a no-ip one works). Set `PONGO_DOMAIN` in `.env`, forward ports 80 and 443 on the router to the server (Let's Encrypt checks the hostname over port 80), and start it with the public override, which also limits the API's plain HTTP port to the server itself:

```sh
docker compose -f docker-compose.yml -f docker-compose.public.yml up -d --build
curl https://$PONGO_DOMAIN/health
```

Build the app against `SERVER_URL=https://<hostname>/` and `SERVER_URL_WSS=wss://<hostname>/`. The iOS app allows plain HTTP only to the local network, so the LAN setup above keeps working for development.

Audio lives in the `pongo_audio` volume and the database in `pongo_db`. Back up both.

Tests: `flutter test test/catalog_models_test.dart` in `frontend/`, and `python -m pytest tests` in `api/pongo/`.

## Frontend structure

```
frontend/lib/
  main.dart
  app/        App widgets, theme and navigation
  core/       Audio, network client, storage, notifications, constants
  shared/     Models, data and widgets used by several features
  features/   One folder per feature
    <feature>/
      data/          API requests and data managers
      models/
      presentation/
        phone/
        desktop/
        widgets/     Shared by phone and desktop
```

Import each symbol from the file that declares it, using `package:pongo/...` paths. Authenticated requests go through `core/network/api_client.dart`.

## How Does It Work?

### Catalog

Search, albums, artists, playlists, genres and new releases come from the public [Deezer API](https://developers.deezer.com/api), which needs no key. The server reshapes the responses into the JSON the app's models expect (`api/pongo/library/metadata/deezer.py`), so another provider can be swapped in there.

### Getting a track onto the server

1. The app opens a WebSocket to `/test` with the track id. The server answers `exists: true` if it already has the audio, otherwise `exists: false`.
2. For a new track, the server takes its title, artist and length from Deezer and searches YouTube Music, scoring results on title, artist and length and rejecting other recordings such as karaoke or live versions (`library/track/matcher.py`).
3. `yt-dlp` downloads the best match as m4a, first with its `visionos` YouTube client, which skips the roughly 5 second wait the default clients need, and with the default clients if that fails (`YTDLP_PLAYER_CLIENTS`). The file is hashed, and it is stored on the audio volume under its SHA-256 so identical audio is kept once.
4. The server sends the duration, or `exists: failed` if no good match exists. Concurrent requests for one track share a single download. For queues, playlists and mixes the server fetches up to `MAX_CONCURRENT_DOWNLOADS` (4) tracks ahead of the one being waited on.

### Playback

The native player requests `/play_song/{id}?st=<stream token>`, which serves the file with HTTP range support. The stream token is per device and stops working when the device is removed or the user is disabled.

### Mix Mode

When a single track is played with mix on, the app keeps the queue going: whenever two or fewer tracks are left, it posts the last five tracks played and everything already queued to `/next_mix_tracks`. The server picks similar tracks from the Deezer radios of those tracks' artists and the latest artist's related artists, downloads three of them, and returns them with their lengths; it keeps no mix state between calls. The app makes one such request at a time, drops answers for a queue it has since left, and after a failure tries again with growing delays.

## App Preview

<img src="https://github.com/user-attachments/assets/1afacff7-c027-48fd-a900-be631d27c1f6" width="293" height="633" />
<img src="https://github.com/user-attachments/assets/48885f3a-6c38-4289-b09a-2cfe10855a46" width="293" height="633" />
<img src="https://github.com/user-attachments/assets/535b95df-62f5-4953-92fe-c22e60e55514" width="293" height="633" />
<img src="https://github.com/user-attachments/assets/a0aac160-664d-410d-b544-bf0be7a2dcbf" width="293" height="633" />
<img src="https://github.com/user-attachments/assets/c2d8204d-5408-42b1-922b-3eda18445fe1" width="293" height="633" />




