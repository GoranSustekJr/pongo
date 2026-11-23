import Foundation

/// What a Pongo server tells the apps before anyone signs in: its name and the
/// ways to sign in to it.
public struct ServerInfo: Sendable, Equatable {
    public var name: String
    /// Whether the server accepts Google sign-in.
    public var google: Bool
    /// Whether accounts with a username and password can sign in.
    public var passwords: Bool
    /// Whether anyone can create a password account.
    public var signup: Bool

    public init(name: String = "Pongo", google: Bool, passwords: Bool, signup: Bool) {
        self.name = name
        self.google = google
        self.passwords = passwords
        self.signup = signup
    }

    init(json: JSONValue) {
        name = json["name"]?.string ?? "Pongo"
        google = json["google"]?.bool ?? false
        passwords = json["passwords"]?.bool ?? false
        signup = json["signup"]?.bool ?? false
    }

    /// Servers from before /server_info only had Google sign-in.
    static let legacy = ServerInfo(google: true, passwords: false, signup: false)

    /// Asks the server at [baseURL] what it supports. Throws when nothing that
    /// looks like a Pongo server answers there.
    public static func fetch(baseURL: String, session: URLSession = .shared) async throws -> ServerInfo {
        guard let info = URL(string: baseURL + "server_info"), let health = URL(string: baseURL + "health") else {
            throw URLError(.badURL)
        }
        let (data, response) = try await session.data(for: URLRequest(url: info, timeoutInterval: 8))
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        if status == 200, let json = try? JSONValue.decode(data), json["passwords"] != nil {
            return ServerInfo(json: json)
        }
        // An older Pongo still answers its health check
        let (_, healthResponse) = try await session.data(for: URLRequest(url: health, timeoutInterval: 8))
        guard (healthResponse as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
        return .legacy
    }

    /// The base URL for what the user typed, such as "192.168.1.10",
    /// "pongo.example.com" or "https://pongo.example.com:9090": with a scheme,
    /// the API's port 8081 for plain HTTP, and a trailing slash. Addresses on
    /// the home network get http, everything else https. Nil if it isn't an
    /// address.
    public static func normalize(_ typed: String) -> String? {
        var text = typed.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !text.contains(" ") else { return nil }
        let hasScheme = text.lowercased().hasPrefix("http://") || text.lowercased().hasPrefix("https://")
        if !hasScheme {
            guard !text.contains("://") else { return nil }
            let host = String(text.split(separator: "/").first ?? "").split(separator: ":").first.map(String.init) ?? ""
            text = (isLocal(host) ? "http://" : "https://") + text
        }
        guard var components = URLComponents(string: text), let scheme = components.scheme?.lowercased(),
            scheme == "http" || scheme == "https", let host = components.host, !host.isEmpty
        else { return nil }
        components.scheme = scheme
        if scheme == "http", components.port == nil, !hasScheme { components.port = 8081 }
        components.query = nil
        components.fragment = nil
        if !components.path.hasSuffix("/") { components.path += "/" }
        return components.string
    }

    /// Whether [host] is an IP address, a .local name or a name without dots,
    /// which are on the home network.
    static func isLocal(_ host: String) -> Bool {
        let host = host.lowercased()
        if host == "localhost" || host.hasSuffix(".local") || !host.contains(".") { return true }
        return host.split(separator: ".").count == 4 && host.split(separator: ".").allSatisfy { UInt8($0) != nil }
    }
}
