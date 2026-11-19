import Foundation

/// Plain and time synced lyrics of a track.
public struct Lyrics: Sendable, Equatable, Codable {
    public var plain: String
    /// LRC formatted lines, such as `[00:12.34] Hello`.
    public var synced: String

    public static let empty = Lyrics(plain: "", synced: "")

    public var isEmpty: Bool { plain.isEmpty && synced.isEmpty }
}

/// Calls to the LRCLIB lyrics database.
public final class LyricsClient: Sendable {
    private let session: URLSession

    public init(session: URLSession = .shared) { self.session = session }

    /// The lyrics of a track, or empty lyrics if none are found.
    ///
    /// Looks the track up exactly first and falls back to a search that
    /// prefers synced lyrics with the closest duration.
    public func fetch(name: String, artist: String, album: String, durationSeconds: Int) async
        -> Lyrics
    {
        if let data = await get(
            "/api/get",
            [
                "artist_name": artist, "track_name": name, "duration": String(durationSeconds),
                "album_name": album,
            ]),
            data["syncedLyrics"]?.string != nil, data["plainLyrics"]?.string != nil
        {
            return lyrics(data)
        }
        guard let results = await get("/api/search", ["q": "\(name) - \(artist)"])?.array,
            !results.isEmpty
        else { return .empty }
        let synced = results.filter { $0["syncedLyrics"]?.string != nil }
        guard !synced.isEmpty else { return lyrics(results[0]) }
        func distance(_ result: JSONValue) -> Double {
            abs((result["duration"]?.double ?? 0).rounded(.towardZero) - Double(durationSeconds))
        }
        return lyrics(synced.min { distance($0) < distance($1) }!)
    }

    private func get(_ path: String, _ query: [String: String]) async -> JSONValue? {
        var components = URLComponents(string: "https://lrclib.net")!
        components.path = path
        components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        guard let url = components.url,
            let (data, response) = try? await session.data(from: url),
            (response as? HTTPURLResponse)?.statusCode == 200
        else { return nil }
        return try? JSONValue.decode(data)
    }

    private func lyrics(_ data: JSONValue) -> Lyrics {
        Lyrics(plain: data["plainLyrics"]?.string ?? "", synced: data["syncedLyrics"]?.string ?? "")
    }
}

/// A line of synced lyrics.
public struct LyricsLine: Sendable, Hashable, Identifiable {
    public var id: Int
    /// When the line starts, in seconds.
    public var time: Double
    public var text: String
}

extension Lyrics {
    /// The synced lyrics as timed lines, in order.
    public var syncedLines: [LyricsLine] {
        var lines: [LyricsLine] = []
        for raw in synced.split(whereSeparator: \.isNewline) {
            var rest = Substring(raw)
            var times: [Double] = []
            // A line can carry several time tags, such as a repeated chorus
            while rest.hasPrefix("["), let close = rest.firstIndex(of: "]") {
                let tag = rest[rest.index(after: rest.startIndex)..<close]
                if let time = Self.seconds(tag) { times.append(time) }
                rest = rest[rest.index(after: close)...]
            }
            let text = rest.trimmingCharacters(in: .whitespaces)
            for time in times {
                lines.append(LyricsLine(id: 0, time: time, text: text))
            }
        }
        return lines.sorted { $0.time < $1.time }.enumerated().map { index, line in
            LyricsLine(id: index, time: line.time, text: line.text)
        }
    }

    /// Seconds in an LRC time tag such as `01:02.34`.
    static func seconds(_ tag: Substring) -> Double? {
        let parts = tag.split(separator: ":")
        guard parts.count == 2, let minutes = Double(parts[0]), let seconds = Double(parts[1])
        else { return nil }
        return minutes * 60 + seconds
    }
}
