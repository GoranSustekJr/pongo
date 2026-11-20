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
    /// The month, as `yyyy-MM`, or the year for a year's stats.
    public var month: String
    public var plays: Int
    public var seconds: Double
    /// How many different tracks were played.
    public var trackCount: Int
    /// The most played tracks, most first.
    public var tracks: [PlayStat]
    public var artists: [ArtistStat]
}

/// What the user listened to in a year, and in each of its months.
public struct YearStats: Sendable, Equatable {
    public struct Month: Sendable, Equatable, Identifiable {
        /// `yyyy-MM`.
        public var month: String
        public var plays: Int
        public var seconds: Double
        public var id: String { month }
    }

    /// The year's totals, top tracks and artists; its `month` is the year.
    public var total: MonthStats
    /// The months with plays, in order.
    public var months: [Month]
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
        try stats(month, months: "month = ?", limit: limit)
    }

    /// What was played in [year], `yyyy`, with each month's share.
    public func yearStats(_ year: String, limit: Int = 50) throws -> YearStats {
        let total = try stats(year, months: "month LIKE ? || '-%'", limit: limit)
        let months = try db.query(
            """
            SELECT month, SUM(plays) AS plays, SUM(seconds) AS seconds FROM play_counts
            WHERE month LIKE ? || '-%' GROUP BY month HAVING SUM(plays) > 0 ORDER BY month
            """, [.text(year)]
        ).compactMap { row -> YearStats.Month? in
            guard let month = row["month"]?.text else { return nil }
            return YearStats.Month(month: month, plays: row["plays"]?.int ?? 0, seconds: row["seconds"]?.double ?? 0)
        }
        return YearStats(total: total, months: months)
    }

    /// The years with plays, latest first.
    public func playYears() throws -> [String] {
        Array(Set(try playMonths().map { String($0.prefix(4)) })).sorted(by: >)
    }

    /// What was played in the months [condition] picks with [period].
    private func stats(_ period: String, months condition: String, limit: Int) throws -> MonthStats {
        let rows = try db.query(
            """
            SELECT stid, SUM(plays) AS plays, SUM(seconds) AS seconds, MAX(track) AS track
            FROM play_counts WHERE \(condition) GROUP BY stid HAVING SUM(plays) > 0
            ORDER BY SUM(plays) DESC, SUM(seconds) DESC
            """, [.text(period)])
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
            month: period, plays: all.reduce(0) { $0 + $1.plays }, seconds: all.reduce(0) { $0 + $1.seconds },
            trackCount: all.count, tracks: Array(all.prefix(limit)),
            artists: Array(artists.values.sorted { $0.plays > $1.plays }.prefix(10)))
    }
}

/// The library on the device belongs to one account at a time.
extension Database {
    /// The tables of what syncs with the account, which go when it signs out.
    /// Downloaded songs stay: they're files on this device, which any
    /// account can play.
    static let accountTables = [
        "favourites", "opid_stid", "online_playlist", "lpid_track_id", "local_playlist", "lfh_tracks",
        "lfh_artists", "search_history", "sleep", "lyrics_sync_time_delay", "play_counts",
    ]

    /// The user ID of the account the library is of, if known.
    public func libraryOwner() throws -> String? {
        try db.query("SELECT value FROM play_meta WHERE name = 'owner'").first?["value"]?.text
    }

    public func setLibraryOwner(_ account: String) throws {
        try db.execute("INSERT OR REPLACE INTO play_meta (name, value) VALUES ('owner', ?)", [.text(account)])
    }

    /// Removes the account's library from the device, so another account
    /// starts with its own.
    public func clearLibrary() throws {
        try db.transaction {
            for table in Self.accountTables { try db.execute("DELETE FROM \(table)") }
            try db.execute("DELETE FROM play_meta WHERE name = 'owner'")
        }
    }
}
