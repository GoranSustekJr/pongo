import Foundation

/// One size of a cover image.
public struct ImageRef: Sendable, Hashable, Codable {
    public var url: String
    public var height: Int?
    public var width: Int?

    public init(url: String, height: Int? = nil, width: Int? = nil) {
        self.url = url
        self.height = height
        self.width = width
    }

    init?(json: JSONValue) {
        guard let url = json["url"]?.string else { return nil }
        self.init(url: url, height: json["height"]?.int, width: json["width"]?.int)
    }

    static func list(_ json: JSONValue?) -> [ImageRef] {
        (json?.array ?? []).compactMap(ImageRef.init(json:))
    }

    var json: JSONValue {
        ["url": .string(url), "height": JSONValue(height), "width": JSONValue(width)]
    }

    /// Pixel count used to rank the image against other sizes of the same
    /// picture. A missing dimension is estimated from the other one the same
    /// way the Flutter app always ranked them.
    var resolution: Int {
        if let width { return width * (height ?? width) }
        if let height { return height + height }
        return 0
    }
}

extension [ImageRef] {
    /// URL of the largest image, or an empty string if there is none.
    public var bestURL: String {
        guard var best = first else { return "" }
        var bestResolution = 0
        for image in self where image.resolution > bestResolution {
            best = image
            bestResolution = image.resolution
        }
        return best.url
    }

    /// URL of the smallest image covering [width] by [height], falling back to
    /// the largest one when every image is smaller.
    public func url(forWidth width: Int, height: Int) -> String {
        guard !isEmpty else { return "" }
        let wanted = width * height
        return sorted { $0.resolution < $1.resolution }
            .first { $0.resolution >= wanted }?.url ?? bestURL
    }
}

/// An artist credited on a track.
public struct ArtistRef: Sendable, Hashable, Codable {
    public var id: String
    public var name: String?

    public init(id: String, name: String?) {
        self.id = id
        self.name = name
    }

    init?(json: JSONValue) {
        guard let id = json["id"].flatMap(Self.idString) else { return nil }
        self.init(id: id, name: json["name"]?.string)
    }

    // Deezer IDs are numbers, which older data stored as such
    static func idString(_ value: JSONValue) -> String? {
        value.string ?? value.int.map(String.init)
    }

    var json: JSONValue { ["id": .string(id), "name": JSONValue(name)] }

    /// Artists in a JSON list encoded as a string, as tables keep them.
    public static func decodeList(_ encoded: String?) -> [ArtistRef] {
        guard let encoded, let json = try? JSONValue.decode(Data(encoded.utf8)) else { return [] }
        return (json.array ?? []).compactMap(ArtistRef.init(json:))
    }

    /// [artists] as the JSON string tables keep.
    public static func encodeList(_ artists: [ArtistRef]) -> String {
        JSONValue.array(artists.map(\.json)).encodedString()
    }
}

/// The album a track belongs to.
public struct AlbumRef: Sendable, Hashable, Codable {
    public var id: String
    public var name: String
    public var images: [ImageRef]
    public var releaseDate: String?

    public init(id: String, name: String, images: [ImageRef], releaseDate: String? = nil) {
        self.id = id
        self.name = name
        self.images = images
        self.releaseDate = releaseDate
    }

    init?(json: JSONValue) {
        guard let id = json["id"].flatMap(ArtistRef.idString), let name = json["name"]?.string
        else { return nil }
        self.init(
            id: id, name: name, images: ImageRef.list(json["images"]),
            releaseDate: json["release_date"]?.string)
    }

    /// The JSON stored with favourites and playlist tracks.
    var json: JSONValue {
        ["id": .string(id), "name": .string(name), "images": .array(images.map(\.json))]
    }

    /// An album decoded from the JSON string tables keep.
    public static func decode(_ encoded: String?) -> AlbumRef? {
        guard let encoded, let json = try? JSONValue.decode(Data(encoded.utf8)) else { return nil }
        return AlbumRef(json: json)
    }

    /// The album as the JSON string tables keep.
    public var encoded: String { json.encodedString() }
}

/// A song from the catalog or from the downloaded library.
public struct Track: Sendable, Hashable, Identifiable, Codable {
    public var id: String
    public var name: String
    public var artists: [ArtistRef]
    public var album: AlbumRef?
    /// Path of the downloaded cover, for downloaded tracks.
    public var localImagePath: String?
    /// Path of the downloaded audio, for downloaded tracks.
    public var audioPath: String?

    public init(
        id: String, name: String, artists: [ArtistRef], album: AlbumRef?,
        localImagePath: String? = nil, audioPath: String? = nil
    ) {
        self.id = id
        self.name = name
        self.artists = artists
        self.album = album
        self.localImagePath = localImagePath
        self.audioPath = audioPath
    }

