import Foundation

/// Reads playlists from files other services and tools export: Spotify's
/// account data (Playlist1.json, YourLibrary.json), CSV files from playlist
/// exporters, and the Music app's exported playlists (tab separated text).
public enum ImportFiles {
    /// The name Spotify's liked songs get when imported.
    public static let likedSongsName = "Liked Songs"

    /// The playlists in the file [name] with [data]; none if it holds none.
    public static func playlists(in data: Data, named name: String) -> [ImportPlaylist] {
        let base = (name as NSString).deletingPathExtension
        if let json = try? JSONValue.decode(data) {
            return spotifyExport(json, fileName: base)
        }
        guard let text = decodeText(data) else { return [] }
        return table(text, fileName: base)
    }

    // MARK: - Spotify account data

    /// Spotify's "Account data" download: Playlist*.json holds every playlist
    /// the account made or follows, YourLibrary.json the liked songs.
    static func spotifyExport(_ json: JSONValue, fileName: String) -> [ImportPlaylist] {
        if let playlists = json["playlists"]?.array {
            return playlists.enumerated().compactMap { index, playlist in
                var skipped = 0
                let songs = (playlist["items"]?.array ?? []).compactMap { item -> ImportSong? in
                    if let track = item["track"], !track.isNull, let song = spotifyTrack(track) { return song }
                    if let local = item["localTrack"]?["uri"]?.string, let song = spotifyLocalTrack(local) {
                        return song
                    }
                    skipped += 1
                    return nil
                }
                let name = playlist["name"]?.string?.trimmingCharacters(in: .whitespaces) ?? ""
                guard !songs.isEmpty || skipped > 0 else { return nil }
                return ImportPlaylist(
                    id: "spotify-file:\(fileName):\(index)",
                    name: name.isEmpty ? "\(fileName) \(index + 1)" : name, source: .spotify, songs: songs,
                    skipped: skipped)
            }
        }
        if let tracks = json["tracks"]?.array {
            let songs = tracks.compactMap { track -> ImportSong? in
                guard let title = track["track"]?.string, !title.isEmpty else { return nil }
                return ImportSong(
                    title: title, artists: [track["artist"]?.string].compactMap { $0 },
                    album: track["album"]?.string)
            }
            guard !songs.isEmpty else { return [] }
            return [
                ImportPlaylist(
                    id: "spotify-file:\(fileName):liked", name: likedSongsName, source: .spotify, songs: songs,
                    destination: .favourites)
            ]
        }
        return []
    }

    private static func spotifyTrack(_ track: JSONValue) -> ImportSong? {
        guard let title = track["trackName"]?.string, !title.isEmpty else { return nil }
        return ImportSong(
            title: title, artists: [track["artistName"]?.string].compactMap { $0 },
            album: track["albumName"]?.string)
    }

    /// spotify:local:Artist:Album:Title:Seconds, each part form encoded.
    static func spotifyLocalTrack(_ uri: String) -> ImportSong? {
        let parts = uri.split(separator: ":", omittingEmptySubsequences: false).map {
            String($0).replacingOccurrences(of: "+", with: " ").removingPercentEncoding ?? String($0)
        }
        guard parts.count >= 6, parts[0] == "spotify", parts[1] == "local", !parts[4].isEmpty else { return nil }
        return ImportSong(
            title: parts[4], artists: [parts[2]], album: parts[3], durationMs: Int(parts[5]).map { $0 * 1000 })
    }

    // MARK: - Tables

    private enum Column {
        case title, artist, album, duration, durationMs, isrc, playlist
    }

    private static let headers: [(Column, [String])] = [
        (.durationMs, ["duration (ms)", "duration_ms", "duration ms", "track duration (ms)", "length (ms)"]),
        (.duration, ["duration", "time", "length", "track duration", "zeit", "dauer", "trajanje", "vrijeme"]),
        (.isrc, ["isrc", "track isrc"]),
        (.playlist, ["playlist name", "playlist", "playlist title"]),
        (.album, ["album name", "album", "album title", "release", "album (name)"]),
        (.artist, [
            "artist name(s)", "artist name", "artist names", "artist", "artists", "artist(s)", "track artist",
            "künstler", "interpret", "izvođač",
        ]),
        (.title, ["track name", "track title", "song name", "song title", "title", "track", "song", "name", "titel", "naziv", "pjesma"]),
    ]

