import Foundation

/// The database's library as sync items, in the Flutter app's format, and
/// what was synced of them in the `sync_state` and `sync_meta` tables.
extension Database: SyncSource, SyncStateStore {
    /// Covers larger than this stay on the device.
    static let maxCoverBytes = 1_000_000

    public nonisolated var kinds: Set<String> {
        [
            "favourite", "online_playlist", "local_playlist", "played_track", "played_artist",
            "search", "sleep_alarm", "lyrics_delay", "play_count",
        ]
    }

    public func snapshot() throws -> [SyncKey: SyncItem] {
        var items: [SyncKey: SyncItem] = [:]
        for kind in kinds {
            for (key, item) in try read(kind, key: nil) {
                items[SyncKey(kind: kind, key: key)] = item
            }
        }
        return items
    }

    public func item(_ key: SyncKey) throws -> SyncItem {
        try read(key.kind, key: key.key).first { $0.0 == key.key }?.1 ?? SyncItem(data: nil)
    }

    private func rows(_ table: String, _ keyColumn: String, _ key: String?) throws -> [SQLRow] {
        guard let key else { return try db.query("SELECT * FROM \(table)") }
        return try db.query("SELECT * FROM \(table) WHERE \(keyColumn) = ?", [.text(key)])
    }

    private func read(_ kind: String, key: String?) throws -> [(String, SyncItem)] {
        switch kind {
        case "favourite":
            return try rows("favourites", "stid", key).compactMap { row in
                guard let stid = row["stid"]?.text else { return nil }
                return (
                    stid,
                    SyncItem(data: [
                        "title": row["title"]?.json ?? .null, "artists": row["artists"]?.json ?? .null,
                        "image": row["image"]?.json ?? .null, "album": row["album"]?.json ?? .null,
                    ])
                )
            }
        case "online_playlist":
            return try rows("online_playlist", "sync_id", key).map { row in
                let tracks = try db.query(
                    "SELECT * FROM opid_stid WHERE opid = ? ORDER BY order_number ASC", [row["opid"] ?? .null]
                ).map { track -> JSONValue in
                    [
                        "stid": track["stid"]?.json ?? .null, "title": track["title"]?.json ?? .null,
                        "artists": track["artists"]?.json ?? .null, "image": track["image"]?.json ?? .null,
                        "album": track["album"]?.json ?? .null,
                        "hidden": .bool(track["hidden"]?.isTrue ?? false),
                    ]
                }
                var data: [String: JSONValue] = ["title": row["title"]?.json ?? .null, "tracks": .array(tracks)]
                data.merge(Self.cover(row["cover"])) { $1 }
                return (try syncID("online_playlist", "opid", row), SyncItem(data: data))
            }
        case "local_playlist":
            return try rows("local_playlist", "sync_id", key).map { row in
                let tracks = try db.query(
                    "SELECT * FROM lpid_track_id WHERE lpid = ? ORDER BY order_number ASC",
                    [row["lpid"] ?? .null]
                ).map { track -> JSONValue in
                    [
                        "track_id": track["track_id"]?.json ?? .null,
                        "hidden": .bool(track["hidden"]?.isTrue ?? false),
                    ]
                }
                var data: [String: JSONValue] = ["title": row["title"]?.json ?? .null, "tracks": .array(tracks)]
                data.merge(Self.cover(row["cover"])) { $1 }
                return (try syncID("local_playlist", "lpid", row), SyncItem(data: data))
            }
        case "played_track", "played_artist", "search":
            let (table, column) = Self.historyTable(kind)
            return try rows(table, column, key).compactMap { row in
                guard let id = row[column]?.text else { return nil }
                let at = row["played_at"]?.int
                return (id, SyncItem(data: ["at": JSONValue(at)], changedAt: at ?? 0))
            }
        case "sleep_alarm":
            return try rows("sleep", "sync_id", key).map { row in
                var data: [String: JSONValue] = [:]
                for column in Self.alarmColumns { data[column] = row[column]?.json ?? .null }
                return (try syncID("sleep", "id", row), SyncItem(data: data))
            }
        case "lyrics_delay":
            return try rows("lyrics_sync_time_delay", "stid", key).compactMap { row in
                guard let stid = row["stid"]?.text else { return nil }
                return (stid, SyncItem(data: ["ms": row["sync_time_delay"]?.json ?? .null]))
            }
        case "play_count":
            let parts = key.map(Self.playCountKey)
            let rows =
                if let parts {
                    try db.query(
                        "SELECT * FROM play_counts WHERE month = ? AND device = ? AND stid = ?",
                        parts.map(SQLValue.text))
                } else {
                    try db.query("SELECT * FROM play_counts")
                }
            return rows.compactMap { row in
                guard let month = row["month"]?.text, let device = row["device"]?.text, let stid = row["stid"]?.text
                else { return nil }
                let track = row["track"]?.text.flatMap { try? JSONValue.decode(Data($0.utf8)) } ?? .null
                return (
                    "\(month)|\(device)|\(stid)",
                    SyncItem(data: [
                        "plays": row["plays"]?.json ?? .int(0), "seconds": .double(row["seconds"]?.double ?? 0),
                        "track": track,
                    ])
                )
            }
        default:
            return []
        }
    }

