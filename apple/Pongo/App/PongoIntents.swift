import AppIntents
import PongoCore

/// Why Siri couldn't do what it was asked.
enum PongoIntentError: Error, CustomLocalizedStringResourceConvertible {
    case notRunning
    case nothingToPlay

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .notRunning: "Pongo isn't ready yet. Open it and try again."
        case .nothingToPlay: "There's nothing to play yet."
        }
    }
}

/// Plays the favourite songs, shuffled unless asked otherwise.
struct PlayFavouritesIntent: AudioPlaybackIntent {
    static let title: LocalizedStringResource = "Play My Favourites"
    static let description = IntentDescription("Plays your favourite songs in Pongo.")

    @Parameter(title: "Shuffle", default: true)
    var shuffle: Bool

    @MainActor
    func perform() async throws -> some IntentResult {
        guard let model = AppModel.current else { throw PongoIntentError.notRunning }
        let tracks = try await model.database.favourites().map(\.track)
        guard !tracks.isEmpty else { throw PongoIntentError.nothingToPlay }
        // Siri waits only so long; the songs the server still has to fetch keep coming after
        Task { await model.player.playOnline("library.favourites", tracks, durations: [:], shuffle: shuffle) }
        return .result()
    }
}

/// Plays this month's 25 most played songs.
struct PlayTopSongsIntent: AudioPlaybackIntent {
    static let title: LocalizedStringResource = "Play My Top Songs"
    static let description = IntentDescription("Plays the songs you listened to most this month in Pongo.")

    @Parameter(title: "Shuffle", default: false)
    var shuffle: Bool

    @MainActor
    func perform() async throws -> some IntentResult {
        guard let model = AppModel.current else { throw PongoIntentError.notRunning }
        guard let tracks = try await TopSongsView.load(model.database)?.tracks.map(\.track), !tracks.isEmpty else {
            throw PongoIntentError.nothingToPlay
        }
        Task { await model.player.playOnline("stats.top25", tracks, durations: [:], shuffle: shuffle) }
        return .result()
    }
}

/// The phrases Siri knows Pongo by, and the shortcuts the Shortcuts app
/// offers without setup.
struct PongoShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: PlayFavouritesIntent(),
            phrases: [
                "Play my favourites in \(.applicationName)",
                "Shuffle my favourites in \(.applicationName)",
                "Play my liked songs in \(.applicationName)",
            ],
            shortTitle: "Play Favourites", systemImageName: "heart.fill")
        AppShortcut(
            intent: PlayTopSongsIntent(),
            phrases: [
                "Play my top songs in \(.applicationName)",
                "Play my top 25 in \(.applicationName)",
                "Play what I listen to most in \(.applicationName)",
            ],
            shortTitle: "Play Top 25", systemImageName: "flame.fill")
    }
}
