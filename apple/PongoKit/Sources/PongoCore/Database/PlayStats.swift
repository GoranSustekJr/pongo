import Foundation

/// How often a track was played in a month, and for how long.
public struct PlayStat: Sendable, Identifiable, Equatable {
    public var track: Track
    public var plays: Int
    public var seconds: Double
    public var id: String { track.id }
}

/// An artist's plays in a month.
public struct ArtistStat: Sendable, Identifiable, Equatable {
    public var artist: ArtistRef
    public var plays: Int
    public var id: String { artist.id }
}

/// What the user listened to in a month, on all their devices.
public struct MonthStats: Sendable, Equatable {
    /// The month, as `yyyy-MM`.
    public var month: String
    public var plays: Int
    public var seconds: Double
    /// How many different tracks were played.
    public var trackCount: Int
    /// The most played tracks, most first.
    public var tracks: [PlayStat]
    public var artists: [ArtistStat]
}

/// Plays counted per month, track and device, so devices syncing their counts
/// never overwrite each other's; the stats add them up.
extension Database {
    static let playStatsSchema = [
        """
        CREATE TABLE IF NOT EXISTS play_counts (
          month TEXT NOT NULL, device TEXT NOT NULL, stid TEXT NOT NULL,
          plays INTEGER NOT NULL DEFAULT 0, seconds REAL NOT NULL DEFAULT 0, track TEXT,
          PRIMARY KEY (month, device, stid))
        """,
        // Kept apart from sync_meta, which signing out clears
        "CREATE TABLE IF NOT EXISTS play_meta (name TEXT PRIMARY KEY, value TEXT)",
    ]

    /// The month [date] is in, as `yyyy-MM` in the user's calendar.
    public static func month(of date: Date) -> String {
        let parts = Calendar.current.dateComponents([.year, .month], from: date)
        return String(format: "%04d-%02d", parts.year ?? 0, parts.month ?? 0)
    }

    /// The ID this install counts its plays under.
    func playDevice() throws -> String {
        if let id = try db.query("SELECT value FROM play_meta WHERE name = 'device'").first?["value"]?.text {
            return id
        }
        let id = UUID().uuidString
        try db.execute("INSERT INTO play_meta (name, value) VALUES ('device', ?)", [.text(id)])
        return id
    }

    /// Adds [seconds] of listening to [track] in the month of [date], and a
    /// play if [newPlay].
    public func recordListen(_ track: Track, seconds: Double, newPlay: Bool, at date: Date = .now) throws {
        var stored = track
        stored.audioPath = nil
        stored.localImagePath = nil
        let json = String(decoding: try JSONEncoder().encode(stored), as: UTF8.self)
        try db.execute(
            """
            INSERT INTO play_counts (month, device, stid, plays, seconds, track) VALUES (?, ?, ?, ?, ?, ?)
            ON CONFLICT (month, device, stid) DO UPDATE SET
              plays = plays + excluded.plays, seconds = seconds + excluded.seconds, track = excluded.track
            """,
            [
                .text(Self.month(of: date)), .text(try playDevice()), .text(track.id), .int(newPlay ? 1 : 0),
                .double(seconds), .text(json),
            ])
    }

    /// The months with plays, latest first.
    public func playMonths() throws -> [String] {
        try db.query("SELECT DISTINCT month FROM play_counts WHERE plays > 0 ORDER BY month DESC")
            .compactMap { $0["month"]?.text }
    }

    /// What was played in [month], with its [limit] most played tracks.
    public func monthStats(_ month: String, limit: Int = 50) throws -> MonthStats {
        let rows = try db.query(
            """
            SELECT stid, SUM(plays) AS plays, SUM(seconds) AS seconds, MAX(track) AS track
            FROM play_counts WHERE month = ? GROUP BY stid HAVING SUM(plays) > 0
            ORDER BY SUM(plays) DESC, SUM(seconds) DESC
            """, [.text(month)])
        let all: [PlayStat] = rows.compactMap { row in
            guard let text = row["track"]?.text,
                let track = try? JSONDecoder().decode(Track.self, from: Data(text.utf8))
            else { return nil }
            return PlayStat(track: track, plays: row["plays"]?.int ?? 0, seconds: row["seconds"]?.double ?? 0)
        }
        var artists: [String: ArtistStat] = [:]
        for stat in all {
            for artist in stat.track.artists where !artist.id.isEmpty {
                artists[artist.id, default: ArtistStat(artist: artist, plays: 0)].plays += stat.plays
            }
        }
        return MonthStats(
            month: month, plays: all.reduce(0) { $0 + $1.plays }, seconds: all.reduce(0) { $0 + $1.seconds },
            trackCount: all.count, tracks: Array(all.prefix(limit)),
            artists: Array(artists.values.sorted { $0.plays > $1.plays }.prefix(10)))
    }
}
