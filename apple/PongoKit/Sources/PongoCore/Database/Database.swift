import Foundation

/// The app's SQLite database.
///
/// The tables and columns are the Flutter app's, so the library syncs between
/// the two apps item for item.
public actor Database {
    let db: SQLiteConnection

    /// Opens the database at [path], creating it as needed. `nil` opens one in
    /// memory, for tests.
    public init(path: String? = nil) throws {
        db = try SQLiteConnection(path: path ?? ":memory:")
        try Self.migrate(db)
        try Self.countLibraryChanges(db)
    }

    /// The tables other devices should get changes to soon. Listening history
    /// and play counts change all through playback, so they go with the
    /// regular sync instead.
    static let libraryTables = [
        "favourites", "online_playlist", "opid_stid", "local_playlist", "lpid_track_id", "sleep",
        "lyrics_sync_time_delay",
    ]

    /// Counts changes to [libraryTables] in `temp.library_changes`, for
    /// [changeCount].
    private static func countLibraryChanges(_ db: SQLiteConnection) throws {
        try db.execute("CREATE TEMP TABLE IF NOT EXISTS library_changes (count INTEGER NOT NULL)")
        try db.execute("INSERT INTO library_changes SELECT 0 WHERE NOT EXISTS (SELECT 1 FROM library_changes)")
        for table in libraryTables {
            for event in ["INSERT", "UPDATE", "DELETE"] {
                try db.execute(
                    """
                    CREATE TEMP TRIGGER IF NOT EXISTS \(table)_\(event.lowercased())_counted
                    AFTER \(event) ON main.\(table) BEGIN UPDATE library_changes SET count = count + 1; END
                    """)
            }
        }
    }

    /// The database in the app's Application Support directory.
    public static func appDatabase() throws -> Database {
        let directory = URL.applicationSupportDirectory
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return try Database(path: directory.appending(path: "pongo.sqlite").path)
    }

    private static let version = 2

    private static func migrate(_ db: SQLiteConnection) throws {
        guard db.userVersion < version else { return }
        try db.transaction {
            if db.userVersion < 1 {
                for sql in schema { try db.execute(sql) }
            }
            if db.userVersion < 2 {
                for sql in playStatsSchema { try db.execute(sql) }
            }
        }
        db.userVersion = version
    }

    private static let schema = [
        """
        CREATE TABLE IF NOT EXISTS online_playlist (
          opid INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, cover BLOB, sync_id TEXT)
        """,
        """
        CREATE TABLE IF NOT EXISTS opid_stid (
          opid INTEGER, stid TEXT, title TEXT, artists TEXT, image TEXT, album TEXT,
          order_number INT, hidden BOOLEAN, FOREIGN KEY(opid) REFERENCES online_playlist(opid))
        """,
        """
        CREATE TABLE IF NOT EXISTS favourites (
          id INTEGER PRIMARY KEY AUTOINCREMENT, stid TEXT, title TEXT, artists TEXT,
          image TEXT, album TEXT)
        """,
        """
        CREATE TABLE IF NOT EXISTS search_history (
          id INTEGER PRIMARY KEY AUTOINCREMENT, query TEXT, played_at INTEGER)
        """,
        """
        CREATE TABLE IF NOT EXISTS lfh_artists (
          id INTEGER PRIMARY KEY AUTOINCREMENT, said TEXT, played_at INTEGER)
        """,
        """
        CREATE TABLE IF NOT EXISTS lfh_tracks (
          id INTEGER PRIMARY KEY AUTOINCREMENT, stid TEXT, played_at INTEGER)
        """,
        """
        CREATE TABLE IF NOT EXISTS downloaded_tracks (
          id INTEGER PRIMARY KEY AUTOINCREMENT, stid TEXT, audio TEXT, artists TEXT,
          title TEXT, duration INT, image TEXT, lyrics_sync TEXT, lyrics_plain TEXT)
        """,
        """
        CREATE TABLE IF NOT EXISTS local_playlist (
          lpid INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, cover BLOB, sync_id TEXT)
        """,
        """
        CREATE TABLE IF NOT EXISTS lpid_track_id (
          lpid INTEGER, track_id TEXT, order_number INT, hidden BOOLEAN,
          FOREIGN KEY(lpid) REFERENCES local_playlist(lpid))
        """,
        "CREATE TABLE IF NOT EXISTS lyrics_sync_time_delay (stid TEXT, sync_time_delay INTEGER)",
        """
        CREATE TABLE IF NOT EXISTS sleep (
          id INTEGER PRIMARY KEY AUTOINCREMENT, sleep BOOLEAN, sleep_duration INTEGER,
          sleep_linear BOOLEAN, alarm_clock BOOLEAN, wake_time INTEGER,
          before_end_time_min INTEGER, alarm_clock_linear BOOLEAN, sync_id TEXT)
        """,
        "CREATE TABLE IF NOT EXISTS track_gain (stid TEXT PRIMARY KEY, gain REAL NOT NULL)",
        """
        CREATE TABLE IF NOT EXISTS sync_state (
          kind TEXT NOT NULL, key TEXT NOT NULL, hash TEXT, changed_at INTEGER NOT NULL,
          dirty INTEGER NOT NULL, PRIMARY KEY (kind, key))
        """,
        "CREATE TABLE IF NOT EXISTS sync_meta (name TEXT PRIMARY KEY, value TEXT)",
    ]

    func count(_ sql: String, _ arguments: [SQLValue] = []) throws -> Int {
        try db.query(sql, arguments).first?.values.first?.int ?? 0
    }

    static func now() -> Int { Int(Date().timeIntervalSince1970 * 1000) }
}

