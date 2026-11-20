import Foundation
import Observation
import PongoCore
import SwiftUI

/// A request to add tracks to the user's playlists, shown by the playlist
/// picker.
struct PlaylistRequest: Identifiable {
    let id = UUID()
    var kind: PlaylistKind
    var tracks: [Track]
    /// Track IDs that have to be downloaded before an offline playlist can
    /// hold them.
    var toDownload: [String] = []
    /// Whether the picker opens on creating a new playlist, as saving the
    /// queue does.
    var creating = false
}

/// Creates every service and repository once and holds what screens share:
/// the favourites and downloads the track menus show, messages and the
/// playlist picker.
@Observable
final class AppModel {
    let config: AppConfig
    let database: Database
    let client: APIClient
    let socket: TrackSocket
    let auth: AuthRepository
    let settings: SettingsRepository
    let catalog: CatalogRepository
    let downloads: DownloadsRepository
    let lyrics: LyricsClient
    let player: Player
    let listening: ListeningSession
    let sync: LibrarySync
    let router = Router()
    let messages = MessageCenter()
    let nowPlaying = NowPlayingModel()
    let recents = RecentCollections()
    #if os(iOS)
        @ObservationIgnored private var liveLyrics: LiveLyricsController?
    #endif
    @ObservationIgnored private var widgets: WidgetPublisher?
    /// The model of the running app, for Siri and Shortcuts.
    @ObservationIgnored nonisolated(unsafe) static weak var current: AppModel?
    #if os(iOS)
        let volume = DeviceVolume()
    #endif

    var playlistRequest: PlaylistRequest?
    /// Whether the screen of listening together shows.
    var showsListenTogether = false
    private(set) var favouriteIDs: Set<String> = []
    private(set) var downloadedIDs: Set<String> = []
    private var localRevision = 0

    /// Grows whenever the library changed, here or through a sync, so screens
    /// showing it reload.
    var libraryRevision: Int { localRevision + sync.revision }

    init() throws {
        let info = Bundle.main.infoDictionary ?? [:]
        config = AppConfig(
            serverURL: info["PongoServerURL"] as? String ?? "http://localhost:8081/",
            googleClientID: info["GoogleClientID"] as? String ?? "")
        database = try Database.appDatabase()
        client = APIClient(config: config)
        socket = TrackSocket(client: client)
        auth = AuthRepository(client: client, store: KeychainStore())
        #if os(iOS)
            settings = SettingsRepository(store: DefaultsStore(), deviceVolume: volume.level)
        #else
            settings = SettingsRepository(store: DefaultsStore())
        #endif
        catalog = CatalogRepository(client: client)
        let lyrics = LyricsClient()
        self.lyrics = lyrics
        downloads = DownloadsRepository(client: client, socket: socket, database: database, lyrics: lyrics)
        let auth = auth
        let config = config
        player = Player(
            client: client, socket: socket, gains: TrackGains(client: client, database: database),
            store: DefaultsStore(),
            streamURL: { stid, caching in
                URL(string: "\(config.serverURL)\(caching ? "play_song_caching" : "play_song")/\(stid)?st=\(auth.streamToken)")
            },
            downloadStreamURL: { stid in
                // The token is in the path, so the audio the playlist points to carries it too
                URL(string: "\(config.serverURL)stream/\(auth.streamToken)/\(stid)/index.m3u8")
            })
        listening = ListeningSession(client: client, player: player)
        sync = LibrarySync(
            client: client, store: database, sources: [database, SettingsSyncSource(settings: settings)])
        L10n.selectedLanguage = settings.settings.locale
        configurePlayer()
        #if DEBUG
            if DemoMode.isOn { DemoMode.seed(store: DefaultsStore(), database: database) }
        #endif
        player.restoreState()
        Task { await reloadLibraryIDs() }
        #if os(iOS)
            liveLyrics = LiveLyricsController(model: self)
            liveLyrics?.start()
        #endif
        widgets = WidgetPublisher(model: self)
        widgets?.start()
        Self.current = self
    }

    private func configurePlayer() {
        applyPreferences()
        player.onMessage = { [weak self] message in self?.show(message) }
        listening.onNotice = { [weak self] notice in self?.show(notice) }
        listening.delay = UserDefaults.standard.double(forKey: ListeningSession.delayKey)
        player.onTrackStarted = { [weak self] item in
            guard let self, !item.isMix, Int(item.stid) != nil else { return }
            Task { try? await self.database.addPlayedTrack(item.stid) }
        }
        player.onListened = { [weak self] item, seconds, newPlay in
            guard let self else { return }
            Task {
                try? await self.database.recordListen(item.track, seconds: seconds, newPlay: newPlay)
                if newPlay { self.widgets?.statsChanged() }
            }
        }
        #if os(iOS)
            player.setDeviceVolume = { [weak self] level in self?.volume.set(level) }
        #endif
        let log = SleepAlarmLog()
        player.log = { log.add($0) }
    }

