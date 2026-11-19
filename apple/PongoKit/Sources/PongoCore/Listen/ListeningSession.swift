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
        case .party: [.add]
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

/// Something about the session to tell the user.
public enum ListenNotice: Sendable, Equatable {
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

    @ObservationIgnored public var onNotice: ((ListenNotice) -> Void)?

    public var isActive: Bool { state != .idle }
    public var isHost: Bool { userID != nil && userID == hostID }
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
    /// The host's latest playback.
    @ObservationIgnored private var playback: Playback?
    @ObservationIgnored private var lastCorrection = Date.distantPast
    /// The server's clock less this device's, and how sure of it the
    /// measurement was.
    @ObservationIgnored private var clockOffset: Double = 0
    @ObservationIgnored private var bestRoundTrip = Double.infinity

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
        Task { try? await socket?.send(Self.message(["type": "leave"])) }
        end()
    }

    private func start(_ how: Start) {
        if isActive { leave() }
        state = .connecting
        connection = Task { [weak self] in await self?.run(how) }
        timers = Task { [weak self] in await self?.tick() }
    }

    private func end() {
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
            try await socket.send(Self.message(first))
            ping()
            var wasLive = false
            while !Task.isCancelled {
                let text: String
                switch try await socket.receive() {
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
        Task { try? await socket.send(message) }
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
            playback = Playback(
                entry: entry, position: message["position"] as? Double ?? 0,
                playing: message["playing"] as? Bool ?? false, at: message["at"] as? Double ?? serverNow)
            follow()
        case "request":
            guard isHost, let request = Self.decode(PlayerRequest.self, message["request"]) else { return }
            apply(request, from: message["from"] as? String)
        case "denied":
            onNotice?(.notAllowed)
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
        hasher.combine(queue.shuffleOrder)
        hasher.combine(queue.shuffleEnabled)
        hasher.combine(queue.repeatMode)
        let signature = hasher.finalize()
        guard signature != publishedQueue, let snapshot = Self.json(queue.snapshot(position: 0)) else { return }
        publishedQueue = signature
        send(["type": "queue", "snapshot": snapshot])
    }

    private func publishPlayback() {
        guard isHost, let current = player.current else { return }
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

    /// Takes what the user does to the player while following the host.
    private func intercept(_ request: PlayerRequest) -> Bool {
        let allowed = Self.needed(request).map(rights.contains) ?? false
        switch request {
        case .halt:
            // Stopping leaves the session, and stops here
            leave()
            return false
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
        let target = playback.position + elapsed
        // Past its end, the host's player is already moving on and will say so
        if let item = player.queue.items.first(where: { $0.id == playback.entry }), item.duration > 0,
            target > item.duration - 0.5
        {
            return
        }
        if player.current?.id != playback.entry || player.isPlaying != playback.playing {
            lastCorrection = Date()
            player.follow(entry: playback.entry, position: target, playing: playback.playing, tolerance: 0.3)
            return
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
