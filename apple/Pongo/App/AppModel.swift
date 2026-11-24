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
    let imports: PlaylistImports
    let versions: TrackVersionsRepository
    let social: SocialRepository
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
    /// The track whose recordings the version picker shows.
    var versionRequest: Track?
    /// Whether the screen of listening together shows.
    var showsListenTogether = false
    /// Friends asking the user to listen along, oldest first; the first one
    /// is asked about.
    private(set) var invites: [ListenInvite] = []
    /// Invitations the user answered, which a later check may still return.
    @ObservationIgnored private var answeredInvites: Set<String> = []
    @ObservationIgnored private var inviteWatcher: Task<Void, Never>?
    private(set) var favouriteIDs: Set<String> = []
    private(set) var downloadedIDs: Set<String> = []
    /// Tracks waiting for or in the middle of downloading.
    private(set) var downloadingIDs: Set<String> = []
    /// Every track of the downloads running now, done or not, so a page can
    /// tell how far along its own tracks are; empties once all are done.
    private(set) var downloadBatch: Set<String> = []
    private var localRevision = 0

    /// Grows whenever the library changed, here or through a sync, so screens
    /// showing it reload.
    var libraryRevision: Int { localRevision + sync.revision }

    /// Where the server the user typed in is kept; without one the app uses
    /// the address it was built with.
    static let serverKey = "PONGOSERVERURL"
    /// The addresses the app was built with, empty in builds made for anyone.
    static var builtInServers: [String] {
        let info = Bundle.main.infoDictionary ?? [:]
        return [info["PongoServerURL"] as? String ?? "", info["PongoLocalServerURL"] as? String ?? ""]
            .filter { !$0.isEmpty }
    }
    /// Whether the app knows a server to connect to.
    private(set) var hasServer: Bool
    /// The address of the server the user picked, nil when it's the built-in one.
    private(set) var chosenServer: String?
    /// Whether the sign-in screen opens on picking another server.
    var editServerOnSignIn = false

    init() throws {
        let info = Bundle.main.infoDictionary ?? [:]
        let chosen = UserDefaults.standard.string(forKey: Self.serverKey)
        let servers = chosen.map { [$0] } ?? Self.builtInServers
        chosenServer = chosen
        hasServer = !servers.isEmpty
        config = AppConfig(
            serverURL: servers.first ?? "", fallbackServerURLs: Array(servers.dropFirst()),
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
        imports = PlaylistImports(client: client, database: database, messages: messages)
        versions = TrackVersionsRepository(client: client)
        social = SocialRepository(client: client)
        sync = LibrarySync(
            client: client, store: database, sources: [database, SettingsSyncSource(settings: settings)])
        L10n.selectedLanguage = settings.settings.locale
        configurePlayer()
        #if DEBUG
            if DemoMode.isOn { DemoMode.seed(store: DefaultsStore(), database: database) }
        #endif
        player.restoreState()
        Task { await config.servers.choose() }
        Task { await reloadLibraryIDs() }
        #if os(iOS)
            liveLyrics = LiveLyricsController(model: self)
            liveLyrics?.start()
        #endif
        widgets = WidgetPublisher(model: self)
        widgets?.start()
        imports.changed = { [weak self] in self?.libraryChanged() }
        Self.current = self
    }

    private func configurePlayer() {
        applyPreferences()
        player.onMessage = { [weak self] message in self?.show(message) }
        listening.onNotice = { [weak self] notice in self?.show(notice) }
        listening.delay =
            UserDefaults.standard.object(forKey: ListeningSession.delayKey) as? Double ?? ListeningSession.defaultDelay
        listening.onInvite = { [weak self] invite in self?.received([invite]) }
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
            watchInvites()
            await sync.start()
        } else {
            inviteWatcher?.cancel()
            inviteWatcher = nil
            invites = []
            // A session is someone's own; another account starts without it
            if listening.isActive { listening.leave() }
            #if DEBUG
                if DemoMode.isOn { return }
            #endif
            player.halt()
            await clearLibrary()
        }
    }

    // MARK: - Inviting friends to listen together

    /// Asks every so often whether friends invited the user to listen along,
    /// which the app can only learn by asking while it isn't in a session.
    private func watchInvites() {
        inviteWatcher?.cancel()
        inviteWatcher = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                await self.checkInvites()
                try? await Task.sleep(for: .seconds(20))
            }
        }
    }

    func checkInvites() async {
        guard auth.isSignedIn, let open = try? await social.invites() else { return }
        // Gone ones were answered elsewhere or the session ended
        invites.removeAll { invite in !open.contains { $0.session == invite.session } }
        received(open)
    }

    private func received(_ new: [ListenInvite]) {
        for invite in new.reversed()
        where !answeredInvites.contains(invite.session) && !invites.contains(where: { $0.session == invite.session })
            && invite.session != listening.code
        {
            invites.append(invite)
        }
    }

    /// Joins the session the friend invited the user to, or declines it.
    func answer(_ invite: ListenInvite, accept: Bool) {
        answeredInvites.insert(invite.session)
        invites.removeAll { $0.session == invite.session }
        let social = social
        Task { try? await social.answer(invite.session, accept: accept) }
        guard accept else { return }
        // Joining one session declines the others
        for other in invites {
            answeredInvites.insert(other.session)
            Task { try? await social.answer(other.session, accept: false) }
        }
        invites = []
        Haptics.tap()
        listening.join(invite.session)
        showsListenTogether = true
    }

    /// Asks [person] to listen along: in the session the user is in, or a new
    /// one the user hosts, where guests may add songs and vote to skip.
    func inviteToListen(_ person: Person) async {
        if !listening.isActive {
            let rights = UserDefaults.standard.stringArray(forKey: Self.lastRightsKey)
                .map { Set($0.compactMap(ListenRight.init(rawValue:))) } ?? ListenPreset.party.rights
            listening.host(rights: rights)
        }
        // A new session has its code once the server answered
        for _ in 0..<50 where listening.code == nil && listening.isActive {
            try? await Task.sleep(for: .milliseconds(200))
        }
        guard let code = listening.code else {
            messages.show(L10n.serverunreachable, systemImage: "wifi.slash", isError: true)
            return
        }
        do {
            try await social.invite(person.code, to: code)
            Haptics.tap()
            messages.show(L10n.invitesent, detail: person.name, systemImage: "paperplane")
        } catch APIError.status(403, _) {
            messages.show(L10n.invitenotfriends, systemImage: "person.crop.circle.badge.xmark", isError: true)
        } catch {
            messages.show(L10n.invitefailed, systemImage: "exclamationmark.triangle", isError: true)
        }
    }

    /// Where the rights the user last started a session with are kept.
    static let lastRightsKey = "listenTogetherRights"

    /// Connects to the server at [url], or back to the built-in one when nil.
    /// A session belongs to one server, so this signs out first.
    func setServer(_ url: String?) async {
        if auth.isSignedIn { await signOut() }
        let servers = url.map { [$0] } ?? Self.builtInServers
        if let url {
            UserDefaults.standard.set(url, forKey: Self.serverKey)
        } else {
            UserDefaults.standard.removeObject(forKey: Self.serverKey)
        }
        chosenServer = url
        config.servers.replace(with: servers)
        hasServer = !servers.isEmpty
    }

    /// Signs out and asks for another server on the sign-in screen.
    func changeServer() async {
        editServerOnSignIn = true
        await signOut()
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

    /// How many of [stids] that are being downloaded are done, and of how
    /// many, while any of them still are.
    func downloadProgress(of stids: [String]) -> (done: Int, total: Int)? {
        guard !downloadingIDs.isEmpty else { return nil }
        let batch = stids.filter(downloadBatch.contains)
        let waiting = batch.filter(downloadingIDs.contains).count
        guard waiting > 0 else { return nil }
        return (batch.count - waiting, batch.count)
    }

    private func startDownloading(_ stids: [String]) {
        downloadingIDs.formUnion(stids)
        downloadBatch.formUnion(stids)
    }

    private func finishedDownloading(_ stid: String) {
        downloadingIDs.remove(stid)
        if downloadingIDs.isEmpty { downloadBatch = [] }
    }

    /// Downloads [tracks] a few at a time, showing each one's progress, and
    /// returns whether any was saved; throws if every one failed.
    func downloadAll(_ tracks: [Track]) async throws -> Bool {
        let tracks = tracks.filter { !downloadingIDs.contains($0.id) }
        startDownloading(tracks.map(\.id))
        defer { tracks.forEach { finishedDownloading($0.id) } }
        return try await downloads.downloadAll(tracks.map { (track: $0, cover: String?.none) }) { [weak self] stid, saved in
            guard let self else { return }
            self.finishedDownloading(stid)
            if saved { self.downloadedIDs.insert(stid) }
        }
    }

    /// Adds [tracks] to the playlist with [id], downloading those in
    /// [toDownload] first for an offline playlist, and says how it went.
    func addTracks(_ tracks: [Track], kind: PlaylistKind, toDownload: [String], to id: Int) async {
        if kind == .offline, !toDownload.isEmpty {
            messages.show(L10n.downloadhasstarted, systemImage: "arrow.down.circle")
            do {
                guard try await downloadAll(tracks.filter { toDownload.contains($0.id) }) else { return }
                messages.show(L10n.downloadsucceeded, systemImage: "arrow.down.circle")
            } catch {
                messages.show(L10n.downloadfailed, systemImage: "exclamationmark.triangle", isError: true)
                return
            }
        }
        var added = 0
        for track in tracks {
            let new =
                kind == .online
                ? (try? await database.addOnlineTrack(OnlinePlaylistTrack(opid: id, track: track))) ?? false
                : (try? await database.addLocalTrack(id, track.id)) ?? false
            if new { added += 1 }
        }
        // A download's own message says enough
        if toDownload.isEmpty || kind == .online {
            if added == 0 {
                messages.show(L10n.playlistalreadycontainsthistrack, systemImage: "bookmark.fill")
            } else {
                messages.show(L10n.successful, systemImage: "text.badge.checkmark")
            }
        }
        libraryChanged()
    }

    func download(_ track: Track) async {
        guard !downloadingIDs.contains(track.id) else { return }
        startDownloading([track.id])
        defer { finishedDownloading(track.id) }
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
    /// tracks that aren't on the device first. Tracks the server can't get are
    /// left out, since they could never play from the playlist.
    func addToPlaylist(_ tracks: [Track], kind: PlaylistKind = .online, creating: Bool = false) async {
        let tracks = await playable(tracks)
        guard !tracks.isEmpty else { return }
        var request = PlaylistRequest(kind: kind, tracks: tracks, creating: creating)
        if kind == .offline {
            request.toDownload = (try? await database.missingDownloads(tracks.map(\.id))) ?? []
        }
        playlistRequest = request
    }

    /// [tracks] without those that can't be played here or fetched by the
    /// server; says which were left out.
    private func playable(_ tracks: [Track]) async -> [Track] {
        guard !tracks.isEmpty else { return [] }
        // Files on the device and downloaded songs play without the server
        let notDownloaded = Set((try? await database.missingDownloads(tracks.map(\.id))) ?? tracks.map(\.id))
        let unchecked = tracks.filter { $0.audioPath == nil && notDownloaded.contains($0.id) }
        guard !unchecked.isEmpty else { return tracks }
        let onServer = (try? await catalog.availability(unchecked.map(\.id)))?.durations ?? [:]
        let toFetch = Array(Set(unchecked.map(\.id)).subtracting(onServer.keys))
        guard !toFetch.isEmpty else { return tracks }
        messages.show(L10n.checkingsongs, systemImage: "hourglass")
        // As many at once as the server downloads
        let socket = socket
        let unavailable = await withTaskGroup(of: String?.self) { group in
            var failed = Set<String>()
            var next = toFetch.makeIterator()
            for _ in 0..<4 {
                guard let stid = next.next() else { break }
                group.addTask { await socket.ensureAvailable(stid) == .unavailable ? stid : nil }
            }
            while let result = await group.next() {
                if let result { failed.insert(result) }
                if let stid = next.next() {
                    group.addTask { await socket.ensureAvailable(stid) == .unavailable ? stid : nil }
                }
            }
            return failed
        }
        if messages.current?.text == L10n.checkingsongs { messages.dismiss() }
        guard !unavailable.isEmpty else { return tracks }
        let names = tracks.filter { unavailable.contains($0.id) }.map(\.name)
        let shown = names.prefix(2).joined(separator: ", ") + (names.count > 2 ? " +\(names.count - 2)" : "")
        messages.show(L10n.notaddedunavailable, detail: shown, systemImage: "exclamationmark.triangle", isError: true)
        return tracks.filter { !unavailable.contains($0.id) }
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
        case .inviteAnswered(let name, let accepted):
            messages.show(
                accepted ? L10n.inviteaccepted : L10n.invitedeclined, detail: name,
                systemImage: accepted ? "person.crop.circle.badge.checkmark" : "person.crop.circle.badge.xmark")
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