// MARK: - Favourites

extension Database {
    /// All favourites, most recently added first.
    public func favourites() throws -> [Favourite] {
        try db.query("SELECT * FROM favourites ORDER BY id DESC").map(Self.favourite)
    }

    static func favourite(_ row: SQLRow) -> Favourite {
        Favourite(
            id: row["id"]?.int ?? 0, stid: row["stid"]?.text ?? "", title: row["title"]?.text ?? "",
            artists: ArtistRef.decodeList(row["artists"]?.text),
            album: AlbumRef.decode(row["album"]?.text), image: row["image"]?.text)
    }

    public func favouriteCount() throws -> Int { try count("SELECT COUNT(*) FROM favourites") }

    public func isFavourite(_ stid: String) throws -> Bool {
        try !db.query("SELECT stid FROM favourites WHERE stid = ?", [.text(stid)]).isEmpty
    }

    /// Adds [favourite] unless its track is already a favourite.
    public func addFavourite(_ favourite: Favourite) throws {
        guard try !isFavourite(favourite.stid) else { return }
        try db.execute(
            "INSERT INTO favourites (stid, title, artists, image, album) VALUES (?, ?, ?, ?, ?)",
            [
                .text(favourite.stid), .text(favourite.title),
                .text(ArtistRef.encodeList(favourite.artists)), SQLValue(favourite.image),
                SQLValue(favourite.album?.encoded),
            ])
    }

    /// Adds those of [favourites] that aren't favourites yet, in one go.
    /// Returns how many were added.
    public func addFavourites(_ favourites: [Favourite]) throws -> Int {
        try db.transaction {
            var added = 0
            for favourite in favourites where try !isFavourite(favourite.stid) {
                try addFavourite(favourite)
                added += 1
            }
            return added
        }
    }

    /// Adds [favourite], or removes it if it's already a favourite. Returns
    /// whether the track is a favourite afterwards.
    public func toggleFavourite(_ favourite: Favourite) throws -> Bool {
        if try isFavourite(favourite.stid) {
            try removeFavourites([favourite.stid])
            return false
        }
        try addFavourite(favourite)
        return true
    }

    public func removeFavourites(_ stids: [String]) throws {
        guard !stids.isEmpty else { return }
        try db.execute(
            "DELETE FROM favourites WHERE stid IN (\(placeholders(stids.count)))",
            stids.map(SQLValue.text))
    }
}

// MARK: - Downloads

extension Database {
    /// All downloaded tracks, sorted by title.
    public func downloads() throws -> [DownloadedTrack] {
        try db.query("SELECT * FROM downloaded_tracks ORDER BY title ASC").map(Self.download)
    }

