# Self-hosting Pongo

Pongo is a self-hosted music app: you run the server on your own machine and install the native app on your own iPhone or Mac. This guide takes you from a fresh clone to playing music, first on your home network and then, optionally, from anywhere.

The apps are written in SwiftUI, in [`apple/`](apple/). The original Flutter app is archived and no longer developed.

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
| **For the apps** | A Mac with [Xcode](https://developer.apple.com/xcode/) 27, and an iPhone on iOS 26.1 or later or a Mac on macOS 26.1 or later. |
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
| `ALLOWED_EMAILS` | The Google account emails allowed in, comma separated. Sign-ins from any other email are refused, and nothing about them is stored. |
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
   - `GOOGLE_CLIENT_ID` in the apps' local settings (step 3).

The iPhone and Mac apps both use this iOS client.

## 3. Build the app

Create `apple/Config/Pongo.local.xcconfig` (it's gitignored). For a phone on the same Wi-Fi, use the server's LAN address, not `localhost`. On a Mac, `ipconfig getifaddr en0` prints it.

```
PONGO_SERVER_URL = http:/$()/192.168.1.10:8081/
GOOGLE_CLIENT_ID = <your Google iOS client ID>
DEVELOPMENT_TEAM = <your Apple team ID>
PONGO_BUNDLE_ID = <the bundle ID from step 2>
```

`/$()/` keeps Xcode from reading `//` as the start of a comment. Your team ID is under **Membership** on [developer.apple.com](https://developer.apple.com/account), or in Xcode under **Settings → Accounts**.

Then install it:

- **iPhone:** connect it, trust the Mac, and turn on **Developer Mode** on the phone (Settings → Privacy & Security). Open `apple/Pongo.xcodeproj`, pick the **Pongo** scheme and your iPhone, and press Run.
- **Mac:** pick the **Pongo Mac** scheme and press Run, or build it with `xcodebuild -project apple/Pongo.xcodeproj -scheme "Pongo Mac" -configuration Release build` and copy `Pongo.app` to Applications.

To update the app later, run it from Xcode again; installing over it keeps its data.

To give the Mac app to someone else, zip `Pongo.app` with `ditto -c -k --keepParent Pongo.app Pongo.zip`. With a free Apple account it isn't notarized, so the first time they open it they have to click **Open Anyway** in System Settings → Privacy & Security.

Sign in with Google in the app. To let in someone whose email isn't in `ALLOWED_EMAILS`, run `scripts/enable_user.sh them@example.com`; no restart needed.

## 4. Reaching it from outside your home

To reach the server away from home, it needs a hostname and HTTPS. The app sends sign-in tokens to the server, so don't expose it over plain HTTP. Use a certificate from Let's Encrypt: devices trust it as it is, while a certificate you sign yourself has to be installed on every device, and work Macs often don't allow that.

### With ports 80 and 443

1. Get a free dynamic DNS hostname, for example from [No-IP](https://www.noip.com) or [Duck DNS](https://www.duckdns.org), pointing at your home IP. Their update client or your router keeps it current.
2. On your router, forward ports **80** and **443** to the server. Let's Encrypt checks the hostname over port 80.
3. Set `PONGO_DOMAIN=yourname.ddns.net` in `.env` and start with the public override. It adds [Caddy](https://caddyserver.com), which gets the certificate automatically, and makes port 8081 reachable only from the server itself:

   ```sh
   docker compose -f docker-compose.yml -f docker-compose.public.yml up -d --build
   curl https://yourname.ddns.net/health
   ```

### Without them: the DNS check

If your provider blocks ports 80 and 443, or the router uses them, Let's Encrypt can check a DNS record instead, and the server can use any port. Caddy sets the record through [Duck DNS](https://www.duckdns.org), which is free.

1. Sign in at duckdns.org, create a subdomain, and copy the token shown at the top of the page.
2. In `.env`, set:

   ```
   PONGO_DOMAIN=yourname.duckdns.org
   DUCKDNS_TOKEN=<your token>
   PONGO_TLS_PORT=9090
   PONGO_OWN_CERT_SITES=https://192.168.1.10:9090
   COMPOSE_FILE=docker-compose.yml:docker-compose.host.yml:docker-compose.dns.yml
   ```

   This setup runs the containers on the host's network, so it's meant for a Linux server. `PONGO_OWN_CERT_SITES` lists the addresses, such as the server's LAN address, that use a certificate of your own from `secrets/tls` (`server-fullchain.crt` and `server.key`), since Let's Encrypt doesn't sign private addresses.
3. Forward a port of your choice on the router to `PONGO_TLS_PORT`, then start it. A small container keeps the hostname pointed at your home IP, and Caddy renews the certificate by itself:

   ```sh
   docker compose up -d --build
   curl https://yourname.duckdns.org:<port>/health
   ```

### Pointing the apps at it

Set the new address in `apple/Config/Pongo.local.xcconfig` and build again. `PONGO_LOCAL_SERVER_URL` can keep the LAN address; the apps fall back to it when the first address can't be reached.

```
PONGO_SERVER_URL = https:/$()/yourname.duckdns.org:<port>/
PONGO_LOCAL_SERVER_URL = http:/$()/192.168.1.10:8081/
```

The apps allow plain HTTP only on the local network, so a build against your LAN address keeps working for development.

## Troubleshooting

| Problem | What to check |
|---|---|
| The app can't reach the server | Is the server's LAN address still the one in `Pongo.local.xcconfig`? Home routers hand out new ones; reserving the address in the router stops that. Is the phone on the same Wi-Fi? Does `curl http://<address>:8081/health` work from another machine? Is a firewall blocking port 8081? |
| Songs stopped downloading | YouTube changes often and older yt-dlp versions stop working. Raise the `yt-dlp` version in `api/pongo/requirements.txt` (on GitHub, Dependabot opens a pull request for it every week), rebuild with `docker compose up -d --build api`, and check with `scripts/check_download.sh`. `docker compose logs api` shows the error. |
| A song is always "unavailable" | No YouTube video matched it closely enough. The server waits an hour before searching for it again. |
| Docker on a Mac says `docker-credential-desktop` not found | `~/.docker/config.json` contains `"credsStore": "desktop"` left over from Docker Desktop; remove that line. |
| Sign-in fails with "not allowed" | The email isn't in `ALLOWED_EMAILS`; add it there, or run `scripts/enable_user.sh`. |
| Requests fail with 429 | A rate limit was hit: sign-ins, requests and connections per IP, and new downloads per user per hour. Raise `SIGN_INS_PER_MINUTE`, `REQUESTS_PER_MINUTE`, `SOCKETS_PER_MINUTE` or `DOWNLOADS_PER_HOUR` in `.env` if they're too low for you. |
| The app stops opening after a week | That's the free Apple account's 7-day limit. Run it from Xcode again; your data stays. |

## Security

- Only allowed emails can sign in, and strangers' sign-ins aren't stored.
- Rate limits apply per IP, plus a limit on new downloads per user per hour.
- Access tokens last 2 hours. Refresh tokens are replaced every time they're used, and if an old one is used again the device is signed out.
- The audio links carry a stream token that expires after 7 days.
- The API container runs read-only, as a normal user, with no Linux capabilities. Over the internet only HTTPS is served, through Caddy.
- yt-dlp is pinned to a known version instead of updating itself.

## How it works

The [README](README.md#how-does-it-work) explains how tracks are matched, downloaded, streamed and mixed, and [apple/README.md](apple/README.md) describes the apps' structure.
