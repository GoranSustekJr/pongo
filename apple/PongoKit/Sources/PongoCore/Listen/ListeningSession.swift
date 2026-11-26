import Foundation
import Observation

/// What a host lets guests do while listening together.
public enum ListenRight: String, CaseIterable, Sendable, Codable {
    /// Add songs to play next or last.
    case add
    /// Play, pause, skip and seek.
    case playback
    /// Remove and reorder songs.
    case manage
    /// Change shuffle and repeat.
    case modes
    /// Start a playlist, album or mix in place of the queue.
    case takeover
    /// Vote to skip the song playing, which goes once most listeners did.
    case vote
}

/// Sets of rights a host picks from when starting a session.
public enum ListenPreset: String, CaseIterable, Sendable {
    /// Guests follow along and do nothing else.
    case listenAlong
    /// Guests add songs.
    case party
    /// Guests do everything the host does.
    case coPilot

    public var rights: Set<ListenRight> {
        switch self {
        case .listenAlong: []
        case .party: [.add, .vote]
        case .coPilot: Set(ListenRight.allCases)
        }
    }

    /// The preset with exactly [rights], if any.
    public static func matching(_ rights: Set<ListenRight>) -> ListenPreset? {
        allCases.first { $0.rights == rights }
    }
}

/// Someone in a session.
public struct Listener: Identifiable, Sendable, Equatable {
    /// Their user ID.
    public var id: String
    public var name: String
    public var picture: String
    /// Whether they're connected; someone who dropped has a while to come back.
    public var isPresent: Bool
    public var rights: Set<ListenRight>
    /// Whether the host gave them rights of their own.
    public var hasOwnRights: Bool
}

/// Who voted to skip the song playing, and how many votes skip it.
public struct SkipVotes: Sendable, Equatable {
    public var voters: [String]
    public var needed: Int
}

/// An emoji someone sent, floating up on everyone's player for a moment.
public struct ListenReaction: Sendable, Equatable, Identifiable {
    public var id = UUID()
    /// The user ID of who sent it.
    public var from: String
    public var emoji: String
}

/// A song a guest would like added, waiting for the host to decide.
public struct SongSuggestion: Sendable, Equatable, Identifiable {
    public var id = UUID()
    /// The user ID of who suggested it.
    public var from: String
    public var track: Track
    public var next: Bool
}

/// What played in a session that ended, to keep as a playlist.
public struct SessionRecap: Sendable, Equatable, Identifiable {
    public struct Song: Sendable, Equatable {
        public var track: Track
        /// The name of who added it, if a guest did.
        public var addedBy: String?
    }

    public var id = UUID()
    public var songs: [Song]
    /// The names of everyone else who listened.
    public var listeners: [String]
    public var started: Date
}

/// Something about the session to tell the user.
public enum ListenNotice: Sendable, Equatable {
    /// The user's suggestion went to the host.
    case suggested(String)
    /// The host added the song the user suggested, or didn't.
    case suggestionAnswered(String, accepted: Bool)
    /// The user's vote to skip counted; this many of so many voted.
    case voted(Int, Int)
    /// The host didn't let guests do that.
    case notAllowed
    case notFound
    case full
    /// The server couldn't be reached for a while, so the session ended here.
    case connectionLost
    /// The host passed the session to the user, or left it to them.
    case nowHosting
    /// Someone else hosts the session now.
    case hostChanged(String)
    /// The friend the user asked to listen along joined, or said no.
    case inviteAnswered(String, accepted: Bool)
}

/// Listening together: one person's queue plays on everyone's devices, each
/// on their own account and headphones.
///
/// The host's player publishes its queue and where it is in it through the
/// server; guests' players follow, and what guests do to their player goes to
/// the host as a request, which the server lets through if the host allowed
/// it. A guest may still pause just for themselves, and catches up when they
/// play again.
@MainActor
@Observable
public final class ListeningSession {
    public enum State: Sendable, Equatable {
        case idle
        case connecting
        case live
        /// The connection dropped and is being made again.
        case reconnecting
    }