    static func download(_ row: SQLRow) -> DownloadedTrack {
        DownloadedTrack(
            track: Track(
                id: row["stid"]?.text ?? "", name: row["title"]?.text ?? "",
                artists: ArtistRef.decodeList(row["artists"]?.text), album: nil,
                localImagePath: row["image"]?.text.map(Downloads.currentPath),
                audioPath: row["audio"]?.text.map(Downloads.currentPath)),
            durationMilliseconds: row["duration"]?.int ?? 0, rowID: row["id"]?.int ?? 0,
            hidden: row["hidden"]?.isTrue ?? false)
    }

    public func downloadCount() throws -> Int { try count("SELECT COUNT(*) FROM downloaded_tracks") }

    public func isDownloaded(_ stid: String) throws -> Bool {
        try !db.query("SELECT stid FROM downloaded_tracks WHERE stid = ?", [.text(stid)]).isEmpty
    }

    /// The IDs in [stids] that aren't downloaded, in their original order.
    public func missingDownloads(_ stids: [String]) throws -> [String] {
        guard !stids.isEmpty else { return [] }
        let existing = Set(
            try db.query(
                "SELECT stid FROM downloaded_tracks WHERE stid IN (\(placeholders(stids.count)))",
                stids.map(SQLValue.text)
            ).compactMap { $0["stid"]?.text })
        return stids.filter { !existing.contains($0) }
    }

    /// Records a downloaded track unless one with [stid] already exists.
    public func addDownload(
        stid: String, audioPath: String, artists: [ArtistRef], title: String,
        durationMilliseconds: Int, imagePath: String?
    ) throws {
        guard try !isDownloaded(stid) else { return }
        try db.execute(
            """
            INSERT INTO downloaded_tracks (stid, audio, artists, title, duration, image)
            VALUES (?, ?, ?, ?, ?, ?)
            """,
            [
                .text(stid), .text(audioPath), .text(ArtistRef.encodeList(artists)), .text(title),
                .int(durationMilliseconds), SQLValue(imagePath),
            ])
    }

    /// Removes the tracks with [stids] and their local playlist entries,
    /// renumbering the playlists that held them.
    public func removeDownloads(_ stids: [String]) throws {
        guard !stids.isEmpty else { return }
        let inClause = placeholders(stids.count)
        let ids = stids.map(SQLValue.text)
        try db.transaction {
            try db.execute("DELETE FROM downloaded_tracks WHERE stid IN (\(inClause))", ids)
            let affected = try db.query(
                "SELECT DISTINCT lpid FROM lpid_track_id WHERE track_id IN (\(inClause))", ids)
            for row in affected {
                let lpid = row["lpid"] ?? .null
                try db.execute(
                    "DELETE FROM lpid_track_id WHERE lpid = ? AND track_id IN (\(inClause))",
                    [lpid] + ids)
                let remaining = try db.query(
                    "SELECT track_id FROM lpid_track_id WHERE lpid = ? ORDER BY order_number ASC",
                    [lpid])
                for (order, track) in remaining.enumerated() {
                    try db.execute(
                        "UPDATE lpid_track_id SET order_number = ? WHERE lpid = ? AND track_id = ?",
                        [.int(order + 1), lpid, track["track_id"] ?? .null])
                }
            }
        }
    }
}

// MARK: - Online playlists

extension Database {
    /// All online playlists, newest first.
    public func onlinePlaylists() throws -> [UserPlaylist] {
        try db.query("SELECT * FROM online_playlist ORDER BY opid DESC").map {
            UserPlaylist(id: $0["opid"]?.int ?? 0, title: $0["title"]?.text ?? "", cover: $0["cover"]?.blob)
        }
    }

    public func onlinePlaylistCount() throws -> Int { try count("SELECT COUNT(*) FROM online_playlist") }

    /// Creates an online playlist and returns its ID.
    public func createOnlinePlaylist(_ title: String, cover: Data?) throws -> Int {
        try db.execute(
            "INSERT INTO online_playlist (title, cover) VALUES (?, ?)", [.text(title), SQLValue(cover)])
        return db.lastInsertID
    }

