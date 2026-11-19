import Foundation

/// Environment values the app is built against.
public struct AppConfig: Sendable {
    /// Base URL of the Pongo API, ending with a slash.
    public var serverURL: String
    /// Base WebSocket URL of the Pongo API, ending with a slash.
    public var socketURL: String
    /// Google OAuth client ID for iOS and macOS.
    public var googleClientID: String

    public init(serverURL: String, socketURL: String? = nil, googleClientID: String) {
        let server = serverURL.hasSuffix("/") ? serverURL : serverURL + "/"
        self.serverURL = server
        self.socketURL =
            socketURL.map { $0.hasSuffix("/") ? $0 : $0 + "/" }
            ?? server.replacingOccurrences(of: "http", with: "ws", options: .anchored)
        self.googleClientID = googleClientID
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
    public func post(_ path: String, _ body: [String: JSONValue] = [:]) async throws -> JSONValue {
        let data = try await postForData(path, body)
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

    /// Posts [body] to [path] and returns the body and status code.
    func send(_ path: String, _ body: [String: JSONValue], timeout: TimeInterval) async throws
        -> (Data, Int)
    {
        var request = URLRequest(url: url(path), timeoutInterval: timeout)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = JSONValue.object(body).encoded()
        let (data, response) = try await session.data(for: request)
        return (data, (response as? HTTPURLResponse)?.statusCode ?? 0)
    }

    static func detail(_ data: Data) -> String {
        (try? JSONValue.decode(data))?["detail"]?.string ?? ""
    }
}