    /// A track from the API's JSON.
    public init?(json: JSONValue) {
        guard let id = json["id"].flatMap(ArtistRef.idString), let name = json["name"]?.string
        else { return nil }
        self.init(
            id: id, name: name,
            artists: (json["artists"]?.array ?? []).compactMap(ArtistRef.init(json:)),
            album: json["album"].flatMap(AlbumRef.init(json:)))
    }

    static func list(_ json: JSONValue?) -> [Track] {
        (json?.array ?? []).compactMap(Track.init(json:))
    }

    public var isDownloaded: Bool { audioPath != nil }

    /// The artist names joined for display.
    public var artistNames: String { artists.compactMap(\.name).joined(separator: ", ") }

    /// URL of the cover: the downloaded file or the album's largest image.
    public var coverURL: URL? {
        if let localImagePath { return URL(filePath: localImagePath) }
        return URL(string: album?.images.bestURL ?? "")
    }

    /// URL of a cover of about [size] pixels.
    public func coverURL(size: Int) -> URL? {
        if let localImagePath { return URL(filePath: localImagePath) }
        return URL(string: album?.images.url(forWidth: size, height: size) ?? "")
    }
}

/// An album, single or compilation in the catalog.
public struct Album: Sendable, Hashable, Identifiable, Codable {
    public var id: String
    public var name: String
    /// The release type, such as `album` or `single`.
    public var type: String
    public var artists: [String]
    /// URL of the cover image.
    public var image: String

    public init(id: String, name: String, type: String, artists: [String], image: String) {
        self.id = id
        self.name = name
        self.type = type
        self.artists = artists
        self.image = image
    }

    /// An album from the API's JSON with its largest cover, or a cover of
    /// about 300 pixels when [thumbnail].
    init?(json: JSONValue, thumbnail: Bool = false) {
        guard let id = json["id"].flatMap(ArtistRef.idString), let name = json["name"]?.string
        else { return nil }
        let images = ImageRef.list(json["images"])
        let type = thumbnail ? json["album_type"]?.string : (json["album_group"] ?? json["album_type"])?.string
        self.init(
            id: id, name: name, type: type ?? "album",
            artists: (json["artists"]?.array ?? []).compactMap { $0["name"]?.string },
            image: thumbnail ? images.url(forWidth: 300, height: 300) : images.bestURL)
    }

    static func list(_ json: JSONValue?, thumbnail: Bool = false) -> [Album] {
        (json?.array ?? []).compactMap { Album(json: $0, thumbnail: thumbnail) }
    }
}

/// An artist in the catalog.
public struct Artist: Sendable, Hashable, Identifiable, Codable {
    public var id: String
    public var name: String
    /// URL of the profile image.
    public var image: String

    public init(id: String, name: String, image: String) {
        self.id = id
        self.name = name
        self.image = image
    }

    init?(json: JSONValue) {
        guard let id = json["id"].flatMap(ArtistRef.idString), let name = json["name"]?.string
        else { return nil }
        self.init(id: id, name: name, image: ImageRef.list(json["images"]).bestURL)
    }

    static func list(_ json: JSONValue?) -> [Artist] {
        (json?.array ?? []).compactMap(Artist.init(json:))
    }
}

/// A playlist in the catalog.
public struct Playlist: Sendable, Hashable, Identifiable, Codable {
    public var id: String
    public var name: String
    public var description: String?
    /// URL of the cover image, or an empty string if there is none.
    public var image: String

    public init(id: String, name: String, description: String?, image: String) {
        self.id = id
        self.name = name
        self.description = description
        self.image = image
    }

    init?(json: JSONValue) {
        guard let id = json["id"].flatMap(ArtistRef.idString), let name = json["name"]?.string
        else { return nil }
        self.init(
            id: id, name: name, description: json["description"]?.string,
            image: ImageRef.list(json["images"]).url(forWidth: 300, height: 300))
    }

    static func list(_ json: JSONValue?) -> [Playlist] {
        (json?.array ?? []).compactMap(Playlist.init(json:))
    }
}

/// A browse category, such as a genre or mood.
public struct BrowseCategory: Sendable, Hashable, Identifiable, Codable {
    public var id: String
    public var name: String
    public var iconURL: String

    public init(id: String, name: String, iconURL: String) {
        self.id = id
        self.name = name
        self.iconURL = iconURL
    }

    init?(json: JSONValue) {
        guard let id = json["id"].flatMap(ArtistRef.idString), let name = json["name"]?.string
        else { return nil }
        self.id = id
        self.name = name
        iconURL = json["icons"]?[0]?["url"]?.string ?? ""
    }
}

