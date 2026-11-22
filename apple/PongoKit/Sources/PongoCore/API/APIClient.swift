import Foundation
import Synchronization

/// Environment values the app is built against.
public struct AppConfig: Sendable {
    /// The addresses the Pongo API can be reached at, and which one is in use.
    public let servers: ServerAddresses
    /// Google OAuth client ID for iOS and macOS.
    public var googleClientID: String

    /// Base URL of the Pongo API in use, ending with a slash.
    public var serverURL: String { servers.current }
    /// Base WebSocket URL of the Pongo API in use, ending with a slash.
    public var socketURL: String {
        serverURL.replacingOccurrences(of: "http", with: "ws", options: .anchored)
    }

    /// [fallbackServerURLs] are tried in order when [serverURL] can't be reached,
    /// such as the server's address on the home network.
    public init(serverURL: String, fallbackServerURLs: [String] = [], googleClientID: String) {
        servers = ServerAddresses([serverURL] + fallbackServerURLs)
        self.googleClientID = googleClientID
    }
}

/// The base URLs of one Pongo server, in order of preference, and the one
/// requests go to.
public final class ServerAddresses: Sendable {
    public let all: [String]
    private let index = Mutex(0)

    init(_ urls: [String]) {
        let urls = urls.filter { !$0.isEmpty }.map { $0.hasSuffix("/") ? $0 : $0 + "/" }
        all = urls.isEmpty ? ["http://localhost:8081/"] : urls
    }

    public var current: String { all[index.withLock { $0 }] }

    /// Switches to the first address whose health check answers, keeping the
    /// current one when none does.
    public func choose(session: URLSession = .shared) async {
        guard all.count > 1 else { return }
        for (i, base) in all.enumerated() {
            guard let url = URL(string: base + "health") else { continue }
            let request = URLRequest(url: url, timeoutInterval: 4)
            if let (_, response) = try? await session.data(for: request),
                (response as? HTTPURLResponse)?.statusCode == 200
            {
                index.withLock { $0 = i }
                return
            }
        }
    }
}

/// Why a request to the API failed.
public enum APIError: Error, Sendable, Equatable {
    /// The server answered with [statusCode].
    case status(Int, detail: String = "")
    /// The signed in account was disabled on the server.
    case accountDisabled
    /// The response wasn't what was expected.
    case malformed(String)
}

/// Supplies and renews the tokens requests are sent with.
public protocol SessionTokens: AnyObject, Sendable {
    /// The access token sent with each request.
    func accessToken() async -> String?
    /// Renews the access token, returning whether it succeeded.
    func refreshSession() async -> Bool
    /// Called when the server reports the account as disabled.
    func accountDisabled() async
}

/// Authenticated calls to the Pongo API.
///
/// Every request carries the current access token and is retried once after
/// the session is renewed when the server rejects it.
public final class APIClient: Sendable {
    public let config: AppConfig
    private let session: URLSession
    nonisolated(unsafe) public weak var tokens: SessionTokens?

    public init(config: AppConfig, session: URLSession = .shared) {
        self.config = config
        self.session = session
    }

    func url(_ path: String) -> URL {
        URL(string: config.serverURL + path)!
    }

    /// Posts [body] to [path] and decodes the JSON response.
    public func post(
        _ path: String, _ body: [String: JSONValue] = [:], timeout: TimeInterval = 60
    ) async throws -> JSONValue {
        let data = try await postForData(path, body, timeout: timeout)
        do {
            return try JSONValue.decode(data)
        } catch {
            throw APIError.malformed("\(path): \(error)")
        }
    }

    /// Posts [body] to [path] and returns the raw successful response body.
    public func postForData(
        _ path: String, _ body: [String: JSONValue] = [:], timeout: TimeInterval = 60
    ) async throws -> Data {
        for attempt in 1...2 {
            var payload = body
            payload["at+JWT"] = JSONValue(await tokens?.accessToken())
            let (data, status) = try await send(path, payload, timeout: timeout)
            if status == 200 { return data }
            if status != 401 { throw APIError.status(status, detail: Self.detail(data)) }
            if Self.detail(data) == "Disabled" {
                await tokens?.accountDisabled()
                throw APIError.accountDisabled
            }
            if attempt < 2 { _ = await tokens?.refreshSession() }
        }
        throw APIError.status(401)
    }

    /// Posts [body] to [path] without an access token, for signing in.
    public func postUnauthenticated(_ path: String, _ body: [String: JSONValue]) async throws
        -> JSONValue
    {
        let (data, status) = try await send(path, body, timeout: 60)
        guard status == 200 else { throw APIError.status(status, detail: Self.detail(data)) }
        return try JSONValue.decode(data)
    }

    /// Posts [body] to [path] and returns the body and status code. When the
    /// server can't be reached it tries the other addresses once.
    func send(
        _ path: String, _ body: [String: JSONValue], timeout: TimeInterval, switchServer: Bool = true
    ) async throws -> (Data, Int) {
        var request = URLRequest(url: url(path), timeoutInterval: timeout)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = JSONValue.object(body).encoded()
        do {
            let (data, response) = try await session.data(for: request)
            return (data, (response as? HTTPURLResponse)?.statusCode ?? 0)
        } catch let error as URLError where switchServer && Self.unreachable.contains(error.code) {
            let tried = config.serverURL
            await config.servers.choose(session: session)
            guard config.serverURL != tried else { throw error }
            return try await send(path, body, timeout: timeout, switchServer: false)
        }
    }

    private static let unreachable: Set<URLError.Code> = [
        .cannotFindHost, .dnsLookupFailed, .cannotConnectToHost, .timedOut,
        .networkConnectionLost, .notConnectedToInternet,
    ]

    static func detail(_ data: Data) -> String {
        (try? JSONValue.decode(data))?["detail"]?.string ?? ""
    }
}
