import CryptoKit
import Foundation

/// Google sign in in the browser, with PKCE, for an iOS OAuth client.
///
/// The app opens [authorizationURL] in a web authentication session, which
/// returns to the reversed client ID scheme; [idToken(for:)] then trades the
/// returned code for the ID token the Pongo API verifies.
public struct GoogleOAuth: Sendable {
    public let clientID: String
    private let verifier: String
    private let state: String

    public init(clientID: String) {
        self.clientID = clientID
        verifier = Self.randomString()
        state = Self.randomString()
    }

    /// The URL scheme Google redirects back to: the client ID reversed.
    public var callbackScheme: String {
        clientID.split(separator: ".").reversed().joined(separator: ".")
    }

    private var redirectURI: String { "\(callbackScheme):/oauth2redirect" }

    /// The page the user signs in on.
    public var authorizationURL: URL {
        var components = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")!
        let challenge = Data(SHA256.hash(data: Data(verifier.utf8))).base64URLEncoded
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: "openid email profile"),
            URLQueryItem(name: "code_challenge", value: challenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "prompt", value: "select_account"),
        ]
        return components.url!
    }

    /// The ID token for the [callback] the sign in page returned to.
    public func idToken(for callback: URL, session: URLSession = .shared) async throws -> String {
        let items = URLComponents(url: callback, resolvingAgainstBaseURL: false)?.queryItems ?? []
        guard items.first(where: { $0.name == "state" })?.value == state,
            let code = items.first(where: { $0.name == "code" })?.value
        else { throw APIError.malformed("Google sign in returned no code") }

        var request = URLRequest(url: URL(string: "https://oauth2.googleapis.com/token")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        var form = URLComponents()
        form.queryItems = [
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "code_verifier", value: verifier),
            URLQueryItem(name: "grant_type", value: "authorization_code"),
        ]
        request.httpBody = Data((form.percentEncodedQuery ?? "").utf8)
        let (data, _) = try await session.data(for: request)
        guard let idToken = try JSONValue.decode(data)["id_token"]?.string else {
            throw APIError.malformed("Google returned no ID token")
        }
        return idToken
    }

    private static func randomString() -> String {
        Data((0..<32).map { _ in UInt8.random(in: 0...255) }).base64URLEncoded
    }
}

extension Data {
    var base64URLEncoded: String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
