import Foundation

/// Another of the user's devices that has the app open.
public struct LinkedDevice: Sendable, Hashable, Identifiable {
    public var id: String
    public var name: String

    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

/// What happened to a transfer, for the app to show.
public enum TransferNotice: Sendable, Equatable {
    /// The queue plays on the device with that name now.
    case sent(to: String)
    /// The queue of the device with that name plays here now.
    case received(from: String)
    case failed
}

/// Moves playback between the user's devices that have the app open.
///
/// While the app is open it keeps a socket to the server, which tells it
/// which of the user's other devices are open too. Transferring sends the
/// queue to one of them once; that device plays it on from the same moment
/// and answers, and this one pauses. A device can also ask another for its
/// queue, which the other then transfers to it.
@MainActor
@Observable
public final class PlaybackHandoff {
    /// The user's other open devices.
    public private(set) var devices: [LinkedDevice] = []
    /// The device a transfer is under way with, if any.
    public private(set) var busyWith: String?

    @ObservationIgnored public var onNotice: ((TransferNotice) -> Void)?
    /// Whether to stay connected and take transfers, such as only while
    /// signed in and not listening along with someone.
    @ObservationIgnored public var isEnabled: () -> Bool = { true }

    @ObservationIgnored private let client: APIClient
    @ObservationIgnored private let player: Player
    @ObservationIgnored private let name: String
    @ObservationIgnored private let urlSession = URLSession(configuration: .default)
    @ObservationIgnored private var loop: Task<Void, Never>?
    @ObservationIgnored private var socket: URLSessionWebSocketTask?
    @ObservationIgnored private var timeout: Task<Void, Never>?
    /// The transfer this device waits to hear the answer to.
    @ObservationIgnored private var pending: (id: String, device: LinkedDevice)?

    /// How long a transfer waits for the other device to answer.
    static let answerTimeout: Duration = .seconds(12)

    /// [name] is what the user's other devices call this one.
    public init(client: APIClient, player: Player, name: String) {
        self.client = client
        self.player = player
        self.name = name
    }

    /// Connects, and keeps reconnecting while the app runs.
    public func start() {
        guard loop == nil else { return }
        loop = Task { [weak self] in
            var failures = 0
            var renewed = false
            while !Task.isCancelled {
                guard let self, self.isEnabled() else {
                    try? await Task.sleep(for: .seconds(5))
                    continue
                }
                switch await self.connect() {
                case .expired where !renewed:
                    renewed = true
                    _ = await self.client.tokens?.refreshSession()
                    continue
                case .live:
                    failures = 0
                    renewed = false
                case .expired, .dropped:
                    failures += 1
                case .unsupported:
                    // A server from before transfers turns the socket away; asking often won't change that
                    self.devices = []
                    try? await Task.sleep(for: .seconds(300))
                    continue
                }
                self.devices = []
                try? await Task.sleep(for: .seconds(min(2 * failures + 1, 30)))
            }
        }
    }

    public func stop() {
        loop?.cancel()
        loop = nil
        socket?.cancel(with: .normalClosure, reason: nil)
        socket = nil
        devices = []
        finish()
    }

    /// Connects again at once, as when the app comes back to the front and
    /// its socket may have closed meanwhile.
    public func wake() {
        stop()
        start()
    }

    private enum Ending { case live, expired, dropped, unsupported }