    public private(set) var state = State.idle
    /// The code others join with.
    public private(set) var code: String?
    public private(set) var hostID: String?
    /// The signed in user's ID, as the server knows them.
    public private(set) var userID: String?
    /// Everyone in the session in the order they joined, the host included.
    public private(set) var listeners: [Listener] = []
    /// What guests without rights of their own may do.
    public private(set) var guestRights: Set<ListenRight> = []
    /// Whether the user paused just for themselves while following.
    public private(set) var isPausedHere = false
    /// The votes to skip the song playing, if anyone voted.
    public private(set) var skipVotes: SkipVotes?
    /// Reactions sent in the last few seconds, oldest first.
    public private(set) var reactions: [ListenReaction] = []
    /// Songs guests suggested, which the host adds or declines.
    public private(set) var suggestions: [SongSuggestion] = []
    /// What played in the session that just ended, until it's dismissed.
    public private(set) var recap: SessionRecap?
    /// Seconds a guest's player runs ahead of the host's, to make up for
    /// headphones that play late, such as Bluetooth ones; negative plays
    /// behind. Guests play a little behind unless the user set it, so the host
    /// hears the music, and what they change, first.
    public var delay: Double = ListeningSession.defaultDelay {
        didSet {
            lastCorrection = .distantPast
            measuredLag = nil
            follow()
        }
    }

    /// How far behind the host a guest plays unless they set otherwise.
    public static let defaultDelay = -0.25

    /// How many seconds behind the host's player the user's actually is, as
    /// measured while following; negative is ahead.
    public private(set) var measuredLag: Double?
    /// How long news takes from the server to the user, one way, as the
    /// quickest answer to a ping measured it.
    public var networkDelay: Double? { bestRoundTrip.isFinite ? bestRoundTrip / 2 : nil }

    /// The emoji listeners can react with.
    public static let reactionEmoji = ["🔥", "❤️", "😂", "😮", "🙌", "💃"]

    @ObservationIgnored public var onNotice: ((ListenNotice) -> Void)?
    /// Called when a friend asks the user to join their session, while the
    /// user is in another.
    @ObservationIgnored public var onInvite: ((ListenInvite) -> Void)?

    public var isActive: Bool { state != .idle }
    public var isHost: Bool { userID != nil && userID == hostID }
    /// A link that opens the app and joins the session.
    public var joinLink: URL? { code.flatMap { URL(string: "pongo://join/\($0)") } }

    /// The session code in a join link.
    public static func code(in link: URL) -> String? {
        guard link.scheme == "pongo", link.host() == "join" else { return nil }
        let code = link.lastPathComponent.uppercased().filter { $0.isLetter || $0.isNumber }
        return code.isEmpty ? nil : code
    }
    public var host: Listener? { listeners.first { $0.id == hostID } }

    /// What the user may do.
    public var rights: Set<ListenRight> {
        isHost ? Set(ListenRight.allCases) : listeners.first { $0.id == userID }?.rights ?? []
    }

    public func listener(_ id: String?) -> Listener? {
        listeners.first { $0.id == id }
    }

    @ObservationIgnored private let client: APIClient
    @ObservationIgnored private let player: Player
    @ObservationIgnored private let urlSession: URLSession
    @ObservationIgnored private var socket: URLSessionWebSocketTask?
    @ObservationIgnored private var connection: Task<Void, Never>?
    @ObservationIgnored private var timers: Task<Void, Never>?
    @ObservationIgnored private var publishTask: Task<Void, Never>?
    /// The role the player was set up for.
    @ObservationIgnored private var hosting: Bool?
    /// Whether this connection still has to publish the queue, as a host.
    @ObservationIgnored private var mustPublish = true
    @ObservationIgnored private var publishedQueue: Int?
    @ObservationIgnored private var publishedEntry: UUID?
    /// The host's latest playback.
    @ObservationIgnored private var playback: Playback?
    @ObservationIgnored private var lastCorrection = Date.distantPast
    /// The server's clock less this device's, and how sure of it the
    /// measurement was.
    @ObservationIgnored private var clockOffset: Double = 0
    private var bestRoundTrip = Double.infinity
    /// Whether the user just voted, so the count that comes back is told.
    @ObservationIgnored private var justVoted = false
    /// What played, for the recap, and who else was there.
    @ObservationIgnored private var played: [SessionRecap.Song] = []
    @ObservationIgnored private var playedEntry: UUID?
    @ObservationIgnored private var others: [String: String] = [:]
    @ObservationIgnored private var started = Date()