    /// The tracks of online playlist [opid], in order.
    public func onlineTracks(_ opid: Int) throws -> [OnlinePlaylistTrack] {
        try db.query("SELECT * FROM opid_stid WHERE opid = ? ORDER BY order_number ASC", [.int(opid)])
            .map { row in
                OnlinePlaylistTrack(
                    opid: row["opid"]?.int ?? opid, stid: row["stid"]?.text ?? "",
                    title: row["title"]?.text ?? "",
                    artists: ArtistRef.decodeList(row["artists"]?.text),
                    album: AlbumRef.decode(row["album"]?.text), image: row["image"]?.text,
                    orderNumber: row["order_number"]?.int ?? 0, hidden: row["hidden"]?.isTrue ?? false)
            }
    }

    /// The number of tracks shown in online playlist [opid].
    public func onlineTrackCount(_ opid: Int) throws -> Int {
        try count("SELECT COUNT(*) FROM opid_stid WHERE opid = ? AND hidden = 0", [.int(opid)])
    }

    /// Appends [track] to its playlist unless it's already there. Returns
    /// whether it was added.
    @discardableResult
    public func addOnlineTrack(_ track: OnlinePlaylistTrack) throws -> Bool {
        let existing = try db.query(
            "SELECT stid FROM opid_stid WHERE opid = ? AND stid = ?", [.int(track.opid), .text(track.stid)])
        guard existing.isEmpty else { return false }
        let maxOrder = try db.query(
            "SELECT MAX(order_number) AS max_order FROM opid_stid WHERE opid = ?", [.int(track.opid)]
        ).first?["max_order"]?.int ?? -1
        try insertOnlineTrack(track, opid: track.opid, order: maxOrder + 1)
        return true
    }

    /// Appends those of [tracks] playlist [opid] doesn't have yet, in order, in
    /// one go. Returns how many were added.
    public func addOnlineTracks(_ opid: Int, _ tracks: [OnlinePlaylistTrack]) throws -> Int {
        try db.transaction {
            var existing = Set(
                try db.query("SELECT stid FROM opid_stid WHERE opid = ?", [.int(opid)]).compactMap { $0["stid"]?.text })
            var order = try db.query(
                "SELECT MAX(order_number) AS max_order FROM opid_stid WHERE opid = ?", [.int(opid)]
            ).first?["max_order"]?.int ?? -1
            var added = 0
            for track in tracks where existing.insert(track.stid).inserted {
                order += 1
                try insertOnlineTrack(track, opid: opid, order: order)
                added += 1
            }
            return added
        }
    }

    private func insertOnlineTrack(_ track: OnlinePlaylistTrack, opid: Int, order: Int) throws {
        try db.execute(
            """
            INSERT INTO opid_stid (opid, stid, title, artists, image, album, order_number, hidden)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """,
            [
                .int(opid), .text(track.stid), .text(track.title),
                .text(ArtistRef.encodeList(track.artists)), SQLValue(track.image),
                SQLValue(track.album?.encoded), .int(order), SQLValue(track.hidden),
            ])
    }

    /// Rewrites online playlist [opid] to hold [tracks] in this order.
    public func reorderOnlineTracks(_ opid: Int, _ tracks: [OnlinePlaylistTrack]) throws {
        try db.transaction {
            try db.execute("DELETE FROM opid_stid WHERE opid = ?", [.int(opid)])
            for (index, track) in tracks.enumerated() {
                try insertOnlineTrack(track, opid: opid, order: index + 1)
            }
        }
    }

    public func renameOnlinePlaylist(_ opid: Int, _ title: String) throws {
        try db.execute("UPDATE online_playlist SET title = ? WHERE opid = ?", [.text(title), .int(opid)])
    }

    public func setOnlinePlaylistCover(_ opid: Int, _ cover: Data) throws {
        try db.execute("UPDATE online_playlist SET cover = ? WHERE opid = ?", [.blob(cover), .int(opid)])
    }

