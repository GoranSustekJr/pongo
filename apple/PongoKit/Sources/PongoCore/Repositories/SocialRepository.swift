import Foundation

/// Someone on the user's server, known by their friend code.
public struct Person: Sendable, Hashable, Identifiable {
    /// The friend code, which also invites people to follow.
    public var code: String
    public var name: String
    public var picture: URL?
    /// Whether the user follows them.
    public var following: Bool
    /// Whether it's the user.
    public var isYou: Bool

    public var id: String { code }

    public init(code: String, name: String, picture: URL? = nil, following: Bool = false, isYou: Bool = false) {
        self.code = code
        self.name = name
        self.picture = picture
        self.following = following
        self.isYou = isYou
    }

    init?(json: JSONValue?) {
        guard let json, let code = json["code"]?.string else { return nil }
        self.init(
            code: code, name: json["name"]?.string ?? "", picture: json["picture"]?.string.flatMap(URL.init(string:)),
            following: json["following"]?.bool ?? false, isYou: json["you"]?.bool ?? false)
    }
}

/// A playlist someone shows on their profile.
public struct SharedPlaylistInfo: Sendable, Hashable, Identifiable {
    public var owner: Person
    /// The playlist's sync key in its owner's library.
    public var key: String
    public var title: String
    public var trackCount: Int
    /// Whether the owner set a cover, which loads on its own.
    public var hasCover: Bool
    /// A track's image, for a playlist without a cover.
    public var image: URL?

    public var id: String { "\(owner.code)/\(key)" }

    public init(owner: Person, key: String, title: String, trackCount: Int, hasCover: Bool = false, image: URL? = nil) {
        self.owner = owner
        self.key = key
        self.title = title
        self.trackCount = trackCount
        self.hasCover = hasCover
        self.image = image
    }

    init?(json: JSONValue, owner: Person? = nil) {
        guard let key = json["key"]?.string, let owner = owner ?? Person(json: json["owner"]) else { return nil }
        self.init(
            owner: owner, key: key, title: json["title"]?.string ?? "", trackCount: json["count"]?.int ?? 0,
            hasCover: json["has_cover"]?.bool ?? false, image: json["image"]?.string.flatMap(URL.init(string:)))
    }
}

/// Someone's profile: who they are, their followers and shown playlists.
public struct Profile: Sendable, Hashable {
    public var person: Person
    public var followers: Int
    public var followingCount: Int
    public var followsYou: Bool
    public var playlists: [SharedPlaylistInfo]
}

/// A shared playlist with its tracks.
public struct SharedPlaylist: Sendable, Hashable {
    public var info: SharedPlaylistInfo
    public var cover: Data?
    public var tracks: [Track]
    /// How many people added it to their library.
    public var followers: Int
    /// Whether the user added it to theirs.
    public var followed: Bool
}

/// The user's own side: their code, counts and which playlists they show.
public struct SocialAccount: Sendable, Hashable {
    public var person: Person
    public var followers: Int
    public var following: Int
    /// Sync keys of the online playlists on the user's profile.
    public var shared: Set<String>
}

/// A friend asking the user to listen along with their session.
public struct ListenInvite: Sendable, Hashable, Identifiable {
    /// The code of the session to join.
    public var session: String
    /// Who asked, by their friend code.
    public var from: Person
    public var sent: Date

    public var id: String { session }

    public init(session: String, from: Person, sent: Date = Date()) {
        self.session = session
        self.from = from
        self.sent = sent
    }

    public init?(json: JSONValue?) {
        guard let json, let session = json["session"]?.string, let code = json["code"]?.string else { return nil }
        self.init(
            session: session,
            from: Person(
                code: code, name: json["name"]?.string ?? "",
                picture: json["picture"]?.string.flatMap { $0.isEmpty ? nil : URL(string: $0) }),
            sent: Date(timeIntervalSince1970: json["at"]?.double ?? Date().timeIntervalSince1970))
    }
}

/// Friends: finding people on the server by name or code, following them,
/// and seeing and following the playlists they show.
public final class SocialRepository: Sendable {
    private let client: APIClient

    public init(client: APIClient) { self.client = client }

    /// The link that opens the user's profile in Pongo, for [code].
    public static func link(for code: String) -> URL { URL(string: "pongo://friend/\(code)")! }

    /// The friend code in a pongo://friend/ link, if [url] is one.
    public static func code(in url: URL) -> String? {
        guard url.scheme == "pongo", url.host == "friend" else { return nil }
        let code = url.lastPathComponent.uppercased().filter { $0.isLetter || $0.isNumber }
        return code.isEmpty ? nil : code
    }