    private struct Playback {
        var entry: UUID
        var position: Double
        var playing: Bool
        /// The server time the position was measured at.
        var at: Double
    }

    private enum Start {
        case create(Set<ListenRight>)
        case join(String)
    }

    private enum Ending {
        case dropped
        case refused(String)
        case left
    }

    public init(client: APIClient, player: Player, urlSession: URLSession = .shared) {
        self.client = client
        self.player = player
        self.urlSession = urlSession
    }

    // MARK: - Starting and leaving

    /// Starts a session others can join, letting guests do [rights].
    public func host(rights: Set<ListenRight>) {
        start(.create(rights))
    }

    /// Joins the session with [code].
    public func join(_ code: String) {
        let code = code.uppercased().filter { $0.isLetter || $0.isNumber }
        guard !code.isEmpty else { return }
        start(.join(code))
    }

    /// Leaves the session; the music plays on here on its own.
    public func leave() {
        let socket = socket
        Task { try? await socket?.sendOnce(Self.message(["type": "leave"])) }
        end()
    }

    private func start(_ how: Start) {
        if isActive { leave() }
        played = []
        playedEntry = nil
        others = [:]
        started = Date()
        recap = nil
        state = .connecting
        connection = Task { [weak self] in await self?.run(how) }
        timers = Task { [weak self] in await self?.tick() }
    }

    private func end() {
        if played.count >= 2 {
            recap = SessionRecap(songs: played, listeners: others.values.sorted(), started: started)
        }
        played = []
        suggestions = []
        connection?.cancel()
        timers?.cancel()
        publishTask?.cancel()
        socket?.cancel(with: .normalClosure, reason: nil)
        socket = nil
        player.remote = nil
        player.addingAs = nil
        player.onPlaybackChanged = nil
        state = .idle
        code = nil
        hostID = nil
        listeners = []
        guestRights = []
        hosting = nil
        playback = nil
        publishedQueue = nil
        isPausedHere = false
        skipVotes = nil
        reactions = []
        justVoted = false
        measuredLag = nil
    }

    // MARK: - The connection

    private func run(_ first: Start) async {
        var how = first
        var drops = 0
        var renewed = false
        while !Task.isCancelled {
            let ending = await connect(how)
            guard !Task.isCancelled else { return }
            switch ending {
            case .left:
                return
            case .refused("expired") where !renewed:
                renewed = true
                _ = await client.tokens?.refreshSession()
                continue
            case .refused(let error):
                onNotice?(error == "notfound" ? (code == nil ? .notFound : .connectionLost) : error == "full" ? .full : .connectionLost)
                end()
                return
            case .dropped:
                // About as long as the server waits for someone to come back
                drops += 1
                guard let code, drops <= 12 else {
                    onNotice?(.connectionLost)
                    end()
                    return
                }
                how = .join(code)
                state = .reconnecting
                try? await Task.sleep(for: .seconds(2.5))
            }
        }
    }

    private func connect(_ how: Start) async -> Ending {
        let socket = urlSession.webSocketTask(with: URL(string: client.config.socketURL + "listen")!)
        // A long queue is the largest message
        socket.maximumMessageSize = 4_000_000
        socket.resume()
        self.socket = socket
        mustPublish = true
        bestRoundTrip = .infinity
        defer { socket.cancel(with: .normalClosure, reason: nil) }
        var first: [String: Any] = ["at+JWT": await client.tokens?.accessToken() ?? ""]
        switch how {
        case .create(let rights): first["create"] = ["rights": rights.map(\.rawValue).sorted()]
        case .join(let code): first["join"] = code
        }
        do {
            try await socket.sendOnce(Self.message(first))
            ping()
            var wasLive = false
            while !Task.isCancelled {
                let text: String
                switch try await socket.receiveOnce() {
                case .string(let string): text = string
                case .data(let data): text = String(decoding: data, as: UTF8.self)
                @unknown default: continue
                }
                guard
                    let message = try? JSONSerialization.jsonObject(with: Data(text.utf8)) as? [String: Any],
                    let type = message["type"] as? String
                else { continue }
                if type == "error" { return .refused(message["error"] as? String ?? "") }
                if type == "session" && !wasLive {
                    wasLive = true
                    // Clock samples taken while connecting are rough; these come back quickly
                    for delay in [0.4, 0.9, 1.6] {
                        Task { [weak self] in
                            try? await Task.sleep(for: .seconds(delay))
                            self?.ping()
                        }
                    }
                }
                handle(type, message)
            }
            return .left
        } catch {
            return Task.isCancelled ? .left : .dropped
        }
    }