    public func setOnlineTracksHidden(_ opid: Int, _ stids: [String], hidden: Bool) throws {
        guard !stids.isEmpty else { return }
        try db.execute(
            "UPDATE opid_stid SET hidden = ? WHERE opid = ? AND stid IN (\(placeholders(stids.count)))",
            [SQLValue(hidden), .int(opid)] + stids.map(SQLValue.text))
    }

    public func removeOnlineTracks(_ opid: Int, _ stids: [String]) throws {
        guard !stids.isEmpty else { return }
        try db.execute(
            "DELETE FROM opid_stid WHERE opid = ? AND stid IN (\(placeholders(stids.count)))",
            [.int(opid)] + stids.map(SQLValue.text))
    }

    public func deleteOnlinePlaylist(_ opid: Int) throws {
        try db.transaction {
            try db.execute("DELETE FROM opid_stid WHERE opid = ?", [.int(opid)])
            try db.execute("DELETE FROM online_playlist WHERE opid = ?", [.int(opid)])
        }
    }
}

// MARK: - Local playlists

extension Database {
    /// All local playlists, newest first.
    public func localPlaylists() throws -> [UserPlaylist] {
        try db.query("SELECT * FROM local_playlist ORDER BY lpid DESC").map {
            UserPlaylist(id: $0["lpid"]?.int ?? 0, title: $0["title"]?.text ?? "", cover: $0["cover"]?.blob)
        }
    }

    public func localPlaylistCount() throws -> Int { try count("SELECT COUNT(*) FROM local_playlist") }

    /// Creates a local playlist and returns its ID.
    public func createLocalPlaylist(_ title: String, cover: Data?) throws -> Int {
        try db.execute(
            "INSERT INTO local_playlist (title, cover) VALUES (?, ?)", [.text(title), SQLValue(cover)])
        return db.lastInsertID
    }

    /// The downloaded tracks of local playlist [lpid], in order.
    public func localTracks(_ lpid: Int) throws -> [DownloadedTrack] {
        try db.query(
            """
            SELECT ltid.track_id, ltid.order_number, ltid.hidden, dt.id, dt.stid, dt.audio,
              dt.artists, dt.title, dt.duration, dt.image
            FROM lpid_track_id ltid JOIN downloaded_tracks dt ON ltid.track_id = dt.stid
            WHERE ltid.lpid = ? ORDER BY ltid.order_number ASC
            """, [.int(lpid)]
        ).map(Self.download)
    }

    public func localTrackCount(_ lpid: Int) throws -> Int {
        try count("SELECT COUNT(*) FROM lpid_track_id WHERE lpid = ?", [.int(lpid)])
    }

    /// Appends the downloaded track [stid] to local playlist [lpid] unless
    /// it's already there. Returns whether it was added.
    @discardableResult
    public func addLocalTrack(_ lpid: Int, _ stid: String) throws -> Bool {
        let existing = try db.query(
            "SELECT track_id FROM lpid_track_id WHERE lpid = ? AND track_id = ?", [.int(lpid), .text(stid)])
        guard existing.isEmpty else { return false }
        let maxOrder = try db.query(
            "SELECT MAX(order_number) AS max_order FROM lpid_track_id WHERE lpid = ?", [.int(lpid)]
        ).first?["max_order"]?.int ?? -1
        try db.execute(
            "INSERT INTO lpid_track_id (lpid, track_id, order_number, hidden) VALUES (?, ?, ?, 0)",
            [.int(lpid), .text(stid), .int(maxOrder + 1)])
        return true
    }

    /// Rewrites the order of local playlist [lpid] to match [stids], keeping
    /// which tracks are hidden.
    public func reorderLocalTracks(_ lpid: Int, _ stids: [String]) throws {
        try db.transaction {
            var hidden: [String: SQLValue] = [:]
            for row in try db.query("SELECT track_id, hidden FROM lpid_track_id WHERE lpid = ?", [.int(lpid)]) {
                if let id = row["track_id"]?.text { hidden[id] = row["hidden"] }
            }
            try db.execute("DELETE FROM lpid_track_id WHERE lpid = ?", [.int(lpid)])
            for (index, stid) in stids.enumerated() {
                try db.execute(
                    "INSERT INTO lpid_track_id (lpid, track_id, order_number, hidden) VALUES (?, ?, ?, ?)",
                    [.int(lpid), .text(stid), .int(index + 1), hidden[stid] ?? .null])
            }
        }
    }

