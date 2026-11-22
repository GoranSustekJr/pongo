import Foundation

/// Brings playlists from other services into the library: finds a catalog
/// track for every song, then fills an online playlist of the same name (or
/// the favourites, for liked songs).
///
/// Importing again is safe: songs go into the playlist with the same name,
/// and those it already has are left alone, so a second run only adds what's
/// new. A song in several playlists is matched once.
public struct PlaylistImporter: Sendable {
    /// Batches matched at the same time.
    static let parallelBatches = 2
    /// The largest cover downloaded for a new playlist.
    static let maxCoverBytes = 3 * 1024 * 1024

    private let database: Database
    private let matcher: any SongMatching
    private let session: URLSession

    public init(database: Database, matcher: any SongMatching, session: URLSession = .shared) {
        self.database = database
        self.matcher = matcher
        self.session = session
    }

    /// Imports [playlists], telling [progress] how far matching is. Cancelling
    /// the task stops it between batches; nothing is written until every song
    /// was looked up.
    public func run(
        _ playlists: [ImportPlaylist], progress: @Sendable (ImportProgress) -> Void = { _ in }
    ) async throws -> [ImportOutcome] {
        let matches = try await matchAll(playlists.flatMap(\.songs), progress: progress)
        try Task.checkCancellation()
        var outcomes: [ImportOutcome] = []
        for playlist in playlists {
            outcomes.append(try await save(playlist, matches: matches))
        }
        return outcomes
    }

    /// Each song's match by its key; songs listed twice are looked up once.
    func matchAll(
        _ songs: [ImportSong], progress: @Sendable (ImportProgress) -> Void
    ) async throws -> [String: SongMatch] {
        var unique: [String: ImportSong] = [:]
        var order: [String] = []
        for song in songs where unique[song.key] == nil {
            unique[song.key] = song
            order.append(song.key)
        }
        let batches = stride(from: 0, to: order.count, by: ImportRepository.batchSize).map {
            Array(order[$0..<min($0 + ImportRepository.batchSize, order.count)])
        }

        var matches: [String: SongMatch] = [:]
        progress(ImportProgress(done: 0, total: order.count, found: 0))
        let matcher = matcher
        try await withThrowingTaskGroup(of: [(String, SongMatch)].self) { group in
            var next = batches.makeIterator()
            func add() {
                guard let keys = next.next() else { return }
                let songs = keys.compactMap { unique[$0] }
                group.addTask {
                    try Task.checkCancellation()
                    let found = try await Self.retrying { try await matcher.match(songs) }
                    return Array(zip(keys, found))
                }
            }
            for _ in 0..<Self.parallelBatches { add() }
            while let batch = try await group.next() {
                for (key, match) in batch { matches[key] = match }
                progress(
                    ImportProgress(
                        done: matches.count, total: order.count, found: matches.values.count { $0.track != nil }))
                add()
            }
        }
        return matches
    }

    /// Runs [body] again after a short wait when the server is busy or briefly
    /// unreachable, so one hiccup doesn't end a long import.
    static func retrying<T: Sendable>(_ body: @Sendable () async throws -> T) async throws -> T {
        var wait: Duration = .seconds(2)
        for _ in 0..<4 {
            do {
                return try await body()
            } catch let error as APIError {
                guard case .status(let status, _) = error, [429, 502, 503, 504].contains(status) else { throw error }
            } catch let error as URLError where [.timedOut, .networkConnectionLost].contains(error.code) {
            }
            try await Task.sleep(for: wait)
            wait *= 2
        }
        return try await body()
    }