    private func send(_ object: [String: Any]) {
        guard let socket else { return }
        let message = Self.message(object)
        Task { try? await socket.sendOnce(message) }
    }

    private static func message(_ object: [String: Any]) -> URLSessionWebSocketTask.Message {
        let data = (try? JSONSerialization.data(withJSONObject: object)) ?? Data("{}".utf8)
        return .string(String(decoding: data, as: UTF8.self))
    }

    /// [value] as the JSON object it encodes to, to put in a message.
    private static func json(_ value: some Encodable) -> Any? {
        guard let data = try? JSONEncoder().encode(value) else { return nil }
        return try? JSONSerialization.jsonObject(with: data)
    }

    private static func decode<T: Decodable>(_ type: T.Type, _ object: Any?) -> T? {
        guard let object, let data = try? JSONSerialization.data(withJSONObject: object) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    // MARK: - Messages

    private func handle(_ type: String, _ message: [String: Any]) {
        switch type {
        case "welcome":
            userID = message["uid"] as? String
        case "session":
            sessionChanged(message)
        case "queue":
            guard !isHost, let snapshot = Self.decode(PlaybackQueue.Snapshot.self, message["snapshot"]) else { return }
            player.follow(snapshot)
            follow()
        case "playback":
            guard !isHost, let entry = (message["entry"] as? String).flatMap(UUID.init(uuidString:)) else { return }
            if playback?.entry != entry { skipVotes = nil }
            playback = Playback(
                entry: entry, position: message["position"] as? Double ?? 0,
                playing: message["playing"] as? Bool ?? false, at: message["at"] as? Double ?? serverNow)
            follow()
        case "request":
            guard isHost, let request = Self.decode(PlayerRequest.self, message["request"]) else { return }
            apply(request, from: message["from"] as? String)
        case "denied":
            justVoted = false
            onNotice?(.notAllowed)
        case "votes":
            let voters = message["voters"] as? [String] ?? []
            let needed = message["needed"] as? Int ?? 0
            skipVotes = voters.isEmpty ? nil : SkipVotes(voters: voters, needed: needed)
            if justVoted {
                justVoted = false
                // An empty count after the vote means it skipped the song
                if !voters.isEmpty { onNotice?(.voted(voters.count, needed)) }
            }
        case "suggestion":
            guard isHost, let from = message["from"] as? String,
                case .add(let track, let next)? = Self.decode(PlayerRequest.self, message["request"]),
                suggestions.count < 50
            else { return }
            suggestions.append(SongSuggestion(from: from, track: track, next: next))
        case "invite":
            guard let invite = Self.invite(message["invite"]) else { return }
            onInvite?(invite)
        case "inviteAnswer":
            onNotice?(.inviteAnswered(message["name"] as? String ?? "", accepted: message["accepted"] as? Bool == true))
        case "answered":
            onNotice?(.suggestionAnswered(message["title"] as? String ?? "", accepted: message["accepted"] as? Bool == true))
        case "reaction":
            guard let from = message["from"] as? String, let emoji = message["emoji"] as? String else { return }
            show(ListenReaction(from: from, emoji: emoji))
        case "pong":
            guard let sent = message["t"] as? Double, let server = message["server"] as? Double else { return }
            let now = Date().timeIntervalSince1970
            let roundTrip = now - sent
            // The quickest answers measure the clock best
            if roundTrip <= bestRoundTrip + 0.01 {
                bestRoundTrip = min(bestRoundTrip, roundTrip)
                clockOffset = server - (sent + roundTrip / 2)
            }
        default:
            break
        }
    }

    private func sessionChanged(_ message: [String: Any]) {
        let previousHost = hostID
        code = message["code"] as? String
        hostID = message["host"] as? String
        guestRights = Self.rights(message["rights"])
        listeners = (message["members"] as? [[String: Any]] ?? []).compactMap { member in
            guard let id = member["uid"] as? String else { return nil }
            return Listener(
                id: id, name: member["name"] as? String ?? "", picture: member["picture"] as? String ?? "",
                isPresent: member["present"] as? Bool ?? false, rights: Self.rights(member["rights"]),
                hasOwnRights: member["custom"] as? Bool ?? false)
        }
        state = .live
        if let previousHost, previousHost != hostID {
            if isHost {
                onNotice?(.nowHosting)
            } else if let host {
                onNotice?(.hostChanged(host.name))
            }
        }
        setUpPlayer()
    }

    private static func invite(_ value: Any?) -> ListenInvite? {
        guard let value = value as? [String: Any], let data = try? JSONSerialization.data(withJSONObject: value),
            let json = try? JSONValue.decode(data)
        else { return nil }
        return ListenInvite(json: json)
    }

    private static func rights(_ value: Any?) -> Set<ListenRight> {
        Set((value as? [String] ?? []).compactMap(ListenRight.init(rawValue:)))
    }

    private var serverNow: Double { Date().timeIntervalSince1970 + clockOffset }

    private func ping() {
        send(["type": "ping", "t": Date().timeIntervalSince1970])
    }

    /// Clock samples and, as a host, where playback is, every so often; as a
    /// guest, keeps the player with the host's.
    private func tick() async {
        var seconds = 0
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(1))
            seconds += 1
            guard state == .live else { continue }
            if seconds % 15 == 0 { ping() }
            notePlayed()
            if isHost {
                if seconds % 5 == 0 && player.isPlaying { publishPlayback() }
            } else {
                follow()
            }
        }
    }

    // MARK: - Hosting

    private func setUpPlayer() {
        let host = isHost
        if host {
            if hosting != true || mustPublish {
                mustPublish = false
                player.remote = nil
                player.addingAs = userID
                player.onPlaybackChanged = { [weak self] in self?.publishPlayback() }
                publishedQueue = nil
                observeQueue()
                publishQueue()
                publishPlayback()
            }
        } else if hosting != false {
            player.remote = { [weak self] request in self?.intercept(request) ?? false }
            player.addingAs = nil
            player.onPlaybackChanged = nil
            publishTask?.cancel()
            isPausedHere = false
        }
        hosting = host
    }

    private func observeQueue() {
        withObservationTracking {
            _ = player.queue
        } onChange: { [weak self] in
            Task { @MainActor in
                guard let self, self.hosting == true else { return }
                self.queueChanged()
                self.observeQueue()
            }
        }
    }

    /// Publishes the queue a moment after it changed, so a playlist filling
    /// in track by track goes out a few times rather than for every track.
    private func queueChanged() {
        guard publishTask == nil else { return }
        publishTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled, let self else { return }
            self.publishTask = nil
            self.publishQueue()
        }
    }

    private func publishQueue() {
        let queue = player.queue
        // Moving on to the next entry changes the queue too, but playback says so
        var hasher = Hasher()
        for item in queue.items {
            hasher.combine(item.id)
            hasher.combine(item.isQueued)
            hasher.combine(item.addedBy)
            hasher.combine(item.duration)
        }
        hasher.combine(queue.playOrder)
        hasher.combine(queue.shuffleEnabled)
        hasher.combine(queue.repeatMode)
        let signature = hasher.finalize()
        guard signature != publishedQueue, let snapshot = Self.json(queue.snapshot(position: 0)) else { return }
        publishedQueue = signature
        send(["type": "queue", "snapshot": snapshot])
    }

    private func publishPlayback() {
        guard isHost, let current = player.current else { return }
        if publishedEntry != current.id {
            publishedEntry = current.id
            skipVotes = nil
        }
        send([
            "type": "playback", "entry": current.id.uuidString, "position": player.exactPosition,
            "playing": player.isPlaying, "at": serverNow,
        ])
    }

    /// Does what a guest asked for, which the server checked they may.
    private func apply(_ request: PlayerRequest, from guest: String?) {
        let player = player
        let queue = player.queue
        func index(_ id: UUID) -> Int? { queue.items.firstIndex { $0.id == id } }
        func local(_ tracks: [Track]) -> [Track] {
            tracks.map { track in
                var track = track
                track.audioPath = nil
                track.localImagePath = nil
                return track
            }
        }
        switch request {
        case .play: player.play()
        case .pause: player.pause()
        case .next: player.skipToNext()
        case .previous: player.skipToPrevious()
        case .seek(let seconds): player.seek(to: seconds)
        case .skip(let id): if let index = index(id) { player.skip(to: index) }
        case .add(let track, let next):
            let track = local([track])[0]
            Task {
                if next {
                    await player.addNext(track, collectionID: Self.collectionID, by: guest)
                } else {
                    await player.addLast(track, collectionID: Self.collectionID, by: guest)
                }
            }
        case .remove(let ids):
            player.remove(at: ids.compactMap(index).filter { $0 != queue.currentIndex })
        case .move(let from, let to):
            let order = queue.playOrder.count
            guard from.allSatisfy({ (0..<order).contains($0) }), (0...order).contains(to) else { return }
            player.move(fromOffsets: IndexSet(from), toOffset: to)
        case .playNext(let id): if let index = index(id) { player.playNext(at: index) }
        case .clearUpcoming: player.clearUpcoming()
        case .shuffle(let enabled): player.setShuffle(enabled)
        case .repeatMode(let mode): player.setRepeatMode(mode, announce: false)
        case .replace(let collectionID, let tracks, let index, let shuffle):
            Task { await player.playOnline(collectionID, local(tracks), durations: [:], index: index, shuffle: shuffle) }
        case .mix(let collectionID, let seeds, let mood):
            Task { await player.playMix(collectionID, seeds: local(seeds), mood: mood) }
        case .halt:
            break
        }
    }

    /// Where songs guests add were started from.
    public static let collectionID = "listen.together"

    // MARK: - Following

    /// The right [request] needs, as the server checks it.
    private static func needed(_ request: PlayerRequest) -> ListenRight? {
        switch request {
        case .play, .pause, .next, .previous, .seek, .skip: .playback
        case .add: .add
        case .remove, .move, .playNext, .clearUpcoming: .manage
        case .shuffle, .repeatMode: .modes
        case .replace, .mix: .takeover
        case .halt: nil
        }
    }

    // MARK: - Suggestions and the recap

    /// Adds the song [suggestion] is of, by who suggested it.
    public func accept(_ suggestion: SongSuggestion) {
        answer(suggestion, accepted: true)
        apply(.add(track: suggestion.track, next: suggestion.next), from: suggestion.from)
    }

    public func decline(_ suggestion: SongSuggestion) {
        answer(suggestion, accepted: false)
    }

    private func answer(_ suggestion: SongSuggestion, accepted: Bool) {
        suggestions.removeAll { $0.id == suggestion.id }
        send(["type": "answer", "to": suggestion.from, "accepted": accepted, "title": suggestion.track.name])
    }

    public func dismissRecap() {
        recap = nil
    }

    /// Keeps the song playing for the recap, once per entry.
    private func notePlayed() {
        for listener in listeners where listener.id != userID { others[listener.id] = listener.name }
        guard let current = player.current, current.id != playedEntry else { return }
        playedEntry = current.id
        let addedBy = current.addedBy.flatMap { $0 == userID ? nil : listener($0)?.name ?? others[$0] }
        played.append(SessionRecap.Song(track: current.track, addedBy: addedBy))
    }

    // MARK: - Votes and reactions

    /// Votes to skip the song playing.
    public func voteToSkip() {
        guard isActive else { return }
        justVoted = true
        send(["type": "vote"])
    }

    /// Sends [emoji] to everyone, and shows it here too.
    public func react(_ emoji: String) {
        guard isActive, Self.reactionEmoji.contains(emoji), let userID else { return }
        send(["type": "react", "emoji": emoji])
        show(ListenReaction(from: userID, emoji: emoji))
    }

    private func show(_ reaction: ListenReaction) {
        reactions.append(reaction)
        if reactions.count > 20 { reactions.removeFirst(reactions.count - 20) }
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(3))
            self?.reactions.removeAll { $0.id == reaction.id }
        }
    }

    /// Takes what the user does to the player while following the host.
    private func intercept(_ request: PlayerRequest) -> Bool {
        let allowed = Self.needed(request).map(rights.contains) ?? false
        switch request {
        case .halt:
            // Stopping leaves the session, and stops here
            leave()
            return false
        case .add(let track, _) where !allowed:
            // Without the right to add, adding asks the host
            guard let request = Self.json(request) else { return true }
            send(["type": "suggest", "request": request])
            onNotice?(.suggested(track.name))
            return true
        case .next where !allowed && rights.contains(.vote):
            // Without the right to skip, skipping is a vote to
            voteToSkip()
            return true
        case .play where !allowed:
            isPausedHere = false
            lastCorrection = .distantPast
            follow()
            return true
        case .pause where !allowed:
            isPausedHere = true
            player.pauseHere()
            return true
        case .play where isPausedHere:
            // Back in time with everyone, who may be playing already
            isPausedHere = false
            lastCorrection = .distantPast
            follow()
            if playback?.playing == true { return true }
        default:
            break
        }
        guard allowed else {
            onNotice?(.notAllowed)
            return true
        }
        guard let request = Self.json(request) else { return true }
        send(["type": "request", "request": request])
        return true
    }

    /// Keeps the player on the host's entry, playing or paused as theirs, and
    /// at their position, allowing for the time the news took.
    private func follow() {
        guard !isHost, !isPausedHere, let playback, player.queue.items.contains(where: { $0.id == playback.entry })
        else { return }
        let elapsed = playback.playing ? max(serverNow - playback.at, 0) : 0
        let target = playback.position + elapsed + delay
        // Past its end, the host's player is already moving on and will say so
        if let item = player.queue.items.first(where: { $0.id == playback.entry }), item.duration > 0,
            target > item.duration - 0.5
        {
            return
        }
        if player.current?.id != playback.entry || player.isPlaying != playback.playing {
            lastCorrection = Date()
            measuredLag = nil
            player.follow(entry: playback.entry, position: target, playing: playback.playing, tolerance: 0.3)
            return
        }
        // How far behind the host this player is, once a correction settled
        if playback.playing, !player.isBuffering, Date().timeIntervalSince(lastCorrection) > 1.5 {
            let lag = target - delay - player.exactPosition
            measuredLag = measuredLag.map { $0 * 0.7 + lag * 0.3 } ?? lag
        }
        // Drifting apart: a seek, but not again before the last one settled
        guard playback.playing, !player.isBuffering, Date().timeIntervalSince(lastCorrection) > 5,
            abs(player.exactPosition - target) > 0.3
        else { return }
        lastCorrection = Date()
        player.follow(entry: playback.entry, position: target, playing: true, tolerance: 0)
    }

    // MARK: - Rights and the host

    /// Lets guests without rights of their own do [rights].
    public func setGuestRights(_ rights: Set<ListenRight>) {
        sendRights(rights, overrides: ownRights())
    }

    /// Gives [guest] rights of their own, or `nil` for the everyone's.
    public func setRights(_ rights: Set<ListenRight>?, for guest: String) {
        var overrides = ownRights()
        overrides[guest] = rights
        sendRights(guestRights, overrides: overrides)
    }

    private func ownRights() -> [String: Set<ListenRight>] {
        Dictionary(uniqueKeysWithValues: listeners.filter(\.hasOwnRights).map { ($0.id, $0.rights) })
    }

    private func sendRights(_ rights: Set<ListenRight>, overrides: [String: Set<ListenRight>]) {
        guard isHost else { return }
        send([
            "type": "rights", "rights": rights.map(\.rawValue).sorted(),
            "overrides": overrides.mapValues { $0.map(\.rawValue).sorted() },
        ])
    }

    /// Makes [listener] the host; the user follows them from then on.
    public func handOver(to listener: String) {
        guard isHost else { return }
        send(["type": "handover", "to": listener])
    }
}