    public func renameLocalPlaylist(_ lpid: Int, _ title: String) throws {
        try db.execute("UPDATE local_playlist SET title = ? WHERE lpid = ?", [.text(title), .int(lpid)])
    }

    public func setLocalPlaylistCover(_ lpid: Int, _ cover: Data) throws {
        try db.execute("UPDATE local_playlist SET cover = ? WHERE lpid = ?", [.blob(cover), .int(lpid)])
    }

    public func setLocalTracksHidden(_ lpid: Int, _ stids: [String], hidden: Bool) throws {
        guard !stids.isEmpty else { return }
        try db.execute(
            "UPDATE lpid_track_id SET hidden = ? WHERE lpid = ? AND track_id IN (\(placeholders(stids.count)))",
            [SQLValue(hidden), .int(lpid)] + stids.map(SQLValue.text))
    }

    public func removeLocalTracks(_ lpid: Int, _ stids: [String]) throws {
        guard !stids.isEmpty else { return }
        try db.execute(
            "DELETE FROM lpid_track_id WHERE lpid = ? AND track_id IN (\(placeholders(stids.count)))",
            [.int(lpid)] + stids.map(SQLValue.text))
    }

    public func deleteLocalPlaylist(_ lpid: Int) throws {
        try db.transaction {
            try db.execute("DELETE FROM lpid_track_id WHERE lpid = ?", [.int(lpid)])
            try db.execute("DELETE FROM local_playlist WHERE lpid = ?", [.int(lpid)])
        }
    }
}

// MARK: - History

extension Database {
    /// The history tables keep this many entries each.
    static let historyLimit = 500

    /// Past search queries, latest first.
    public func searches() throws -> [String] {
        try history("search_history", "query", limit: nil)
    }

    /// Moves [query] to the top of the search history.
    public func addSearch(_ query: String) throws { try addHistory("search_history", "query", query) }

    public func removeSearch(_ query: String) throws {
        try db.execute("DELETE FROM search_history WHERE query = ?", [.text(query)])
    }

    public func clearSearches() throws { try db.execute("DELETE FROM search_history") }

    /// IDs of recently played tracks, latest first.
    public func playedTracks(limit: Int? = nil) throws -> [String] {
        try history("lfh_tracks", "stid", limit: limit)
    }

    public func addPlayedTrack(_ stid: String) throws { try addHistory("lfh_tracks", "stid", stid) }

    /// IDs of recently viewed artists, latest first.
    public func viewedArtists(limit: Int? = nil) throws -> [String] {
        try history("lfh_artists", "said", limit: limit)
    }

    public func addViewedArtist(_ said: String) throws { try addHistory("lfh_artists", "said", said) }

    private func history(_ table: String, _ column: String, limit: Int?) throws -> [String] {
        let limitClause = limit.map { " LIMIT \($0)" } ?? ""
        return try db.query("SELECT \(column) FROM \(table) ORDER BY played_at DESC, id DESC\(limitClause)")
            .compactMap { $0[column]?.text }
    }

    private func addHistory(_ table: String, _ column: String, _ value: String) throws {
        try db.transaction {
            try db.execute("DELETE FROM \(table) WHERE \(column) = ?", [.text(value)])
            try db.execute(
                "INSERT INTO \(table) (\(column), played_at) VALUES (?, ?)", [.text(value), .int(Self.now())])
            try trimHistory(table)
        }
    }

    func trimHistory(_ table: String) throws {
        try db.execute(
            """
            DELETE FROM \(table) WHERE id NOT IN (
              SELECT id FROM \(table) ORDER BY played_at DESC, id DESC LIMIT \(Self.historyLimit))
            """)
    }
}

// MARK: - Lyrics offsets, sleep alarms and loudness gains

