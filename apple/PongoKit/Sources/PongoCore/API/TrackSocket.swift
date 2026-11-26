import Foundation

/// The state of a track on the server while it's being made playable.
public enum TrackFetchState: Sendable, Equatable {
    /// The server doesn't have the track yet and started fetching it.
    case downloading
    /// The track can be streamed; it lasts this many seconds.
    case ready(Double)
    /// The server couldn't fetch the track.
    case unavailable
}

/// WebSocket endpoints that make tracks available on the server.
public final class TrackSocket: Sendable {
    private let client: APIClient
    private let session: URLSession

    public init(client: APIClient, session: URLSession = .shared) {
        self.client = client
        self.session = session
    }

    private func connect(_ path: String) -> URLSessionWebSocketTask {
        let task = session.webSocketTask(with: URL(string: client.config.socketURL + path)!)
        task.resume()
        return task
    }

    /// Asks the server to make the track with [stid] playable.
    ///
    /// Reports `downloading` through [onState] if the server has to fetch it
    /// first, and returns the final state. A rejected token is renewed once.
    public func ensureAvailable(
        _ stid: String, onState: @Sendable (TrackFetchState) -> Void = { _ in }
    ) async -> TrackFetchState {
        var renewed = false
        while true {
            let task = connect("test")
            defer { task.cancel(with: .normalClosure, reason: nil) }
            do {
                let token = await client.tokens?.accessToken()
                try await task.sendOnce(message(["stid": .string(stid), "at+JWT": JSONValue(token)]))
                let exists = try await receive(task)["exists"]?.string
                if exists != "true" && exists != "false" {
                    if renewed { return .unavailable }
                    renewed = true
                    _ = await client.tokens?.refreshSession()
                    continue
                }
                if exists == "false" { onState(.downloading) }
                guard let duration = try await receive(task)["duration"]?.double else {
                    return .unavailable
                }
                return .ready(duration)
            } catch {
                return .unavailable
            }
        }
    }

    /// Opens a session that fetches the tracks with [stids], in that order.
    ///
    /// All of them are sent up front, so the server fetches the next ones while
    /// the app waits for the first.
    public func openBatch(_ stids: [String]) async -> TrackBatch {
        let task = connect("concenating_stids")
        let token = await client.tokens?.accessToken()
        try? await task.sendOnce(message(["stids": .int(stids.count), "at+JWT": JSONValue(token)]))
        for stid in stids {
            try? await task.sendOnce(message(["stid": .string(stid)]))
        }
        return TrackBatch(task: task)
    }

    private func message(_ object: [String: JSONValue]) -> URLSessionWebSocketTask.Message {
        .string(JSONValue.object(object).encodedString())
    }
}

/// A socket that reports fetched tracks in order.
public final class TrackBatch: Sendable {
    let task: URLSessionWebSocketTask

    init(task: URLSessionWebSocketTask) { self.task = task }

    /// Waits for the next track of the batch and returns its length in
    /// seconds, or `nil` if the server couldn't get it.
    public func next() async -> Double? {
        (try? await receive(task))?["duration"]?.double
    }

    /// Closes the socket.
    public func close() {
        task.cancel(with: .normalClosure, reason: nil)
    }
}

private func receive(_ task: URLSessionWebSocketTask) async throws -> JSONValue {
    switch try await task.receiveOnce() {
    case .string(let text): return try JSONValue.decode(Data(text.utf8))
    case .data(let data): return try JSONValue.decode(data)
    @unknown default: return .null
    }
}