    public func account() async throws -> SocialAccount {
        let data = try await client.post("social/me", [:])
        return SocialAccount(
            person: Person(
                code: data["code"]?.string ?? "", name: data["name"]?.string ?? "",
                picture: data["picture"]?.string.flatMap(URL.init(string:)), isYou: true),
            followers: data["followers"]?.int ?? 0, following: data["following"]?.int ?? 0,
            shared: Set((data["shared"]?.array ?? []).compactMap(\.string)))
    }

    /// People whose name contains [query], or whose friend code it is.
    public func search(_ query: String) async throws -> [Person] {
        Self.people(try await client.post("social/search", ["query": .string(query)]))
    }

    /// Whom the user follows, or with [followers], who follows the user.
    public func people(followers: Bool = false) async throws -> [Person] {
        Self.people(try await client.post("social/people", ["which": .string(followers ? "followers" : "following")]))
    }

    public func profile(_ code: String) async throws -> Profile {
        let data = try await client.post("social/profile", ["code": .string(code)])
        let person = Person(
            code: data["code"]?.string ?? code, name: data["name"]?.string ?? "",
            picture: data["picture"]?.string.flatMap(URL.init(string:)), following: data["following"]?.bool ?? false,
            isYou: data["you"]?.bool ?? false)
        return Profile(
            person: person, followers: data["followers"]?.int ?? 0, followingCount: data["following_count"]?.int ?? 0,
            followsYou: data["follows_you"]?.bool ?? false,
            playlists: (data["playlists"]?.array ?? []).compactMap { SharedPlaylistInfo(json: $0, owner: person) })
    }

    public func follow(_ code: String, _ follow: Bool) async throws {
        _ = try await client.post("social/follow", ["code": .string(code), "follow": .bool(follow)])
    }

    public func playlist(_ code: String, key: String) async throws -> SharedPlaylist {
        let data = try await client.post("social/playlist", ["code": .string(code), "key": .string(key)])
        guard let info = SharedPlaylistInfo(json: data) else { throw APIError.malformed("social/playlist") }
        return SharedPlaylist(
            info: info, cover: data["cover"]?.string.flatMap { Data(base64Encoded: $0) },
            tracks: (data["tracks"]?.array ?? []).compactMap(Self.track),
            followers: data["followers"]?.int ?? 0, followed: data["followed"]?.bool ?? false)
    }

    /// The cover of a shared playlist, if its owner set one.
    public func cover(_ code: String, key: String) async throws -> Data? {
        try await client.post("social/cover", ["code": .string(code), "key": .string(key)])["cover"]?.string
            .flatMap { Data(base64Encoded: $0) }
    }

    /// Adds someone's shared playlist to the user's library, or removes it.
    public func followPlaylist(_ code: String, key: String, _ follow: Bool) async throws {
        _ = try await client.post(
            "social/follow_playlist", ["code": .string(code), "key": .string(key), "follow": .bool(follow)])
    }

    /// The shared playlists in the user's library.
    public func followedPlaylists() async throws -> [SharedPlaylistInfo] {
        (try await client.post("social/followed_playlists", [:])["playlists"]?.array ?? [])
            .compactMap { SharedPlaylistInfo(json: $0) }
    }

    /// Shows the user's online playlist with sync key [key] on their profile, or hides it.
    public func share(_ key: String, _ shared: Bool) async throws {
        _ = try await client.post("social/share_playlist", ["key": .string(key), "shared": .bool(shared)])
    }

    /// Asks the person with friend code [code] to join the session with
    /// [session], which the user is in.
    public func invite(_ code: String, to session: String) async throws {
        _ = try await client.post("social/invite", ["code": .string(code), "session": .string(session)])
    }

    /// The user's open invitations to listen together, newest first.
    public func invites() async throws -> [ListenInvite] {
        (try await client.post("social/invites", [:])["invites"]?.array ?? []).compactMap { ListenInvite(json: $0) }
    }

    /// Accepts or declines the invitation to [session]; whoever asked is told.
    public func answer(_ session: String, accept: Bool) async throws {
        _ = try await client.post("social/answer_invite", ["session": .string(session), "accept": .bool(accept)])
    }

    private static func people(_ data: JSONValue) -> [Person] {
        (data["people"]?.array ?? []).compactMap { Person(json: $0) }
    }

    /// A track of a shared playlist, stored as online playlists sync it.
    static func track(_ json: JSONValue) -> Track? {
        guard let value = json["stid"], let stid = ArtistRef.idString(value), !stid.isEmpty else { return nil }
        return OnlinePlaylistTrack(
            opid: 0, stid: stid, title: json["title"]?.string ?? "",
            artists: ArtistRef.decodeList(json["artists"]?.string), album: AlbumRef.decode(json["album"]?.string),
            image: json["image"]?.string
        ).track
    }
}