extension Database {
    /// The saved lyrics offset of the track with [stid] in milliseconds.
    public func lyricsDelay(_ stid: String) throws -> Int {
        try db.query("SELECT sync_time_delay FROM lyrics_sync_time_delay WHERE stid = ?", [.text(stid)])
            .first?["sync_time_delay"]?.int ?? 0
    }

    public func saveLyricsDelay(_ stid: String, milliseconds: Int) throws {
        try db.execute(
            "UPDATE lyrics_sync_time_delay SET sync_time_delay = ? WHERE stid = ?",
            [.int(milliseconds), .text(stid)])
        if db.changes == 0 {
            try db.execute(
                "INSERT INTO lyrics_sync_time_delay (stid, sync_time_delay) VALUES (?, ?)",
                [.text(stid), .int(milliseconds)])
        }
    }

    static let alarmColumns = [
        "sleep", "sleep_duration", "sleep_linear", "alarm_clock", "wake_time",
        "before_end_time_min", "alarm_clock_linear",
    ]

    /// All sleep alarms, newest first.
    public func sleepAlarms() throws -> [SleepAlarm] {
        try db.query("SELECT * FROM sleep ORDER BY id DESC").map { row in
            var alarm = SleepAlarm(id: row["id"]?.int ?? 0)
            alarm.sleep = row["sleep"]?.isTrue ?? true
            alarm.sleepDuration = row["sleep_duration"]?.int ?? 30
            alarm.sleepLinear = row["sleep_linear"]?.isTrue ?? true
            alarm.alarmClock = row["alarm_clock"]?.isTrue ?? false
            alarm.wakeTime = row["wake_time"]?.int ?? 450
            alarm.beforeEndTimeMin = row["before_end_time_min"]?.int ?? 30
            alarm.alarmClockLinear = row["alarm_clock_linear"]?.isTrue ?? true
            return alarm
        }
    }

    private func alarmValues(_ alarm: SleepAlarm) -> [SQLValue] {
        [
            SQLValue(alarm.sleep), .int(alarm.sleepDuration), SQLValue(alarm.sleepLinear),
            SQLValue(alarm.alarmClock), .int(alarm.wakeTime), .int(alarm.beforeEndTimeMin),
            SQLValue(alarm.alarmClockLinear),
        ]
    }

    /// Saves [alarm] as a new alarm and returns it with its ID.
    public func addSleepAlarm(_ alarm: SleepAlarm) throws -> SleepAlarm {
        try db.execute(
            "INSERT INTO sleep (\(Self.alarmColumns.joined(separator: ", "))) VALUES (\(placeholders(7)))",
            alarmValues(alarm))
        var saved = alarm
        saved.id = db.lastInsertID
        return saved
    }

    public func updateSleepAlarm(_ alarm: SleepAlarm) throws {
        let assignments = Self.alarmColumns.map { "\($0) = ?" }.joined(separator: ", ")
        try db.execute("UPDATE sleep SET \(assignments) WHERE id = ?", alarmValues(alarm) + [.int(alarm.id)])
    }

    public func removeSleepAlarm(_ id: Int) throws {
        try db.execute("DELETE FROM sleep WHERE id = ?", [.int(id)])
    }

    /// The stored loudness gains of the tracks with [stids], in decibels.
    public func trackGains(_ stids: [String]) throws -> [String: Double] {
        guard !stids.isEmpty else { return [:] }
        var gains: [String: Double] = [:]
        for row in try db.query(
            "SELECT * FROM track_gain WHERE stid IN (\(placeholders(stids.count)))", stids.map(SQLValue.text))
        {
            if let stid = row["stid"]?.text, let gain = row["gain"]?.double { gains[stid] = gain }
        }
        return gains
    }

    public func removeTrackGains(_ stids: [String]) throws {
        guard !stids.isEmpty else { return }
        try db.execute(
            "DELETE FROM track_gain WHERE stid IN (\(placeholders(stids.count)))", stids.map(SQLValue.text))
    }

    public func saveTrackGains(_ gains: [String: Double]) throws {
        try db.transaction {
            for (stid, gain) in gains {
                try db.execute(
                    "INSERT OR REPLACE INTO track_gain (stid, gain) VALUES (?, ?)", [.text(stid), .double(gain)])
            }
        }
    }
}
