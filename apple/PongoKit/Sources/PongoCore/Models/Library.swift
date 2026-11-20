import Foundation

/// A track the user marked as a favourite.
public struct Favourite: Sendable, Hashable, Identifiable {
    public var id: Int
    public var stid: String
    public var title: String
    public var artists: [ArtistRef]
    public var album: AlbumRef?
    public var image: String?

    public init(
        id: Int = -1, stid: String, title: String, artists: [ArtistRef], album: AlbumRef?,
        image: String?
    ) {
        self.id = id
        self.stid = stid
        self.title = title
        self.artists = artists
        self.album = album
        self.image = image
    }

    /// A favourite for the catalog [track].
    public init(track: Track) {
        self.init(
            stid: track.id, title: track.name, artists: track.artists, album: track.album,
            image: track.album.map { $0.images.bestURL })
    }

    /// The favourite as a playable track.
    public var track: Track { Track(id: stid, name: title, artists: artists, album: album) }
}

/// A track downloaded to the device.
public struct DownloadedTrack: Sendable, Hashable, Identifiable {
    public var track: Track
    /// The track's length in milliseconds.
    public var durationMilliseconds: Int
    /// The row ID, which grows with each download.
    public var rowID: Int
    /// Whether the track is hidden, when it's part of a playlist.
    public var hidden: Bool

    public var id: String { track.id }
}

/// A playlist the user made, of catalog tracks or of downloaded tracks.
public struct UserPlaylist: Sendable, Hashable, Identifiable {
    /// The playlist's ID in its table.
    public var id: Int
    public var title: String
    /// The cover image bytes, if the user set one.
    public var cover: Data?

    public init(id: Int, title: String, cover: Data?) {
        self.id = id
        self.title = title
        self.cover = cover
    }
}

/// Which kind of playlist: of catalog tracks or of downloaded ones.
public enum PlaylistKind: String, Sendable, Hashable {
    case online
    case offline
}

/// A catalog track saved in one of the user's online playlists.
public struct OnlinePlaylistTrack: Sendable, Hashable {
    public var opid: Int
    public var stid: String
    public var title: String
    public var artists: [ArtistRef]
    public var album: AlbumRef?
    public var image: String?
    public var orderNumber: Int
    public var hidden: Bool

    public init(
        opid: Int, stid: String, title: String, artists: [ArtistRef], album: AlbumRef?,
        image: String?, orderNumber: Int = -1, hidden: Bool = false
    ) {
        self.opid = opid
        self.stid = stid
        self.title = title
        self.artists = artists
        self.album = album
        self.image = image
        self.orderNumber = orderNumber
        self.hidden = hidden
    }

    /// An entry of playlist [opid] for the catalog [track], with a 150 pixel
    /// cover like the Flutter app keeps.
    public init(opid: Int, track: Track, hidden: Bool = false) {
        self.init(
            opid: opid, stid: track.id, title: track.name, artists: track.artists,
            album: track.album,
            image: track.album?.images.url(forWidth: 150, height: 150), hidden: hidden)
    }

    /// The entry as a playable track.
    public var track: Track { Track(id: stid, name: title, artists: artists, album: album) }
}

/// A sleep timer that fades the music out, optionally followed by an alarm
/// that fades it back in.
public struct SleepAlarm: Sendable, Hashable, Identifiable {
    public var id: Int
    /// Whether the music fades out.
    public var sleep = true
    /// Minutes the fade out takes.
    public var sleepDuration = 30
    public var sleepLinear = true
    /// Whether the music fades back in at [wakeTime].
    public var alarmClock = false
    /// Minutes after midnight the fade in ends. Defaults to 7:30 am.
    public var wakeTime = 450
    /// Minutes the fade in takes.
    public var beforeEndTimeMin = 30
    public var alarmClockLinear = true

    public init(id: Int = -1) { self.id = id }
}

/// How downloaded tracks are sorted.
public enum LocalsSort: String, Sendable, CaseIterable {
    case titleAscending = "A-Z"
    case titleDescending = "Z-A"
    case firstAdded = "First added"
    case lastAdded = "Last added"

    /// The sort stored as [value], defaulting to the newest first like before.
    public static func fromStorage(_ value: String) -> LocalsSort {
        LocalsSort(rawValue: value) ?? .lastAdded
    }
}

/// How lyrics are aligned.
public enum LyricsAlignment: String, Sendable, CaseIterable {
    case left
    case center
    case right
    case justify
}

/// The user's preferences, with the defaults of a fresh install.
public struct AppSettings: Sendable, Hashable {
    public var locale = "en"
    public var market = "US"
    public var useSyncTimeDelay = false
    public var useSyncedLyrics = true
    public var searchArtistCount = 1
    public var searchAlbumCount = 1
    public var searchTrackCount = 50
    public var searchPlaylistCount = 20
    public var lyricsTextAlign = LyricsAlignment.left
    public var useCacheAudioSource = false
    public var enableLyrics = true
    public var enableHistory = true
    public var enableCategories = true
    public var categoryCount = 50
    public var cacheImages = false
    public var localsSort = LocalsSort.titleAscending
    public var useBlur = true
    public var useMix = true
    public var useDetailedBlurhash = true
    public var sleepAlarmDeviceVolume = 0.0
    public var darkMode = true
    public var linearSleepIn = true
    public var linearWakeUp = true
    public var useDynamicBlurhash = true
    public var useAnimations = true
    public var useLiquidGlass = true
    /// Experimental: tracks the server is still downloading play from its
    /// stream of the download instead of after it.
    public var streamWhileDownloading = false
    /// Whether the playing song's lyrics show on the Lock Screen and in the
    /// Dynamic Island.
    public var showLiveLyrics = true
    /// Seconds a song fades into the next one; 0 plays them one after the
    /// other.
    public var crossfadeSeconds = 0
    /// Whether songs of one album that follow each other play without a fade,
    /// as the album was mastered.
    public var gaplessAlbums = true
    /// Whether the low bass is lifted a little, so songs sound deeper.
    public var bassBoost = false
    /// Whether shuffling a playlist or the favourites mixes in suggested
    /// songs like them.
    public var smartShuffle = true

    public init() {}
}
