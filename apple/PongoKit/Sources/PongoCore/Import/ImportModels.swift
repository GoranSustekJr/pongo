import Foundation

/// Where playlists being brought over come from.
public enum ImportSource: String, Sendable, Hashable, Codable {
    case spotify
    case appleMusic = "apple_music"
    /// A CSV or text file from another tool.
    case file
}

/// A song from another service, described well enough to find it in the
/// catalog: the other service's IDs mean nothing here.
public struct ImportSong: Sendable, Hashable, Codable {
    public var title: String
    public var artists: [String]
    public var album: String?
    public var durationMs: Int?
    public var isrc: String?

    public init(title: String, artists: [String], album: String? = nil, durationMs: Int? = nil, isrc: String? = nil) {
        self.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.artists = artists.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        self.album = album?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        self.durationMs = durationMs.flatMap { $0 > 0 ? $0 : nil }
        self.isrc = isrc?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
    }

    /// The same song in another playlist has the same key, so it's matched once.
    var key: String {
        let seconds = durationMs.map { String($0 / 2000) } ?? ""
        return [title, artists.joined(separator: ","), seconds, isrc ?? ""]
            .map { $0.lowercased() }.joined(separator: "|")
    }

    var json: JSONValue {
        [
            "title": .string(title), "artists": JSONValue(artists), "album": JSONValue(album),
            "duration_ms": JSONValue(durationMs), "isrc": JSONValue(isrc),
        ]
    }

    init?(json: JSONValue) {
        guard let title = json["title"]?.string, !title.isEmpty else { return nil }
        self.init(
            title: title, artists: (json["artists"]?.array ?? []).compactMap(\.string),
            album: json["album"]?.string, durationMs: json["duration_ms"]?.int, isrc: json["isrc"]?.string)
    }
}

/// Where an imported list ends up.
public enum ImportDestination: String, Sendable, Hashable, Codable {
    /// An online playlist of the same name, created if there's none yet.
    case playlist
    /// The favourite songs, for liked songs.
    case favourites
}

/// A playlist or album from another service, ready to be imported.
public struct ImportPlaylist: Sendable, Hashable, Identifiable {
    public var id: String
    public var name: String
    public var source: ImportSource
    public var songs: [ImportSong]
    /// The cover's address, if the service has one.
    public var image: String?
    public var destination: ImportDestination
    /// Whether the service showed only some of the songs.
    public var truncated: Bool
    /// How many songs the service says there are, if it says.
    public var total: Int?
    /// Podcast episodes and the like, which aren't imported.
    public var skipped: Int

    public init(
        id: String = UUID().uuidString, name: String, source: ImportSource, songs: [ImportSong],
        image: String? = nil, destination: ImportDestination = .playlist, truncated: Bool = false,
        total: Int? = nil, skipped: Int = 0
    ) {
        self.id = id
        self.name = name
        self.source = source
        self.songs = songs
        self.image = image
        self.destination = destination
        self.truncated = truncated
        self.total = total
        self.skipped = skipped
    }
}

/// The catalog track found for a song, or the closest ones when none fit well.
public struct SongMatch: Sendable, Hashable {
    public var track: Track?
    public var score: Double
    public var alternatives: [Track]

    public init(track: Track?, score: Double, alternatives: [Track] = []) {
        self.track = track
        self.score = score
        self.alternatives = alternatives
    }

    init(json: JSONValue) {
        self.init(
            track: json["track"].flatMap(Track.init(json:)), score: json["score"]?.double ?? 0,
            alternatives: Track.list(json["alternatives"]))
    }
}

/// A song no catalog track was found for, kept for the user to pick one.
public struct UnmatchedSong: Sendable, Hashable, Identifiable {
    public var id: Int { position }
    /// Its place in the imported list.
    public var position: Int
    public var song: ImportSong
    public var alternatives: [Track]

    public init(position: Int, song: ImportSong, alternatives: [Track]) {
        self.position = position
        self.song = song
        self.alternatives = alternatives
    }
}

/// What importing one list did.
public struct ImportOutcome: Sendable, Hashable, Identifiable {
    public var id: String { playlist.id }
    public var playlist: ImportPlaylist
    /// The online playlist the songs went to; nil for favourites, or when no
    /// song was found and so no playlist was made.
    public var opid: Int?
    /// Whether the songs went into a playlist that existed already.
    public var merged: Bool
    public var added: Int
    /// Songs found that the playlist or favourites already had.
    public var alreadyThere: Int
    public var unmatched: [UnmatchedSong]
    /// The catalog track each found song became, by its place in the list,
    /// so songs picked later go where they were.
    public var placed: [Int: String]

    public init(
        playlist: ImportPlaylist, opid: Int?, merged: Bool, added: Int, alreadyThere: Int,
        unmatched: [UnmatchedSong], placed: [Int: String] = [:]
    ) {
        self.playlist = playlist
        self.opid = opid
        self.merged = merged
        self.added = added
        self.alreadyThere = alreadyThere
        self.unmatched = unmatched
        self.placed = placed
    }
}

/// How far an import is.
public struct ImportProgress: Sendable, Hashable {
    public var done: Int
    public var total: Int
    public var found: Int

    public init(done: Int, total: Int, found: Int) {
        self.done = done
        self.total = total
        self.found = found
    }
}

extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