    /// Hands the settings the player reads while playing to it.
    func applyPreferences() {
        let current = settings.settings
        var preferences = PlayerPreferences()
        preferences.useCachingSource = current.useCacheAudioSource
        preferences.linearSleepIn = current.linearSleepIn
        preferences.linearWakeUp = current.linearWakeUp
        preferences.alarmDeviceVolume = current.sleepAlarmDeviceVolume
        preferences.startMix = current.useMix
        preferences.streamWhileDownloading = current.streamWhileDownloading
        preferences.crossfade = Double(current.crossfadeSeconds)
        preferences.gaplessAlbums = current.gaplessAlbums
        preferences.bassBoost = current.bassBoost
        player.preferences = preferences
        L10n.selectedLanguage = current.locale
        URLCache.shared.diskCapacity = current.cacheImages ? 500_000_000 : 50_000_000
    }

    /// Starts syncing once signed in; signing out forgets what was synced, so
    /// another account starts afresh.
    func sessionChanged() async {
        if auth.isSignedIn {
            // A library left by another account isn't this one's
            if let account = auth.accountID {
                let owner = try? await database.libraryOwner()
                if let owner, owner != account { await clearLibrary() }
                try? await database.setLibraryOwner(account)
            }
            await sync.start()
        } else {
            // A session is someone's own; another account starts without it
            if listening.isActive { listening.leave() }
            #if DEBUG
                if DemoMode.isOn { return }
            #endif
            player.halt()
            await clearLibrary()
        }
    }

    /// Sends the last changes to the account, then signs out.
    func signOut() async {
        await sync.sync()
        auth.signOut()
    }

    /// Forgets the account's library and what was synced of it.
    private func clearLibrary() async {
        await sync.reset()
        try? await database.clearLibrary()
        libraryChanged()
        widgets?.statsChanged()
    }

    // MARK: - The library

    /// Tells screens showing the library that it changed.
    func libraryChanged() {
        localRevision += 1
        Task { await reloadLibraryIDs() }
    }

    func reloadLibraryIDs() async {
        favouriteIDs = Set((try? await database.favourites().map(\.stid)) ?? [])
        downloadedIDs = Set((try? await database.downloads().map(\.track.id)) ?? [])
    }

    // MARK: - Smart shuffle

    /// Mixes songs like those of the shuffled [collectionID] into the queue,
    /// a few more for longer lists, if the user wants that.
    func suggestSongs(for collectionID: String, trackCount: Int) {
        guard settings.settings.smartShuffle, player.queue.shuffleEnabled else { return }
        Task { await player.addSuggestions(to: collectionID, count: min(max(trackCount / 5, 2), 10)) }
    }

    /// Adds the suggested [item] to the playlist or favourites it was
    /// suggested for, which its collection names.
    func keepSuggestion(_ item: QueueItem) async {
        Haptics.tap()
        player.keepSuggestion(item.id)
        if let playlist = item.collectionID.split(separator: ":").last.flatMap({ Int($0) }),
            item.collectionID.hasPrefix("online.playlist:")
        {
            _ = try? await database.addOnlineTrack(OnlinePlaylistTrack(opid: playlist, track: item.track))
            messages.show(L10n.addedtoplaylist, systemImage: "text.badge.plus")
            libraryChanged()
        } else if !favouriteIDs.contains(item.stid) {
            await toggleFavourite(item.track)
        }
    }

    func toggleFavourite(_ track: Track) async {
        guard let added = try? await database.toggleFavourite(Favourite(track: track)) else { return }
        messages.show(
            added ? L10n.trackisnowafavourite : L10n.trackremovedfromfavourites,
            systemImage: added ? "heart.fill" : "heart.slash")
        libraryChanged()
    }

    func download(_ track: Track) async {
        do {
            let outcome = try await downloads.download(track)
            messages.show(
                outcome == .downloaded ? L10n.successfullydownloadedthetrack : L10n.trackalreadydownloaded,
                systemImage: "arrow.down.circle")
            libraryChanged()
        } catch {
            messages.show(L10n.downloadfailed, systemImage: "exclamationmark.triangle", isError: true)
        }
    }