    /// Puts the found songs of [playlist] where they belong.
    func save(_ playlist: ImportPlaylist, matches: [String: SongMatch]) async throws -> ImportOutcome {
        var tracks: [Track] = []
        var unmatched: [UnmatchedSong] = []
        var placed: [Int: String] = [:]
        for (position, song) in playlist.songs.enumerated() {
            if let track = matches[song.key]?.track {
                tracks.append(track)
                placed[position] = track.id
            } else {
                unmatched.append(
                    UnmatchedSong(position: position, song: song, alternatives: matches[song.key]?.alternatives ?? []))
            }
        }
        // Two versions of a song can be the same catalog track; it's listed once
        var seen = Set<String>()
        let unique = tracks.filter { seen.insert($0.id).inserted }
        let duplicates = tracks.count - unique.count

        var outcome = ImportOutcome(
            playlist: playlist, opid: nil, merged: false, added: 0, alreadyThere: duplicates, unmatched: unmatched,
            placed: placed)
        switch playlist.destination {
        case .favourites:
            outcome.added = try await database.addFavourites(unique.map(Favourite.init(track:)))
        case .playlist:
            guard !unique.isEmpty else { return outcome }
            let (opid, merged) = try await playlistID(for: playlist)
            outcome.opid = opid
            outcome.merged = merged
            outcome.added = try await database.addOnlineTracks(
                opid, unique.map { OnlinePlaylistTrack(opid: opid, track: $0) })
        }
        outcome.alreadyThere += unique.count - outcome.added
        return outcome
    }

    /// Adds [track], which the user picked for the song [unmatched] of
    /// [outcome], where that song was in its list, and returns the outcome
    /// without it.
    public func choose(_ track: Track, for unmatched: UnmatchedSong, in outcome: ImportOutcome) async throws
        -> ImportOutcome
    {
        var outcome = outcome
        outcome.unmatched.removeAll { $0.position == unmatched.position }
        switch outcome.playlist.destination {
        case .favourites:
            outcome.added += try await database.addFavourites([Favourite(track: track)])
        case .playlist:
            let opid: Int
            if let existing = outcome.opid {
                opid = existing
            } else {
                (opid, outcome.merged) = try await playlistID(for: outcome.playlist)
                outcome.opid = opid
            }
            var tracks = try await database.onlineTracks(opid)
            guard !tracks.contains(where: { $0.stid == track.id }) else {
                outcome.alreadyThere += 1
                return outcome
            }
            // After the closest song before it that was found, or before the first one found
            let before = outcome.placed.filter { $0.key < unmatched.position }.max { $0.key < $1.key }?.value
            let firstImported = outcome.placed.sorted { $0.key < $1.key }.lazy
                .compactMap { placed in tracks.firstIndex { $0.stid == placed.value } }.first
            let index = before.flatMap { stid in tracks.firstIndex { $0.stid == stid } }.map { $0 + 1 }
                ?? firstImported ?? tracks.count
            tracks.insert(OnlinePlaylistTrack(opid: opid, track: track), at: index)
            try await database.reorderOnlineTracks(opid, tracks)
            outcome.added += 1
        }
        outcome.placed[unmatched.position] = track.id
        return outcome
    }

    /// The online playlist named like [playlist], made if there's none.
    func playlistID(for playlist: ImportPlaylist) async throws -> (Int, merged: Bool) {
        let name = Self.title(for: playlist)
        if let existing = try await database.onlinePlaylists().first(where: { $0.title == name }) {
            return (existing.id, true)
        }
        return (try await database.createOnlinePlaylist(name, cover: await cover(playlist.image)), false)
    }

    /// The name a playlist gets here: its own, or its source's for unnamed ones.
    public static func title(for playlist: ImportPlaylist) -> String {
        let name = playlist.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !name.isEmpty { return name }
        switch playlist.source {
        case .spotify: return "Spotify"
        case .appleMusic: return "Apple Music"
        case .file: return "Import"
        }
    }

    /// The cover at [address], if it's an image that downloads quickly.
    func cover(_ address: String?) async -> Data? {
        guard let address, let url = URL(string: address), url.scheme == "https" else { return nil }
        var request = URLRequest(url: url, timeoutInterval: 15)
        request.setValue("image/*", forHTTPHeaderField: "Accept")
        guard let (data, response) = try? await session.data(for: request),
            let http = response as? HTTPURLResponse, http.statusCode == 200,
            http.mimeType?.hasPrefix("image/") ?? false, data.count <= Self.maxCoverBytes
        else { return nil }
        return data
    }
}
