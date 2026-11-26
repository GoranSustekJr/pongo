import Foundation

/// The music catalog on the Pongo API.
public final class CatalogRepository: Sendable {
    private let client: APIClient

    public init(client: APIClient) { self.client = client }

    /// Searches the catalog of [market] for [query].
    public func search(_ query: String, market: String) async throws -> SearchResults {
        let data = try await client.post(
            "search_spotify", ["query": .string(query), "market": .string(market)])
        var results = SearchResults()
        results.tracks = Track.list(data.at("tracks", "items"))
        results.artists = Artist.list(data.at("artists", "items"))
        results.albums = Album.list(data.at("albums", "items"))
        results.playlists = Playlist.list(data.at("playlists", "items"))
        return results
    }

    /// The album with [id].
    public func album(_ id: String) async throws -> Album {
        let data = try await client.post("get_album_data", ["salid": .string(id)])
        guard let album = Album(json: data, thumbnail: true) else {
            throw APIError.malformed("get_album_data")
        }
        return album
    }

    /// The tracks of [album].
    public func albumTracks(_ album: Album) async throws -> TrackListing {
        let data = try await client.post("get_album", ["salid": .string(album.id)])
        // Album tracks arrive without their album, so it's attached here
        let albumRef = AlbumRef(id: album.id, name: album.name, images: [ImageRef(url: album.image)], releaseDate: "")
        let tracks = Track.list(data["items"]).map { track in
            var track = track
            track.album = albumRef
            return track
        }
        return TrackListing(tracks: tracks, availability: TrackAvailability(json: data))
    }

    /// The releases and top tracks of the artist with [id] in [market].
    public func artist(_ id: String, market: String) async throws -> ArtistDetails {
        let data = try await client.post(
            "get_artist_metadata", ["said": .string(id), "market": .string(market)])
        let albums = Album.list(data["albums"])
        return ArtistDetails(
            albums: albums.filter { $0.type == "album" },
            otherReleases: albums.filter { $0.type != "album" },
            tracks: Track.list(data["tracks"]))
    }

    /// The URL of the profile image of the artist with [id].
    public func artistImage(_ id: String) async throws -> String {
        let data = try await client.post(
            "caf5cc332d474f35ff74e94af44f2a7801b620b2ce0196560e038b511d14986e",
            ["said": .string(id)])
        return ImageRef.list(data["images"]).bestURL
    }

    /// The artist with [id] and [name], with its profile image.
    public func artist(id: String, name: String) async throws -> Artist {
        Artist(id: id, name: name, image: try await artistImage(id))
    }

    /// The tracks of the catalog playlist with [id].
    public func playlistTracks(_ id: String) async throws -> TrackListing {
        let data = try await client.post("get_playlist", ["spid": .string(id)])
        let tracks = (data["items"]?.array ?? []).compactMap { item -> Track? in
            guard let track = item["track"], track["name"]?.string != "" else { return nil }
            return Track(json: track)
        }
        return TrackListing(tracks: tracks, availability: TrackAvailability(json: data))
    }

    /// Which of the tracks with [stids] the server can stream right away.
    public func availability(_ stids: [String]) async throws -> TrackAvailability {
        TrackAvailability(
            json: try await client.post("get_serialized_shuffle", ["stids": JSONValue(stids)]))
    }

    /// Has the server start downloading those of the tracks with [stids] it
    /// doesn't have, trying failed ones again. Returns how many it started,
    /// and whether the user's hourly download limit stopped it.
    public func prepare(_ stids: [String]) async throws -> (started: Int, limited: Bool) {
        let data = try await client.post("prepare_tracks", ["stids": JSONValue(stids)])
        return (data["started"]?.int ?? 0, data["limited"]?.bool ?? false)
    }

    /// The mood of each of the tracks with [stids] the server has analyzed.
    public func moods(_ stids: [String]) async throws -> [String: TrackMood] {
        var moods: [String: TrackMood] = [:]
        for start in stride(from: 0, to: stids.count, by: 500) {
            let batch = Array(stids[start..<min(start + 500, stids.count)])
            let data = try await client.post("track_moods", ["stids": JSONValue(batch)])
            for (stid, value) in data["moods"]?.object ?? [:] {
                if let mood = TrackMood(json: value) { moods[stid] = mood }
            }
        }
        return moods
    }

    /// [artistIDs] in scenes of artists that belong together, such as Balkan
    /// pop or tango, biggest first, as the server works them out.
    public func artistGroups(_ artistIDs: [String]) async throws -> [[String]] {
        let data = try await client.post("artist_groups", ["artists": JSONValue(Array(artistIDs.prefix(300)))])
        return (data["groups"]?.array ?? []).map { ($0.array ?? []).compactMap(\.string) }
    }

    /// The length in seconds of the track with [stid], if the server has it.
    public func duration(of stid: String) async -> Double? {
        try? await client.post("get_track_duration", ["stid": .string(stid)])["duration"]?.double
    }

    /// The home screen content for the user's [history] of played track IDs,
    /// with the charts of [country], an ISO code such as "GB".
    public func homeFeed(
        history: [String], market: String, locale: String, country: String?, categoryCount: Int,
        includeHistory: Bool, includeCategories: Bool
    ) async throws -> HomeFeed {
        var body: [String: JSONValue] = [
            "market": .string(market), "history": JSONValue(history),
            "category_num": .int(categoryCount), "locale": .string(locale),
        ]
        if let country { body["country"] = .string(country) }
        let data = try await client.post("get_recommendations", body)
        var feed = HomeFeed()
        if includeHistory { feed.history = Track.list(data.at("history", "tracks")) }
        if includeCategories {
            feed.categories = (data.at("categories", "categories", "items")?.array ?? [])
                .compactMap(BrowseCategory.init(json:))
            feed.newReleases = Album.list(data.at("new_releases", "albums", "items"), thumbnail: true)
            feed.topTracks = Track.list(data.at("charts", "tracks"))
            feed.topArtists = Artist.list(data.at("charts", "artists"))
            feed.topPlaylists = Playlist.list(data.at("charts", "playlists"))
        }
        return feed
    }

    /// The genre with [id] and its top tracks, albums, artists and playlists.
    public func genre(_ id: String) async throws -> GenrePage {
        let data = try await client.post("get_genre", ["gid": .string(id)])
        guard let genre = BrowseCategory(json: data) else { throw APIError.malformed("get_genre") }
        return GenrePage(
            genre: genre, tracks: Track.list(data["tracks"]), albums: Album.list(data["albums"], thumbnail: true),
            artists: Artist.list(data["artists"]), playlists: Playlist.list(data["playlists"]))
    }

    /// Recognizes the song behind the track with [stid].
    public func shazam(_ stid: String) async throws -> ShazamMatch {
        let data = try await client.post(
            "6a2f5d49dda86647d136751f354f0bbfbd76a414a283b18f211b34f911029e0e",
            ["stid": .string(stid)])
        guard let title = data.at("track", "title")?.string else {
            throw APIError.malformed("shazam")
        }
        return ShazamMatch(
            title: title, subtitle: data.at("track", "subtitle")?.string ?? "",
            coverArt: data.at("track", "images", "coverart")?.string ?? "")
    }
}