    /// The month, device and track of a play count's key, `month|device|stid`.
    private static func playCountKey(_ key: String) -> [String] {
        let parts = key.split(separator: "|", maxSplits: 2).map(String.init)
        return parts.count == 3 ? parts : [key, "", ""]
    }

    /// The row's sync ID, giving it one first if it has none.
    private func syncID(_ table: String, _ idColumn: String, _ row: SQLRow) throws -> String {
        if let id = row["sync_id"]?.text { return id }
        let id = Self.newSyncID()
        try db.execute("UPDATE \(table) SET sync_id = ? WHERE \(idColumn) = ?", [.text(id), row[idColumn] ?? .null])
        return id
    }

    /// A random ID, unique for all practical purposes.
    static func newSyncID() -> String {
        (0..<16).map { _ in String(format: "%02x", UInt8.random(in: 0...255)) }.joined()
    }

    private static func cover(_ cover: SQLValue?) -> [String: JSONValue] {
        switch cover {
        case .blob(let bytes) where bytes.count <= maxCoverBytes: ["cover": .string(bytes.base64EncodedString())]
        // Too large to sync: other devices keep whatever cover they have
        case .blob: [:]
        default: ["cover": .null]
        }
    }

    private static func historyTable(_ kind: String) -> (String, String) {
        switch kind {
        case "played_track": ("lfh_tracks", "stid")
        case "played_artist": ("lfh_artists", "said")
        default: ("search_history", "query")
        }
    }

    public func apply(_ item: SyncKey, _ data: [String: JSONValue]?) throws {
        try db.transaction { try applyInTransaction(item, data) }
    }

    private func applyInTransaction(_ item: SyncKey, _ data: [String: JSONValue]?) throws {
        let key = SQLValue.text(item.key)
        switch item.kind {
        case "favourite":
            guard let data else {
                try db.execute("DELETE FROM favourites WHERE stid = ?", [key])
                return
            }
            let values = ["title", "artists", "image", "album"].map { SQLValue(json: data[$0]) }
            try db.execute(
                "UPDATE favourites SET title = ?, artists = ?, image = ?, album = ? WHERE stid = ?", values + [key])
            if db.changes == 0 {
                try db.execute(
                    "INSERT INTO favourites (stid, title, artists, image, album) VALUES (?, ?, ?, ?, ?)",
                    [key] + values)
            }
        case "online_playlist":
            try applyPlaylist(
                item.key, data, table: "online_playlist", idColumn: "opid", tracksTable: "opid_stid",
                trackColumns: ["stid", "title", "artists", "image", "album"])
        case "local_playlist":
            try applyPlaylist(
                item.key, data, table: "local_playlist", idColumn: "lpid", tracksTable: "lpid_track_id",
                trackColumns: ["track_id"])
        case "played_track", "played_artist", "search":
            let (table, column) = Self.historyTable(item.kind)
            try db.execute("DELETE FROM \(table) WHERE \(column) = ?", [key])
            if let at = data?["at"]?.int {
                try db.execute("INSERT INTO \(table) (\(column), played_at) VALUES (?, ?)", [key, .int(at)])
                try trimHistory(table)
            }
        case "sleep_alarm":
            guard let data else {
                try db.execute("DELETE FROM sleep WHERE sync_id = ?", [key])
                return
            }
            let values = Self.alarmColumns.map { SQLValue(json: data[$0]) }
            let assignments = Self.alarmColumns.map { "\($0) = ?" }.joined(separator: ", ")
            try db.execute("UPDATE sleep SET \(assignments) WHERE sync_id = ?", values + [key])
            if db.changes == 0 {
                try db.execute(
                    "INSERT INTO sleep (\(Self.alarmColumns.joined(separator: ", ")), sync_id) VALUES (\(placeholders(8)))",
                    values + [key])
            }
        case "lyrics_delay":
            try db.execute("DELETE FROM lyrics_sync_time_delay WHERE stid = ?", [key])
            if let ms = data?["ms"]?.int {
                try db.execute(
                    "INSERT INTO lyrics_sync_time_delay (stid, sync_time_delay) VALUES (?, ?)", [key, .int(ms)])
            }
        case "play_count":
            // Another device's count, which only that device changes
            let parts = Self.playCountKey(item.key).map(SQLValue.text)
            guard let data else {
                try db.execute("DELETE FROM play_counts WHERE month = ? AND device = ? AND stid = ?", parts)
                return
            }
            let track = data["track"].map { SQLValue.text($0.encodedString()) } ?? .null
            try db.execute(
                "INSERT OR REPLACE INTO play_counts (month, device, stid, plays, seconds, track) VALUES (?, ?, ?, ?, ?, ?)",
                parts + [.int(data["plays"]?.int ?? 0), .double(data["seconds"]?.double ?? 0), track])
        default:
            break
        }
    }

