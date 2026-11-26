import Foundation

/// Where downloaded tracks and their covers are kept.
public enum Downloads {
    /// Where tests keep downloads instead of the user's documents.
    nonisolated(unsafe) static var testDirectory: URL?

    /// The directory downloaded files are saved in.
    public static var directory: URL {
        let directory = testDirectory ?? URL.documentsDirectory.appending(path: "Downloads", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    /// [path] moved into the current downloads directory.
    ///
    /// The app's container moves when it's reinstalled or updated, so paths
    /// saved earlier point to where it used to be.
    static func currentPath(_ path: String) -> String {
        directory.appending(path: URL(filePath: path).lastPathComponent).path
    }

    private static func lyricsFile(_ stid: String) -> URL { directory.appending(path: "\(stid).lyrics.json") }

    /// The lyrics saved with the downloaded track [stid], so they show offline.
    public static func savedLyrics(_ stid: String) -> Lyrics? {
        guard let data = try? Data(contentsOf: lyricsFile(stid)) else { return nil }
        return try? JSONDecoder().decode(Lyrics.self, from: data)
    }

    /// Keeps [lyrics] with the downloaded track [stid].
    public static func saveLyrics(_ lyrics: Lyrics, for stid: String) {
        guard !lyrics.isEmpty, let data = try? JSONEncoder().encode(lyrics) else { return }
        try? data.write(to: lyricsFile(stid), options: .atomic)
    }
}

extension URLSession {
    /// A session that keeps nothing in the shared cache, for audio files the
    /// app saves itself: the cache would hold a second copy of each.
    public static let uncached: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = nil
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: configuration)
    }()
}

/// What happened when a track was downloaded.
public enum DownloadOutcome: Sendable {
    /// The track was saved to the device.
    case downloaded
    /// The track was already on the device.
    case alreadyDownloaded
}

/// How many downloads were saved, and the first that failed.
private actor DownloadTally {
    private var saved = 0
    private var firstError: Error?

    var total: (saved: Int, firstError: Error?) { (saved, firstError) }

    func add(_ result: Result<DownloadOutcome, Error>) {
        switch result {
        case .success(.downloaded): saved += 1
        case .success: break
        case .failure(let error): firstError = firstError ?? error
        }
    }
}

/// Tracks saved to the device.
public final class DownloadsRepository: Sendable {
    private let client: APIClient
    private let socket: TrackSocket
    private let database: Database
    private let session: URLSession
    private let lyrics: LyricsClient?
    private let audioURL: @Sendable (String) async -> URL?

    static let parallelDownloads = 4

    /// Creates the downloads, which also save each track's lyrics from
    /// [lyrics]. [audioURL] is where the player streams a track from, which
    /// downloads use too.
    public init(
        client: APIClient, socket: TrackSocket, database: Database, lyrics: LyricsClient? = nil,
        session: URLSession = .uncached, audioURL: @escaping @Sendable (String) async -> URL? = { _ in nil }
    ) {
        self.client = client
        self.socket = socket
        self.database = database
        self.lyrics = lyrics
        self.session = session
        self.audioURL = audioURL
    }

