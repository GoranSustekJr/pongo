import ActivityKit
import AppIntents
import Foundation

/// The song playing, shown on the Lock Screen and in the Dynamic Island with
/// its current lyrics line. Shared by the app, which starts and updates it,
/// and the widget extension, which draws it.
nonisolated struct LyricsActivityAttributes: ActivityAttributes {
    nonisolated struct ContentState: Codable, Hashable, Sendable {
        var title: String
        var artist: String
        /// The line being sung, or `nil` before the first one and for songs
        /// without synced lyrics.
        var line: String?
        var nextLine: String?
        var isPlaying: Bool
        /// A tiny JPEG of the cover. Activities can't load images themselves,
        /// and their data must stay under 4 KB.
        var cover: Data?
        /// The cover's colors as RGB from 0 to 1: the background, and a pale
        /// one for highlights.
        var background: [Double]
        var accent: [Double]
    }
}

/// Plays or pauses from the Live Activity. It runs in the app, which listens
/// for the notification it posts.
nonisolated struct TogglePlaybackIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Play or pause"
    static let isDiscoverable = false

    init() {}

    func perform() async throws -> some IntentResult {
        await MainActor.run { NotificationCenter.default.post(name: .pongoTogglePlayback, object: nil) }
        return .result()
    }
}

/// Skips to the next song from the Live Activity.
nonisolated struct SkipToNextIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Next song"
    static let isDiscoverable = false

    init() {}

    func perform() async throws -> some IntentResult {
        await MainActor.run { NotificationCenter.default.post(name: .pongoSkipToNext, object: nil) }
        return .result()
    }
}

extension Notification.Name {
    nonisolated static let pongoTogglePlayback = Notification.Name("PongoTogglePlayback")
    nonisolated static let pongoSkipToNext = Notification.Name("PongoSkipToNext")
}

/// The link a tap on the activity opens: the player with lyrics.
nonisolated enum PongoLinks {
    static let lyrics = URL(string: "pongo://lyrics")!
}
