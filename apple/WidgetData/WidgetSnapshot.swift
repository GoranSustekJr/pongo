import Foundation

/// What the widgets show, which the app writes to the App Group's container
/// whenever it changes and the widgets read: the song playing and this
/// month's top songs.
nonisolated struct WidgetSnapshot: Codable, Sendable {
    nonisolated struct Song: Codable, Sendable, Hashable {
        var title: String
        var artist: String
        /// A small JPEG of the cover.
        var cover: Data?
        var plays: Int?
    }

    var nowPlaying: Song?
    var isPlaying = false
    /// The cover's colors as RGB from 0 to 1: a deep one to draw on, and a
    /// pale one for highlights.
    var background: [Double] = []
    var accent: [Double] = []
    /// The month the top songs are of, by name.
    var month = ""
    var monthPlays = 0
    var monthMinutes = 0
    var top: [Song] = []
    /// The widgets' words in the app's language: `nothingPlaying`, `topSongs`,
    /// `plays` and `minutes`.
    var labels: [String: String] = [:]

    private static var file: URL? {
        guard let group = Bundle.main.object(forInfoDictionaryKey: "PongoAppGroup") as? String else { return nil }
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group)?
            .appending(path: "widgets.json")
    }

    static func load() -> WidgetSnapshot? {
        guard let file, let data = try? Data(contentsOf: file) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }

    func save() {
        guard let file = Self.file, let data = try? JSONEncoder().encode(self) else { return }
        try? data.write(to: file, options: .atomic)
    }
}

/// The links widgets and activities open.
nonisolated enum PongoLinks {
    /// Opens the player with lyrics.
    static let lyrics = URL(string: "pongo://lyrics")!
    /// Opens the full player.
    static let player = URL(string: "pongo://player")!
    /// Opens this month's top songs.
    static let topSongs = URL(string: "pongo://top")!
}

/// What the widgets are called, for reloading them.
nonisolated enum PongoWidgetKind {
    static let nowPlaying = "PongoNowPlaying"
    static let topSongs = "PongoTopSongs"
    /// What Mac widgets tell the app, as distributed notifications.
    static let togglePlayback = Notification.Name("PongoWidgetTogglePlayback")
    static let skipToNext = Notification.Name("PongoWidgetSkipToNext")
}