    /// The audio of the track with [stid].
    ///
    /// Fetched like the player streams it: a server behind its proxy has the
    /// proxy send audio files, which it only does for GET requests, so the
    /// older POST, which the app falls back on, gets an error there.
    func fetchAudio(_ stid: String) async throws -> Data {
        // Never a cached copy: after a new version was picked the URL stays the same
        if let url = await audioURL(stid),
            let (data, response) = try? await session.data(
                for: URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 300)),
            (response as? HTTPURLResponse)?.statusCode == 200, !data.isEmpty
        {
            return data
        }
        let data = try await client.postForData("download_track/\(stid)", timeout: 300)
        guard !data.isEmpty else { throw APIError.malformed("Track \(stid) came without audio") }
        return data
    }

    /// Downloads [track], with the cover at [cover], a URL or path, or else
    /// the track's best album image.
    @discardableResult
    public func download(_ track: Track, cover: String? = nil) async throws -> DownloadOutcome {
        if try await database.isDownloaded(track.id) { return .alreadyDownloaded }
        // The server has to have the track before it can send the file
        guard case .ready(let duration) = await socket.ensureAvailable(track.id) else {
            throw APIError.malformed("Track \(track.id) is unavailable")
        }
        let audio = try await fetchAudio(track.id)
        try await save(track, audio: audio, durationSeconds: duration, cover: cover ?? track.album?.images.bestURL)
        return .downloaded
    }

    /// Downloads several tracks, a few at a time, saving each as it arrives.
    ///
    /// Returns whether any track was saved, or throws the first error if
    /// every track failed. [finished] is told the ID of each track once it's
    /// done, and whether it's on the device now.
    public func downloadAll(
        _ tracks: [(track: Track, cover: String?)],
        finished: (@MainActor (String, Bool) -> Void)? = nil
    ) async throws -> Bool {
        let tally = DownloadTally()
        // The server fetches as many tracks at once; more workers would only wait
        await concurrently(tracks, width: Self.parallelDownloads) { entry in
            let result: Result<DownloadOutcome, Error>
            do { result = .success(try await self.download(entry.track, cover: entry.cover)) }
            catch { result = .failure(error) }
            await tally.add(result)
            if let finished {
                let done: Bool
                if case .success = result { done = true } else { done = false }
                await finished(entry.track.id, done)
            }
        }
        let (saved, firstError) = await tally.total
        if saved == 0, let firstError { throw firstError }
        return saved > 0
    }

    private func save(_ track: Track, audio: Data, durationSeconds: Double, cover: String?) async throws {
        let audioFile = Downloads.directory.appending(path: "\(track.id).m4a")
        try audio.write(to: audioFile)
        var imagePath: String?
        if let cover, !cover.isEmpty {
            let imageFile = Downloads.directory.appending(path: "\(track.id).png")
            let bytes: Data? =
                if cover.hasPrefix("http"), let url = URL(string: cover) {
                    try? await session.data(from: url).0
                } else {
                    try? Data(contentsOf: cover.hasPrefix("file:") ? URL(string: cover)! : URL(filePath: cover))
                }
            if let bytes, (try? bytes.write(to: imageFile)) != nil { imagePath = imageFile.path }
        }
        try await database.addDownload(
            stid: track.id, audioPath: audioFile.path, artists: track.artists, title: track.name,
            durationMilliseconds: Int(durationSeconds * 1000), imagePath: imagePath)
        // Lyrics are matched by length, which is known now
        if let lyrics {
            let found = await lyrics.fetch(
                name: track.name, artist: track.artists.first?.name ?? "", album: track.album?.name ?? "",
                durationSeconds: Int(durationSeconds))
            Downloads.saveLyrics(found, for: track.id)
        }
    }

    /// Downloads the audio of the downloaded [track] again, after the server
    /// changed which recording it plays, now [durationSeconds] long, with
    /// lyrics that fit it. Returns whether the track was downloaded.
    @discardableResult
    public func refreshAudio(of track: Track, durationSeconds: Double) async throws -> Bool {
        guard try await database.isDownloaded(track.id) else { return false }
        let audio = try await fetchAudio(track.id)
        try audio.write(to: Downloads.directory.appending(path: "\(track.id).m4a"), options: .atomic)
        if durationSeconds > 0 {
            try await database.setDownloadDuration(track.id, milliseconds: Int(durationSeconds * 1000))
            if let lyrics {
                let found = await lyrics.fetch(
                    name: track.name, artist: track.artists.first?.name ?? "", album: track.album?.name ?? "",
                    durationSeconds: Int(durationSeconds))
                Downloads.saveLyrics(found, for: track.id)
            }
        }
        return true
    }

    /// Deletes the tracks with [stids] and their files.
    public func remove(_ stids: [String]) async throws {
        try await database.removeDownloads(stids)
        for stid in stids {
            for name in ["\(stid).m4a", "\(stid).png", "\(stid).lyrics.json"] {
                try? FileManager.default.removeItem(at: Downloads.directory.appending(path: name))
            }
        }
    }
}