    private func connect() async -> Ending {
        let socket = urlSession.webSocketTask(with: URL(string: client.config.socketURL + "devices")!)
        // A long queue is the largest message
        socket.maximumMessageSize = 8_000_000
        socket.resume()
        self.socket = socket
        defer {
            socket.cancel(with: .normalClosure, reason: nil)
            if self.socket === socket { self.socket = nil }
        }
        let first: [String: Any] = ["at+JWT": await client.tokens?.accessToken() ?? "", "name": name]
        // Keeps proxies from closing a quiet socket
        let pinger = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(25))
                self?.send(["type": "ping"])
            }
        }
        defer { pinger.cancel() }
        var wasLive = false
        do {
            try await socket.sendOnce(Self.message(first))
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
                if type == "error" { return message["error"] as? String == "expired" ? .expired : .dropped }
                wasLive = true
                handle(type, message)
            }
        } catch {
            if !wasLive, let status = (socket.response as? HTTPURLResponse)?.statusCode, [403, 404].contains(status) {
                return .unsupported
            }
        }
        return wasLive ? .live : .dropped
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

    // MARK: - Transfers

    /// Whether this device has something to transfer.
    public var canTransfer: Bool { player.handoffSnapshot() != nil && busyWith == nil }

    /// Sends the queue to [device], which plays it on from where it is here;
    /// this device pauses once it does.
    public func transfer(to device: LinkedDevice) {
        guard busyWith == nil else { return }
        sendQueue(to: device, id: UUID().uuidString)
    }

    private func sendQueue(to device: LinkedDevice, id: String) {
        guard isEnabled(), let snapshot = player.handoffSnapshot(),
            let data = try? JSONEncoder().encode(snapshot),
            let state = try? JSONSerialization.jsonObject(with: data)
        else {
            onNotice?(.failed)
            return
        }
        wait(for: id, from: device)
        send([
            "type": "transfer", "to": device.id, "id": id, "state": state,
            "position": player.exactPosition, "playing": player.isPlaying,
        ])
    }

    /// Asks [device] for its queue, which then plays here.
    public func requestQueue(from device: LinkedDevice) {
        guard busyWith == nil, isEnabled() else { return }
        let id = UUID().uuidString
        wait(for: id, from: device)
        send(["type": "request", "to": device.id, "id": id])
    }

    private func wait(for id: String, from device: LinkedDevice) {
        pending = (id, device)
        busyWith = device.id
        timeout?.cancel()
        timeout = Task { [weak self] in
            try? await Task.sleep(for: Self.answerTimeout)
            guard !Task.isCancelled, let self, self.pending?.id == id else { return }
            self.finish()
            self.onNotice?(.failed)
        }
    }

    private func finish() {
        pending = nil
        busyWith = nil
        timeout?.cancel()
        timeout = nil
    }

    private func handle(_ type: String, _ message: [String: Any]) {
        let id = message["id"] as? String
        let from = (message["from"] as? String).map {
            LinkedDevice(id: $0, name: message["from_name"] as? String ?? "")
        }
        switch type {
        case "devices":
            let you = message["you"] as? String
            devices = (message["devices"] as? [[String: Any]] ?? []).compactMap { entry in
                guard let id = entry["device_id"] as? String, id != you else { return nil }
                return LinkedDevice(id: id, name: entry["name"] as? String ?? "")
            }
            if let pending, !devices.contains(where: { $0.id == pending.device.id }) {
                finish()
                onNotice?(.failed)
            }
        case "transfer":
            guard let from, let id else { return }
            let taken = take(message)
            send(["type": "answer", "to": from.id, "id": id, "ok": taken])
            if taken {
                // Answers a request this device made, if it did
                if pending?.device.id == from.id { finish() }
                onNotice?(.received(from: from.name))
            }
        case "answer":
            guard let id, let pending, pending.id == id else { return }
            finish()
            if message["ok"] as? Bool == true {
                if player.isPlaying { player.pause() }
                onNotice?(.sent(to: pending.device.name))
            } else {
                onNotice?(.failed)
            }
        case "request":
            guard let from, let id else { return }
            if busyWith == nil, player.handoffSnapshot() != nil {
                sendQueue(to: from, id: id)
            } else {
                send(["type": "answer", "to": from.id, "id": id, "ok": false])
            }
        case "undelivered":
            guard let id, pending?.id == id else { return }
            finish()
            onNotice?(.failed)
        default:
            break
        }
    }

    /// Plays the queue another device sent, returning whether it does.
    private func take(_ message: [String: Any]) -> Bool {
        guard isEnabled(), let state = message["state"],
            let data = try? JSONSerialization.data(withJSONObject: state),
            let snapshot = try? JSONDecoder().decode(PlaybackQueue.Snapshot.self, from: data),
            !snapshot.items.isEmpty
        else { return false }
        player.takeOver(snapshot, at: (message["position"] as? Double) ?? 0)
        return player.current != nil
    }
}
