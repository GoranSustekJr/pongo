# Self-hosting Pongo

Pongo is being revived as a self-hosted music app: you run the server on your own machine and install the app on your own phone. This guide takes you from a fresh clone to playing music, first on your home network and then, optionally, from anywhere.

The iOS app is the focus of the revival. macOS and Android builds exist but haven't been brought up to date yet.

## Before you start: personal use only

Pongo finds each song's metadata on [Deezer](https://developers.deezer.com/api) and downloads the matching audio from YouTube with [yt-dlp](https://github.com/yt-dlp/yt-dlp). Downloading from YouTube is against YouTube's terms of service, and the music itself is copyrighted.

- Run Pongo for yourself, and at most a few people you know. Don't run it as a public service.
- Keep sign-in limited to people you know (`ALLOWED_EMAILS`, see below).
- You are responsible for how you use it and for following the law where you live.

The code is under the [MIT License](LICENSE): free to use, change and share, with no warranty.

## What you need

| | |
|---|---|
| **Server** | Any machine that can run Docker: a Mac, a Linux box, a home server. 2 CPU cores, 2 GB of RAM and some disk for the audio (about 4 MB per song). |
| **Docker** | [Docker Desktop](https://www.docker.com/products/docker-desktop/), or on a Mac [Colima](https://github.com/abiosoft/colima) (`brew install colima docker docker-compose && colima start`). |
| **For the iOS app** | A Mac with [Xcode](https://developer.apple.com/xcode/) and [Flutter](https://docs.flutter.dev/get-started/install) 3.47 or newer, and an iPhone on iOS 15 or later. |
| **Apple account** | A free Apple ID works, but apps installed with it stop opening after 7 days until you install them again. A paid developer account ($99/year) gives 1-year installs, TestFlight and Sign in with Apple. |
| **Google Cloud project** | Free. Used only for Google sign-in. |

## 1. Start the server

```sh
git clone https://github.com/GoranSustekJr/pongo.git
cd pongo
cp .env.example .env
```

Edit `.env`:

| Setting | What to put |
|---|---|
| `DB_PASSWORD`, `JWT_SECRET` | Long random values: run `openssl rand -hex 48` once for each. |
| `ALLOWED_EMAILS` | The Google account emails allowed in, comma separated. Anyone else who signs in gets a disabled account. |
| `IOS_CLIENT_ID` | Your Google iOS client ID, from step 2. |

Leave the rest as it is for now, then start the server:

```sh
docker compose up -d --build
curl http://localhost:8081/health      # {"status":"ok"}
```

The first start takes a few minutes. The database and the audio are kept in Docker volumes (`pongo_db`, `pongo_audio`), so they survive restarts and rebuilds.

## 2. Set up Google sign-in

1. In the [Google Cloud Console](https://console.cloud.google.com/), create a project, then go to **APIs & Services → OAuth consent screen**. Set it up as **External** and add your email under **Test users**.
2. Go to **Credentials → Create credentials → OAuth client ID**, choose **iOS**, and enter the bundle ID you'll give the app in step 3, such as `com.yourname.pongo`.
3. Copy the **Client ID** (`1234-abc.apps.googleusercontent.com`) into:
   - `IOS_CLIENT_ID` in the server's `.env`, then run `docker compose up -d` again;
   - `iosClientID` in `frontend/.env` (step 3).
4. Copy the **iOS URL scheme** (`com.googleusercontent.apps.1234-abc`) into `frontend/ios/Runner/Info.plist`, replacing the existing `com.googleusercontent.apps.…` value under `CFBundleURLSchemes`.

## 3. Build the app

Create `frontend/.env`. For a phone on the same Wi-Fi, use the server's LAN address, not `localhost`. On a Mac, `ipconfig getifaddr en0` prints it.

```
iosClientID=<your Google iOS client ID>
androidClientID=
desktopClientID=
desktopClientSecred=
SERVER_URL=http://192.168.1.10:8081/
SERVER_URL_WSS=ws://192.168.1.10:8081/
```

Then set up signing:

1. Open `frontend/ios/Runner.xcworkspace` in Xcode.
2. Select the **Runner** target → **Signing & Capabilities**, choose your own **Team**, and change the **Bundle Identifier** to the one from step 2.
3. Connect the iPhone, trust the Mac, and turn on **Developer Mode** on the phone (Settings → Privacy & Security).

Install and start it:

```sh
cd frontend
flutter pub get
flutter run --release -d <your device>     # flutter devices lists them
```

To update the app later, run the same command again. **Don't use `flutter install`**: it deletes the app first, along with all its data on the phone (downloads, playlists, sign-in).

Sign in with Google in the app. If your email isn't in `ALLOWED_EMAILS`, enable the account with `scripts/enable_user.sh you@example.com`.

## 4. Use it from anywhere (optional)

To reach the server away from home, it needs a hostname and HTTPS. The app sends sign-in tokens to the server, so don't expose it over plain HTTP.

1. Get a free dynamic DNS hostname, for example from [No-IP](https://www.noip.com) or [Duck DNS](https://www.duckdns.org), pointing at your home IP. Their update client or your router keeps it current.
2. On your router, forward ports **80** and **443** to the server. Let's Encrypt checks the hostname over port 80.
3. Set `PONGO_DOMAIN=yourname.ddns.net` in `.env` and start with the public override. It adds [Caddy](https://caddyserver.com), which gets the certificate automatically, and makes port 8081 reachable only from the server itself:

   ```sh
   docker compose -f docker-compose.yml -f docker-compose.public.yml up -d --build
   curl https://yourname.ddns.net/health
   ```

4. Point the app at it in `frontend/.env` and build again:

   ```
   SERVER_URL=https://yourname.ddns.net/
   SERVER_URL_WSS=wss://yourname.ddns.net/
   ```

The iOS app allows plain HTTP only on the local network, so a build against your LAN address keeps working for development.

## Troubleshooting

| Problem | What to check |
|---|---|
| The app can't reach the server | Is the server's LAN address still the one in `frontend/.env`? Home routers hand out new ones; reserving the address in the router stops that. Is the phone on the same Wi-Fi? Does `curl http://<address>:8081/health` work from another machine? Is a firewall blocking port 8081? |
| Songs stopped downloading | YouTube changes often and older yt-dlp versions stop working. The server updates yt-dlp on every start (`YTDLP_AUTO_UPDATE`), so run `docker compose restart api`. Check `docker compose logs api` for the error. |
| A song is always "unavailable" | No YouTube video matched it closely enough. The server waits an hour before searching for it again. |
| Docker on a Mac says `docker-credential-desktop` not found | `~/.docker/config.json` contains `"credsStore": "desktop"` left over from Docker Desktop; remove that line. |
| The app stops opening after a week | That's the free Apple account's 7-day limit. Run `flutter run --release` again; your data stays. |

## How it works

The [README](README.md#how-does-it-work) explains how tracks are matched, downloaded, streamed and mixed, and [docs in the frontend](README.md#frontend-structure) describe the app's structure.
