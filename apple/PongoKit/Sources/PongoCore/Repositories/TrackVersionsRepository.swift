import Foundation

/// A YouTube recording a catalog track can play from.
public struct TrackVersion: Sendable, Hashable, Identifiable {
    /// The YouTube video ID.
    public var id: String
    public var title: String
    public var artists: [String]
    public var album: String?
    public var year: String?
    /// The length in seconds.
    public var duration: Int?
    /// A music video rather than a song upload.
    public var isVideo: Bool
    public var image: String?
    /// How well it matches the track, 0 to 1, if known.
    public var score: Double?
    /// Whether the track plays from it now.
    public var isCurrent: Bool

    init?(json: JSONValue) {
        guard let id = json["id"]?.string else { return nil }
        self.id = id
        title = json["title"]?.string ?? ""
        artists = (json["artists"]?.array ?? []).compactMap(\.string)
        album = json["album"]?.string
        year = json["year"]?.string ?? json["year"]?.int.map(String.init)
        duration = json["duration"]?.int
        isVideo = json["kind"]?.string == "video"
        image = json["image"]?.string
        score = json["score"]?.double
        isCurrent = json["current"]?.bool ?? false
    }
}

/// Picking the right recording of a track when the server's match is another
/// one, such as a later re-recording with the same title and length.
public final class TrackVersionsRepository: Sendable {
    private let client: APIClient

    public init(client: APIClient) { self.client = client }

    /// The recordings that could be the track with [stid], the one it plays now first.
    public func versions(of stid: String) async throws -> [TrackVersion] {
        let data = try await client.post("track_versions", ["stid": .string(stid)], timeout: 90)
        return (data["versions"]?.array ?? []).compactMap(TrackVersion.init(json:))
    }

    /// Makes the server play the track with [stid] from [video], a YouTube video
    /// ID or link, for everyone from now on. Returns the new length in seconds.
    @discardableResult
    public func use(_ video: String, for stid: String) async throws -> Double {
        let data = try await client.post(
            "set_track_version", ["stid": .string(stid), "video": .string(video)], timeout: 300)
        return data["duration"]?.double ?? 0
    }
}