    private func applyPlaylist(
        _ key: String, _ data: [String: JSONValue]?, table: String, idColumn: String, tracksTable: String,
        trackColumns: [String]
    ) throws {
        let existing = try db.query("SELECT \(idColumn) FROM \(table) WHERE sync_id = ?", [.text(key)])
        let id = existing.first?[idColumn]?.int
        if let id { try db.execute("DELETE FROM \(tracksTable) WHERE \(idColumn) = ?", [.int(id)]) }
        guard let data else {
            if let id { try db.execute("DELETE FROM \(table) WHERE \(idColumn) = ?", [.int(id)]) }
            return
        }
        var columns = ["title"]
        var values = [SQLValue(json: data["title"])]
        // Without a cover in the data, the playlist keeps the one it has
        if let cover = data["cover"] {
            columns.append("cover")
            values.append(SQLValue(cover.string.flatMap { Data(base64Encoded: $0) }))
        }
        let playlistID: Int
        if let id {
            let assignments = columns.map { "\($0) = ?" }.joined(separator: ", ")
            try db.execute("UPDATE \(table) SET \(assignments) WHERE \(idColumn) = ?", values + [.int(id)])
            playlistID = id
        } else {
            try db.execute(
                "INSERT INTO \(table) (\((columns + ["sync_id"]).joined(separator: ", "))) VALUES (\(placeholders(columns.count + 1)))",
                values + [.text(key)])
            playlistID = db.lastInsertID
        }
        let insert = """
            INSERT INTO \(tracksTable) (\((trackColumns + [idColumn, "order_number", "hidden"]).joined(separator: ", ")))
            VALUES (\(placeholders(trackColumns.count + 3)))
            """
        for (order, track) in (data["tracks"]?.array ?? []).enumerated() {
            guard let track = track.object else { continue }
            let hidden = track["hidden"] == .bool(true) || track["hidden"] == .int(1)
            try db.execute(
                insert,
                trackColumns.map { SQLValue(json: track[$0]) } + [.int(playlistID), .int(order), SQLValue(hidden)])
        }
    }

    public func states() throws -> [SyncKey: SyncState] {
        var states: [SyncKey: SyncState] = [:]
        for row in try db.query("SELECT * FROM sync_state") {
            guard let kind = row["kind"]?.text, let key = row["key"]?.text else { continue }
            states[SyncKey(kind: kind, key: key)] = SyncState(
                hash: row["hash"]?.text, changedAt: row["changed_at"]?.int ?? 0, dirty: row["dirty"]?.isTrue ?? false)
        }
        return states
    }

    public func saveStates(_ states: [SyncKey: SyncState]) throws {
        try db.transaction {
            for (item, state) in states {
                try db.execute(
                    "INSERT OR REPLACE INTO sync_state (kind, key, hash, changed_at, dirty) VALUES (?, ?, ?, ?, ?)",
                    [.text(item.kind), .text(item.key), SQLValue(state.hash), .int(state.changedAt), SQLValue(state.dirty)])
            }
        }
    }

    public func cursor() throws -> Int? {
        try db.query("SELECT value FROM sync_meta WHERE name = 'cursor'").first?["value"]?.int
    }

    public func setCursor(_ cursor: Int) throws {
        try db.execute("INSERT OR REPLACE INTO sync_meta (name, value) VALUES ('cursor', ?)", [.text(String(cursor))])
    }

    public func clearSyncState() throws {
        try db.execute("DELETE FROM sync_state")
        try db.execute("DELETE FROM sync_meta")
    }

    public func changeCount() -> Int { db.totalChanges }
}