    /// A CSV or tab separated table with a header row naming its columns.
    static func table(_ text: String, fileName: String) -> [ImportPlaylist] {
        let rows = parseTable(text)
        guard let header = rows.first else { return [] }
        var columns: [Column: Int] = [:]
        let names = header.map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
        for (column, candidates) in headers {
            for candidate in candidates {
                if let index = names.firstIndex(of: candidate), !columns.values.contains(index) {
                    columns[column] = index
                    break
                }
            }
        }
        guard columns[.title] != nil else { return [] }
        // Exporters that name the column "Artist Name(s)" or "Artists" list several, comma separated
        let artistsListed = columns[.artist].map { names[$0].contains("(s)") || names[$0].hasSuffix("s") } ?? false

        var order: [String] = []
        var byPlaylist: [String: [ImportSong]] = [:]
        for row in rows.dropFirst() {
            func value(_ column: Column) -> String? {
                guard let index = columns[column], index < row.count else { return nil }
                return row[index].trimmingCharacters(in: .whitespaces).nilIfEmpty
            }
            guard let title = value(.title) else { continue }
            let artist = value(.artist) ?? ""
            let artists = artistsListed ? artist.split(separator: ",").map(String.init) : [artist]
            let duration = value(.durationMs).flatMap { Double($0) }.map { Int($0) } ?? value(.duration).flatMap(milliseconds)
            let song = ImportSong(title: title, artists: artists, album: value(.album), durationMs: duration, isrc: value(.isrc))
            let playlist = value(.playlist) ?? fileName
            if byPlaylist[playlist] == nil { order.append(playlist) }
            byPlaylist[playlist, default: []].append(song)
        }
        return order.map { name in
            ImportPlaylist(id: "file:\(fileName):\(name)", name: name, source: .file, songs: byPlaylist[name] ?? [])
        }
    }

    /// "3:25", "1:02:03", seconds or milliseconds as milliseconds.
    static func milliseconds(_ text: String) -> Int? {
        if text.contains(":") {
            let parts = text.split(separator: ":").compactMap { Double($0) }
            guard !parts.isEmpty else { return nil }
            return Int(parts.reduce(0) { $0 * 60 + $1 } * 1000)
        }
        guard let number = Double(text.replacingOccurrences(of: ",", with: ".")), number > 0 else { return nil }
        // No song is over 3 hours, so a bigger number counts milliseconds
        return Int(number > 10_800 ? number : number * 1000)
    }

    /// Rows of cells; quoted cells may hold the separator, quotes and line breaks.
    static func parseTable(_ text: String) -> [[String]] {
        let text = text.hasPrefix("\u{FEFF}") ? String(text.dropFirst()) : text
        let firstLine = text.prefix { $0 != "\n" && $0 != "\r" }
        let separator: Character = [Character("\t"), ";", ","].max { a, b in
            firstLine.filter { $0 == a }.count < firstLine.filter { $0 == b }.count
        } ?? ","

        var rows: [[String]] = []
        var row: [String] = []
        var cell = ""
        var quoted = false
        var iterator = text.makeIterator()
        var pending: Character?
        while let character = pending ?? iterator.next() {
            pending = nil
            if quoted {
                if character == "\"" {
                    let next = iterator.next()
                    if next == "\"" {
                        cell.append("\"")
                    } else {
                        quoted = false
                        pending = next
                    }
                } else {
                    cell.append(character)
                }
            } else if character == "\"" && cell.isEmpty {
                quoted = true
            } else if character == separator {
                row.append(cell)
                cell = ""
            } else if character == "\n" || character == "\r" || character == "\r\n" {
                row.append(cell)
                cell = ""
                if row.contains(where: { !$0.isEmpty }) { rows.append(row) }
                row = []
            } else {
                cell.append(character)
            }
        }
        row.append(cell)
        if row.contains(where: { !$0.isEmpty }) { rows.append(row) }
        return rows
    }

    /// UTF-8, or UTF-16 as the Music app writes, or Windows' Latin encoding.
    static func decodeText(_ data: Data) -> String? {
        if data.starts(with: [0xFF, 0xFE]) || data.starts(with: [0xFE, 0xFF]) {
            return String(data: data, encoding: .utf16)
        }
        return String(data: data, encoding: .utf8) ?? String(data: data, encoding: .windowsCP1252)
    }
}
