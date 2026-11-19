# Pongo for iOS (native)

A SwiftUI rewrite of the Flutter app in `frontend/`. It talks to the same
server, uses the same database layout and sync format, so a library syncs
between this app and the Flutter one.

## Layout

- `PongoKit/`: the Swift package `PongoCore`, which holds everything but the
  UI: API client, track websocket, SQLite database, library sync, sign-in,
  settings, downloads and the player. It builds for iOS and macOS and has no
  third-party dependencies.
- `Pongo/`: the iOS app (SwiftUI). `App/` creates the services, and `Shared/`
  holds the screens.
- `LiveLyrics/`: the widget extension that draws the Live Activity, and
  `Shared/` (top level) what it and the app both use.
- `Config/`: build settings and the Info.plist.
- `scripts/generate_strings.py`: generates `Pongo/Resources/Localizable.xcstrings`
  and `Pongo/Shared/Strings.swift` from the Flutter `.arb` files plus
  `scripts/extra_strings.json`. Run it after changing either.

## Setup

1. Create `Config/Pongo.local.xcconfig` (it's gitignored):

   ```
   PONGO_SERVER_URL = http:/$()/<your server LAN IP>:8081/
   GOOGLE_CLIENT_ID = <iOS OAuth client ID>.apps.googleusercontent.com
   DEVELOPMENT_TEAM = <your team ID>
   ```

   `/$()/` keeps xcconfig from reading `//` as a comment.

2. Open `Pongo.xcodeproj` in Xcode 27 and run the `Pongo` scheme.

The app needs iOS 26.1. Its bundle ID is `com.example.pongo.swift`, so it
installs next to the Flutter app instead of replacing it, and each app keeps
its own data. Set `PONGO_BUNDLE_ID` in the local xcconfig to change it.

Sign-in opens Google in a browser sheet (OAuth with PKCE) and uses the same iOS
client ID as the Flutter app, so the server accepts its tokens without changes.

Tests for the core run with `swift test` in `PongoKit/`.

## Differences from the Flutter app

The screens follow the Flutter app's look (its background, colors, big synced
lyrics with blur, the queue and lyrics panels in the player, the delay
controls) with iOS 26 parts where iOS has its own: the tab bar (Home, Library,
Settings), the mini player in the tab bar, Liquid Glass and swipe actions.

- Search sits at the top of Home: its history shows while the field is
  focused and results as you type. Genres jump into it.
- Covers aren't shown as blurhash placeholders. The player blurs the artwork
  itself instead.
- There's no onboarding, because its images show the old interface.
- Picking tracks to edit opens a sheet with a selection list instead of
  check boxes in place.
- Live lyrics: while a song plays, a Live Activity shows it with the line
  being sung on the Lock Screen and in the Dynamic Island, with play or pause
  and next. It can be turned off in the preferences, under lyrics.
- Holding a lyrics line makes a card of it, with more lines if you tap them,
  over the song's colors to share or save.
- Home opens with shortcuts to the favourites, downloads and the albums,
  playlists and genres played last, then mixes made from what you play
  (a daily mix per top artist and one of your favourites), numbered charts,
  and genres that open their own page. The last Home page is kept, so it
  shows at once, also offline. Genre pages need the server's `get_genre`.
- Lyrics can be translated line by line into the app's language (or
  English when Apple's Translation doesn't offer it), on the device.
  Downloaded tracks keep their lyrics, so they show offline.
- Your moods on Home: the server listens to each song once (tempo, beat,
  bass, brightness, major or minor key) and sorts it into chill, happy,
  energetic, party, intense or melancholy. Each mood card plays your songs
  of that mood and goes on with new songs that sound the same. On iPhones
  with Apple Intelligence, the on-device model names each card.
- Smart shuffle (on by default): shuffling a playlist or the favourites
  mixes in a few songs like them, which a tap in the queue keeps.
- Crossfade (off by default, up to 12 seconds) fades each song into the next.
  Songs of one album that follow each other still play gapless, unless that's
  turned off.

## Trying the UI in the simulator

Debug builds launched with `-PongoDemo` skip sign-in and fill the queue,
favourites and a playlist with sample tracks. Add `-PongoDemoScreen <name>`
to open `player`, `lyrics`, `queue`, `library`, `favourites`, `settings`,
`preferences` or `sleep`, and `-PongoDemoScrolled` (or `-PongoDemoMiddle`) to open lists scrolled to
their end (or middle). With `lyrics`, `-PongoDemoPosition <seconds>` jumps into the song, and the
screen `card` opens a lyric card:

```
xcrun simctl launch booted com.example.pongo.swift -PongoDemo -PongoDemoScreen lyrics
```

## macOS

`PongoCore` already builds for macOS. Platform code is behind `#if os(iOS)`:
the audio session, the device volume and the artwork for Now Playing. Adding a
Mac app means:

- a macOS target in the project that shares `Pongo/Shared`
- replacing the few UIKit pieces in the UI (`UIImage` in `Support.swift` and
  `PlaylistViews.swift`, `DeviceVolume.swift`) with platform-neutral ones
- a Mac layout (sidebar instead of tabs) in place of `MainTabView`
