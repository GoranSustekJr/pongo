import Foundation

/// Why a shared link couldn't be read, as the server says.
public enum ImportLinkError: Error, Sendable, Equatable {
    /// Not a playlist or album link of Spotify or Apple Music.
    case unsupported
    /// Spotify's liked songs, which can't be shared.
    case likedSongs
    /// Only its owner can see it.
    case isPrivate
    case notFound
    /// The service didn't answer as expected.
    case unavailable

    init(detail: String) {
        switch detail {
        case "liked_songs": self = .likedSongs
        case "private": self = .isPrivate
        case "not_found": self = .notFound
        case "unsupported": self = .unsupported
        default: self = .unavailable
        }
    }
}

/// Finds catalog tracks for songs from other services.
public protocol SongMatching: Sendable {
    /// The match of each of [songs], in order.
    func match(_ songs: [ImportSong]) async throws -> [SongMatch]
}

/// Playlist imports on the Pongo API.
public final class ImportRepository: SongMatching {
    /// Most songs the server matches in one request.
    public static let batchSize = 50
    private let client: APIClient

    public init(client: APIClient) { self.client = client }

    /// The songs of the shared Spotify or Apple Music playlist or album at [link].
    public func readLink(_ link: String) async throws -> ImportPlaylist {
        let data: JSONValue
        do {
            data = try await client.post("import_link", ["link": .string(link)])
        } catch APIError.status(422, let detail) {
            throw ImportLinkError(detail: detail)
        }
        let source = ImportSource(rawValue: data["source"]?.string ?? "") ?? .file
        let name = data["name"]?.string ?? ""
        return ImportPlaylist(
            id: "\(source.rawValue):\(data["kind"]?.string ?? ""):\(data["id"]?.string ?? UUID().uuidString)",
            name: name.isEmpty ? link : name, source: source,
            songs: (data["tracks"]?.array ?? []).compactMap(ImportSong.init(json:)),
            image: data["image"]?.string, truncated: data["truncated"]?.bool ?? false,
            total: data["total"]?.int, skipped: data["skipped"]?.int ?? 0)
    }

    public func match(_ songs: [ImportSong]) async throws -> [SongMatch] {
        guard !songs.isEmpty else { return [] }
        let data = try await client.post(
            "import_match", ["songs": .array(songs.prefix(Self.batchSize).map(\.json))], timeout: 180)
        let matches = (data["matches"]?.array ?? []).map(SongMatch.init(json:))
        guard matches.count == min(songs.count, Self.batchSize) else { throw APIError.malformed("import_match") }
        return matches
    }
}