    /// Opens the playlist picker for [tracks]; offline playlists download the
    /// tracks that aren't on the device first.
    func addToPlaylist(_ tracks: [Track], kind: PlaylistKind = .online, creating: Bool = false) async {
        guard !tracks.isEmpty else { return }
        var request = PlaylistRequest(kind: kind, tracks: tracks, creating: creating)
        if kind == .offline {
            request.toDownload = (try? await database.missingDownloads(tracks.map(\.id))) ?? []
        }
        playlistRequest = request
    }

    /// Adds [query] to the search history.
    func rememberSearch(_ query: String) {
        let query = query.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return }
        Task {
            try? await database.addSearch(query)
            libraryChanged()
        }
    }

    /// Shows the artist with [ref] on the current tab.
    func showArtist(_ ref: ArtistRef) async {
        guard let artist = try? await catalog.artist(id: ref.id, name: ref.name ?? "") else { return }
        router.show(.artist(artist))
    }

    /// Shows the album with [id] on the current tab.
    func showAlbum(_ id: String) async {
        guard let album = try? await catalog.album(id) else { return }
        router.show(.album(album))
    }

    func shazam(_ stid: String) async {
        do {
            let match = try await catalog.shazam(stid)
            messages.show("\(match.title) – \(match.subtitle)", systemImage: "shazam.logo")
        } catch {
            messages.show(L10n.shazamfailed, systemImage: "exclamationmark.triangle", isError: true)
        }
    }

    private func show(_ message: PlayerMessage) {
        switch message {
        case .keepAppOpen: messages.show(L10n.donotterminatetheapp, systemImage: "moon.zzz", isError: true)
        case .sleepAlarmEnabled: messages.show(L10n.sleepalarmisenabled, systemImage: "alarm", isError: true)
        case .cannotHaltDuringSleepAlarm:
            messages.show(
                L10n.unabletohaltthemusicplayerbecausesleepalarmiscurrentlyon, systemImage: "alarm", isError: true)
        case .repeatChanged(let mode):
            switch mode {
            case .off: messages.show(L10n.repeatoff, systemImage: "repeat")
            case .all: messages.show(L10n.repeatthequeue, systemImage: "repeat")
            case .one: messages.show(L10n.repeatthissong, systemImage: "repeat.1")
            }
        case .trackUnavailable: messages.show(L10n.trackunavailable, systemImage: "exclamationmark.triangle", isError: true)
        case .serverUnreachable:
            messages.show(L10n.serverunreachable, detail: L10n.downloadsstillplay, systemImage: "wifi.slash", isError: true)
        }
    }

    private func show(_ notice: ListenNotice) {
        switch notice {
        case .notAllowed: messages.show(L10n.notallowedinsession, systemImage: "hand.raised", isError: true)
        case .notFound: messages.show(L10n.sessionnotfound, systemImage: "person.2.slash", isError: true)
        case .full: messages.show(L10n.sessionfull, systemImage: "person.2.slash", isError: true)
        case .connectionLost: messages.show(L10n.sessionconnectionlost, systemImage: "wifi.slash", isError: true)
        case .nowHosting: messages.show(L10n.nowhosting, systemImage: "crown")
        case .voted(let count, let needed):
            messages.show("\(L10n.votedtoskip) · \(count)/\(needed)", systemImage: "forward")
        case .hostChanged(let name): messages.show("\(L10n.hostisnow) \(name)", systemImage: "crown")
        case .suggested(let title): messages.show(L10n.suggestedtohost, detail: title, systemImage: "lightbulb")
        case .suggestionAnswered(let title, let accepted):
            messages.show(
                accepted ? L10n.suggestionadded : L10n.suggestiondeclined, detail: title,
                systemImage: accepted ? "checkmark.circle" : "xmark.circle")
        }
    }
}

/// Appends what a sleep alarm does to `sleep_alarm.log` in the documents
/// directory. Alarms run while the phone is locked, where no debugger can
/// follow them, so the log shows why one didn't wake the user.
final class SleepAlarmLog {
    private let file = URL.documentsDirectory.appending(path: "sleep_alarm.log")

    func add(_ message: String) {
        if message.hasPrefix("start ") { try? Data().write(to: file) }
        let line = Data("\(Date().ISO8601Format()) \(message)\n".utf8)
        if let handle = try? FileHandle(forWritingTo: file) {
            handle.seekToEndOfFile()
            handle.write(line)
            try? handle.close()
        } else {
            try? line.write(to: file)
        }
    }
}
