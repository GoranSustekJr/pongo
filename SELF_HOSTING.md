# Self-hosting Pongo

Pongo is a self-hosted music app: you run the server on your own machine and install the native app on your own iPhone or Mac. This guide takes you from nothing to playing music in about ten minutes, with no accounts or keys to set up.

## Before you start: personal use only

Pongo finds each song's metadata on [Deezer](https://developers.deezer.com/api) and downloads the matching audio from YouTube with [yt-dlp](https://github.com/yt-dlp/yt-dlp). Downloading from YouTube is against YouTube's terms of service, and the music itself is copyrighted.

- Run Pongo for yourself, and at most a few people you know. Don't run it as a public service.
- Don't share the server's address publicly: anyone who can reach it can create an account, unless you [make it invite-only](#invite-only).
- You are responsible for how you use it and for following the law where you live.

The code is under the [MIT License](LICENSE): free to use, change and share, with no warranty.

## What you need

- **A computer that stays on**, to run the server: a Mac, a Linux box, a home server or a Raspberry Pi 4 or later. 2 CPU cores, 2 GB of RAM, and disk for the music (about 4 MB per song).
- **Docker** on that computer: [Docker Desktop](https://www.docker.com/products/docker-desktop/) for Mac or Windows, `docker` with the compose plugin on Linux, or on a Mac [Colima](https://github.com/abiosoft/colima) (`brew install colima docker docker-compose && colima start`).
- **An iPhone on iOS 26.1 or later, or a Mac on macOS 26.1 or later.**

## 1. Start the server

```sh
git clone https://github.com/GoranSustekJr/pongo.git
cd pongo
./setup.sh
```

The script writes `.env` with new random passwords, builds and starts the server, and prints the address to type into the app:

```
Pongo is running.
In the app, connect to:   192.168.1.10:8081
```

The first start takes a few minutes. The database and the music are kept in Docker volumes, so they survive restarts and updates. To update later, `git pull` and run `./setup.sh` again.

## 2. Install the app

Download the app from the [latest release](https://github.com/GoranSustekJr/pongo/releases/latest):

- **iPhone: `Pongo.ipa`.** Install it with [SideStore](https://sidestore.io) or [AltStore](https://altstore.io), which sign apps with your own free Apple ID. Apps installed that way have to be refreshed every 7 days, which SideStore and AltStore do for you.
- **Mac: `Pongo-Mac.zip`.** Unzip it and move Pongo to Applications. It isn't notarized by Apple, so the first time macOS refuses to open it: go to **System Settings → Privacy & Security** and click **Open Anyway**.

Or [build the app yourself](#building-the-app-yourself) with Xcode.

## 3. Connect and create an account

Open the app, type the address `setup.sh` printed, and tap **Connect**. Then tap **New here? Create an account**, pick a username and password, and play something.

Your phone or Mac has to be on the same network as the server. Everyone who wants to listen creates their own account the same way; each has their own library, playlists and friends.

## 4. Optional: use it away from home

The easiest way is [Tailscale](https://tailscale.com), free for personal use. It connects your devices privately, with no ports to open on your router and no domain to buy:

1. Install Tailscale on the server and on your phone or Mac, signed in to the same account.
2. In the [Tailscale admin console](https://login.tailscale.com/admin/dns), turn on **MagicDNS** and **HTTPS certificates**.
3. On the server, run `tailscale serve --bg 8081`. It prints an address like `https://my-server.tail1234.ts.net`.
4. In the app, go to **Settings → Profile → Change server** and enter that address. It works at home and away.

To share the server with friends, [share the machine](https://tailscale.com/kb/1084/sharing) with them in Tailscale. If you'd rather use a domain of your own, see [below](#reaching-it-from-outside-your-home-with-your-own-domain).

That's all you need. The rest of this guide is optional.

## Settings

Everything is in `.env` next to `docker-compose.yml`. After changing it, run `docker compose up -d`.

| Setting | What it does |
|---|---|
| `SERVER_NAME` | The name the app shows when it connects. |
| `OPEN_SIGNUP` | `true`: anyone who can reach the server can create an account. `false`: [invite-only](#invite-only). |
| `PASSWORD_ACCOUNTS` | `false` turns off username and password accounts, leaving only Google sign-in. |
| `API_PORT` | The port the server listens on, 8081 by default. |
| `DOWNLOADS_PER_HOUR`, `REQUESTS_PER_MINUTE`, ... | Rate limits; see [Troubleshooting](#troubleshooting). |

### Invite-only

With `OPEN_SIGNUP=false` nobody can create an account in the app. You create them on the server, and only the accounts you made, plus the Google emails you allow, can sign in:

```sh
docker compose exec api python -m library.auth.passwords create <username>   # asks for the password
docker compose exec api python -m library.auth.passwords reset <username>    # a new password, signs it out everywhere
scripts/enable_user.sh someone@gmail.com                                      # lets a Google account in
```

### Google sign-in

Optional; username and password accounts need none of this. Google sign-in needs your own Google client ID built into the app, so it only works if you build the app yourself.

1. In the [Google Cloud Console](https://console.cloud.google.com/), create a project, then go to **APIs & Services → OAuth consent screen**. Set it up as **External** and add your email under **Test users**.
2. Go to **Credentials → Create credentials → OAuth client ID**, choose **iOS**, and enter the bundle ID you give the app, such as `com.yourname.pongo`.
3. Put the **Client ID** (`1234-abc.apps.googleusercontent.com`) in `IOS_CLIENT_ID` in `.env` and run `docker compose up -d`, and in `GOOGLE_CLIENT_ID` in the app's local settings (next section). The iPhone and Mac apps both use this iOS client.

## Building the app yourself

You need a Mac with [Xcode](https://developer.apple.com/xcode/) 27. A free Apple ID works, but apps installed with it stop opening after 7 days until you install them again; a paid developer account ($99/year) gives 1-year installs and TestFlight.

Create `apple/Config/Pongo.local.xcconfig` (it's gitignored):

```
DEVELOPMENT_TEAM = <your Apple team ID>
PONGO_BUNDLE_ID = com.yourname.pongo
// Optional: the server to use without asking, and Google sign-in
PONGO_SERVER_URL = http:/$()/192.168.1.10:8081/
GOOGLE_CLIENT_ID = <your Google iOS client ID>
```

`/$()/` keeps Xcode from reading `//` as the start of a comment. Your team ID is under **Membership** on [developer.apple.com](https://developer.apple.com/account), or in Xcode under **Settings → Accounts**. Without `PONGO_SERVER_URL` the app asks for the server on first launch, as the downloaded one does.

- **iPhone:** connect it, trust the Mac, and turn on **Developer Mode** on the phone (Settings → Privacy & Security). Open `apple/Pongo.xcodeproj`, pick the **Pongo** scheme and your iPhone, and press Run.
- **Mac:** pick the **Pongo Mac** scheme and press Run.

To update the app later, run it from Xcode again; installing over it keeps its data. `apple/scripts/build_release.sh` builds the `Pongo.ipa` and `Pongo-Mac.zip` that go in a GitHub release, without your server address or Google client ID in them.

## Reaching it from outside your home, with your own domain

[Tailscale](#4-optional-use-it-away-from-home) is the easiest way. If you'd rather reach the server at a hostname of your own, it needs HTTPS: the app sends sign-in tokens to the server, so don't expose it over plain HTTP. Use a certificate from Let's Encrypt: devices trust it as it is, while a certificate you sign yourself has to be installed on every device, and work Macs often don't allow that.

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

In the app, go to **Settings → Profile → Change server** and type `https://yourname.duckdns.org:<port>`. If you build the app yourself you can also build the address in, as [Building the app yourself](#building-the-app-yourself) shows; `PONGO_LOCAL_SERVER_URL` can then keep the LAN address, which the app falls back to when the first one can't be reached.

## Troubleshooting

| Problem | What to check |
|---|---|
| The app can't reach the server | Is the phone on the same Wi-Fi? Did the server's address change? Home routers hand out new ones, so run `./setup.sh` again to see the current one, and reserve it in the router to keep it. Does `http://<address>:8081/health` open in a browser on another device? Is a firewall blocking port 8081? |
| Someone forgot their password | `docker compose exec api python -m library.auth.passwords reset <username>` sets a new one and signs that account out everywhere. |
| Songs stopped downloading | YouTube changes often and older yt-dlp versions stop working. Raise the `yt-dlp` version in `api/pongo/requirements.txt` (on GitHub, Dependabot opens a pull request for it every week), rebuild with `docker compose up -d --build api`, and check with `scripts/check_download.sh`. `docker compose logs api` shows the error. |
| A song is always "unavailable" | No YouTube video matched it closely enough. The server waits an hour before searching for it again. |
| Docker on a Mac says `docker-credential-desktop` not found | `~/.docker/config.json` contains `"credsStore": "desktop"` left over from Docker Desktop; remove that line. |
| Sign-in fails with "not allowed" | The server is invite-only. Create a password account for the person, or add their Google email to `ALLOWED_EMAILS` or with `scripts/enable_user.sh`. |
| Requests fail with 429 | A rate limit was hit: sign-ins, requests and connections per IP, and new downloads per user per hour. Raise `SIGN_INS_PER_MINUTE`, `REQUESTS_PER_MINUTE`, `SOCKETS_PER_MINUTE` or `DOWNLOADS_PER_HOUR` in `.env` if they're too low for you. |
| The app stops opening after a week | That's the free Apple account's 7-day limit. SideStore and AltStore refresh it for you; from Xcode, run it again. Your data stays. |
| Updating the server | `git pull`, then `./setup.sh` again. It keeps your `.env` and data, rebuilds and restarts. |

## Security

- Passwords are stored as scrypt hashes. On an [invite-only](#invite-only) server, only accounts you create or emails you allow get in, and strangers' sign-ins aren't stored.
- Rate limits apply per IP, plus a limit on new downloads per user per hour.
- Access tokens last 2 hours. Refresh tokens are replaced every time they're used, and if an old one is used again the device is signed out.
- The audio links carry a stream token that expires after 7 days.
- The API container runs read-only, as a normal user, with no Linux capabilities. Over the internet only HTTPS is served, through Caddy.
- yt-dlp is pinned to a known version instead of updating itself.

## How it works

The [README](README.md#how-does-it-work) explains how tracks are matched, downloaded, streamed and mixed, and [apple/README.md](apple/README.md) describes the apps' structure.