/// Which tracks of a list the server can stream right away.
public struct TrackAvailability: Sendable, Hashable {
    /// Length in seconds of each track the server already has.
    public var durations: [String: Double]
    /// IDs of the tracks the server has to fetch first.
    public var missing: [String]
    /// Why the server couldn't fetch some of the missing tracks the last time
    /// it tried, by ID.
    public var failed: [String: DownloadFailure]

    public init(durations: [String: Double] = [:], missing: [String] = [], failed: [String: DownloadFailure] = [:]) {
        self.durations = durations
        self.missing = missing
        self.failed = failed
    }

    /// Parses the `durations` and `missing_tracks` fields of a response.
    init(json: JSONValue) {
        var durations: [String: Double] = [:]
        for item in json["durations"]?.array ?? [] {
            if let stid = item[0].flatMap(ArtistRef.idString), let duration = item[1]?.double {
                durations[stid] = duration
            }
        }
        self.durations = durations
        missing = (json["missing_tracks"]?.array ?? []).compactMap { value in
            guard let stid = ArtistRef.idString(value), stid != "null" else { return nil }
            return stid
        }
        failed = (json["failed_tracks"]?.object ?? [:]).compactMapValues { $0.string.map(DownloadFailure.init) }
    }
}

/// Why the server couldn't download a track.
public enum DownloadFailure: Sendable, Hashable {
    /// YouTube has no recording that matches it.
    case noMatch
    /// The catalog doesn't have it any more.
    case catalog
    /// Downloading it failed.
    case download

    init(reason: String) {
        switch reason {
        case "no_match": self = .noMatch
        case "catalog": self = .catalog
        default: self = .download
        }
    }
}

/// The tracks of an album or playlist and which of them can play right away.
public struct TrackListing: Sendable {
    public var tracks: [Track]
    public var availability: TrackAvailability
}

/// An artist's releases and top tracks.
public struct ArtistDetails: Sendable {
    /// Full length albums.
    public var albums: [Album]
    /// Singles, EPs and compilations.
    public var otherReleases: [Album]
    public var tracks: [Track]
}

/// The results of a catalog search.
public struct SearchResults: Sendable {
    public var tracks: [Track] = []
    public var artists: [Artist] = []
    public var albums: [Album] = []
    public var playlists: [Playlist] = []

    public init() {}
}

/// The content of the home screen.
public struct HomeFeed: Sendable, Codable {
    /// Tracks recommended from the play history.
    public var history: [Track] = []
    public var categories: [BrowseCategory] = []
    public var newReleases: [Album] = []
    public var topTracks: [Track] = []
    public var topArtists: [Artist] = []
    public var topPlaylists: [Playlist] = []

    public init() {}
}

/// A genre with its own charts.
public struct GenrePage: Sendable {
    public var genre: BrowseCategory
    public var tracks: [Track] = []
    public var albums: [Album] = []
    public var artists: [Artist] = []
    public var playlists: [Playlist] = []
}

/// A song recognized by Shazam.
public struct ShazamMatch: Sendable {
    public var title: String
    public var subtitle: String
    /// URL of the cover art.
    public var coverArt: String
}

/// The signed in user's account details.
public struct UserProfile: Sendable {
    public var email: String
    public var name: String
    /// URL of the profile picture.
    public var picture: String
    /// Whether the email is a private relay address.
    public var hiddenAuth: Bool

    init(json: JSONValue) {
        email = json["email"]?.string ?? ""
        name = json["name"]?.string ?? ""
        picture = json["picture"]?.string ?? ""
        hiddenAuth = json["hidden_auth"]?.bool ?? false
    }
}

/// How a song feels, as the server hears it in the audio.
public enum Mood: String, CaseIterable, Sendable, Codable {
    case chill, happy, energetic, party, intense, melancholy
}

/// What the server measured in a track's audio: its mood and the scores it
/// comes from, which run from 0 to 1.
public struct TrackMood: Sendable, Hashable, Codable {
    public var mood: Mood
    public var tempo: Double
    public var energy: Double
    public var valence: Double
    public var danceability: Double

    public init(mood: Mood, tempo: Double, energy: Double, valence: Double, danceability: Double) {
        self.mood = mood
        self.tempo = tempo
        self.energy = energy
        self.valence = valence
        self.danceability = danceability
    }

    init?(json: JSONValue) {
        guard let mood = json["mood"]?.string.flatMap(Mood.init(rawValue:)) else { return nil }
        self.init(
            mood: mood, tempo: json["tempo"]?.double ?? 0, energy: json["energy"]?.double ?? 0,
            valence: json["valence"]?.double ?? 0, danceability: json["danceability"]?.double ?? 0)
    }
}
