import Foundation
import Observation

/// The signed in session: its tokens, signing in and out.
@MainActor
@Observable
public final class AuthRepository: SessionTokens {
    private static let signInPath = "bed1684d6d16802154bba513a5f0980dd3dc4b612aeb6a05433c28f55936ca7d"

    public private(set) var isSignedIn: Bool
    /// The token authorizing audio streams.
    public private(set) var streamToken: String
    /// Grows whenever the server reports the account as disabled.
    public private(set) var disabledCount = 0

    @ObservationIgnored private let client: APIClient
    @ObservationIgnored private let store: KeyValueStore
    @ObservationIgnored private let session: URLSession
    @ObservationIgnored private var currentAccessToken: String?
    @ObservationIgnored private var refreshing: Task<Bool, Never>?

    /// Restores the saved session from [store] and gives [client] its tokens.
    public init(client: APIClient, store: KeyValueStore, session: URLSession = .shared) {
        self.client = client
        self.store = store
        self.session = session
        currentAccessToken = store.string(.accessToken)
        streamToken = store.string(.streamToken) ?? ""
        isSignedIn = store.bool(.signedIn, fallback: false)
        client.tokens = self
    }

    public func accessToken() async -> String? { currentAccessToken }

    public func accountDisabled() async { disabledCount += 1 }

    /// The device's ID for the server, so it can tell the user's devices apart.
    public static var deviceID: String? {
        #if os(iOS)
            return DeviceIdentifier.vendorID
        #else
            return DeviceIdentifier.machineID
        #endif
    }

    /// Signs in with the Google [idToken]. Returns whether a session started.
    public func signIn(googleIDToken idToken: String) async throws -> Bool {
        let value = try await client.postUnauthenticated(
            Self.signInPath,
            [
                "apple": false, "id_token": .string(idToken), "platform": "ios",
                "device_id": JSONValue(Self.deviceID),
            ])
        setStreamToken(value["st"]?.string ?? "")
        guard let access = value["at+JWT"]?.string, let refresh = value["rt+JWT"]?.string else { return false }
        setSession(signedIn: true, accessToken: access, refreshToken: refresh)
        return true
    }

    /// Renews the access token, signing out if the session expired.
    ///
    /// Requests failing together share one renewal, since each refresh token
    /// works only once.
    public func refreshSession() async -> Bool {
        if let refreshing { return await refreshing.value }
        let task = Task { await renew() }
        refreshing = task
        let renewed = await task.value
        refreshing = nil
        return renewed
    }

    private func renew() async -> Bool {
        var request = URLRequest(url: client.url("renew_at"))
        request.httpMethod = "POST"
        request.httpBody = JSONValue.object(["jwt": JSONValue(store.string(.refreshToken))]).encoded()
        guard let (data, response) = try? await session.data(for: request) else { return false }
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        if status == 401 {
            signOut()
            return false
        }
        guard status == 200, let body = try? JSONValue.decode(data) else { return false }
        currentAccessToken = body["at"]?.string
        store.set(currentAccessToken, for: .accessToken)
        // The server issues a new refresh token every time and refuses old ones
        if let refresh = body["rt+JWT"]?.string { store.set(refresh, for: .refreshToken) }
        if let stream = body["st"]?.string { setStreamToken(stream) }
        return true
    }

    /// The signed in account's user ID, from its access token.
    public var accountID: String? {
        guard let token = currentAccessToken else { return nil }
        let parts = token.split(separator: ".")
        guard parts.count == 3 else { return nil }
        var payload = parts[1].replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        payload += String(repeating: "=", count: (4 - payload.count % 4) % 4)
        guard let data = Data(base64Encoded: payload),
            let claims = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }
        return claims["uid"] as? String
    }

    /// Signs the user out on this device.
    public func signOut() {
        setSession(signedIn: false, accessToken: nil, refreshToken: nil)
    }

    /// Deletes the account on the server and signs out.
    public func deleteAccount() async throws {
        _ = try await client.postForData("delete_account")
        signOut()
    }

    /// The account details of the signed in user. Signs out if the server no
    /// longer accepts the session.
    public func fetchProfile() async throws -> UserProfile {
        do {
            return UserProfile(json: try await client.post("user_data"))
        } catch let error as APIError {
            // Network failures keep the session; rejections end it
            signOut()
            throw error
        }
    }

    private func setSession(signedIn: Bool, accessToken: String?, refreshToken: String?) {
        isSignedIn = signedIn
        currentAccessToken = accessToken
        store.set(signedIn, for: .signedIn)
        store.set(accessToken, for: .accessToken)
        store.set(refreshToken, for: .refreshToken)
    }

    private func setStreamToken(_ token: String) {
        streamToken = token
        store.set(token, for: .streamToken)
    }
}
