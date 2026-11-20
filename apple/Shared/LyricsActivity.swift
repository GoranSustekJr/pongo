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
        /// How many milliseconds earlier the lyrics show than they're timed.
        var delay: Int? = nil
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

/// Jumps to the start of the next lyrics line, or back to the previous one.
struct LyricsLineIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Jump to a lyrics line"
    static let isDiscoverable = false

    @Parameter(title: "Forward")
    var forward: Bool

    init() {}

    init(forward: Bool) {
        self.forward = forward
    }

    func perform() async throws -> some IntentResult {
        let forward = forward
        await MainActor.run {
            NotificationCenter.default.post(name: .pongoLyricsLine, object: nil, userInfo: ["forward": forward])
        }
        return .result()
    }
}

/// Shows the lyrics a quarter second earlier or later, for this song.
struct LyricsTimingIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Adjust the lyrics timing"
    static let isDiscoverable = false

    @Parameter(title: "Earlier")
    var earlier: Bool

    init() {}

    init(earlier: Bool) {
        self.earlier = earlier
    }

    func perform() async throws -> some IntentResult {
        let earlier = earlier
        await MainActor.run {
            NotificationCenter.default.post(name: .pongoLyricsTiming, object: nil, userInfo: ["earlier": earlier])
        }
        return .result()
    }
}

extension Notification.Name {
    nonisolated static let pongoLyricsLine = Notification.Name("PongoLyricsLine")
    nonisolated static let pongoLyricsTiming = Notification.Name("PongoLyricsTiming")
    nonisolated static let pongoTogglePlayback = Notification.Name("PongoTogglePlayback")
    nonisolated static let pongoSkipToNext = Notification.Name("PongoSkipToNext")
}
