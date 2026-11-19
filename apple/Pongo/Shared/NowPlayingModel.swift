import Observation
import PongoCore
import SwiftUI
import Translation

/// What the player screen shows besides the cover, and the current track's
/// lyrics. It lives as long as the app, so lyrics or the queue stay open
/// across tracks and after closing the player, as in the Flutter app.
@Observable
final class NowPlayingModel {
    enum Mode { case artwork, lyrics, queue }

    var lyricsOn = false
    var showsQueue = false
    /// Milliseconds the synced lyrics are shifted by; positive shows each line
    /// earlier.
    private(set) var delay = 0
    private(set) var savedDelay = 0
    /// The current track's lyrics, nil while they load.
    private(set) var lyrics: Lyrics?
    private(set) var syncedLines: [LyricsLine] = []
    private(set) var plainLines: [String] = []
    private var lyricsStid: String?

    /// Lyrics that are still loading count as existing, so the screen doesn't
    /// jump back to the cover while the next track's arrive.
    var lyricsExist: Bool { lyrics.map { !$0.isEmpty } ?? true }

    var mode: Mode { lyricsOn && lyricsExist ? .lyrics : showsQueue ? .queue : .artwork }

    /// Whether the synced lyrics are shown: plain ones only show for tracks
    /// without synced lyrics.
    var showsSynced: Bool { !syncedLines.isEmpty || plainLines.isEmpty }

    /// The current track's cover blurred into its colors, behind the mini
    /// player. Kept here so the mini player doesn't fade it in again each
    /// time it's rebuilt.
    private(set) var backdrop: PlatformImage?
    private var backdropURL: URL?

    /// Blurs the cover at [url] into [backdrop], unless it's the one there.
    func loadBackdrop(_ url: URL?) async {
        guard url != backdropURL else { return }
        backdropURL = url
        let image = await url.asyncMap { await ImagePipeline.shared.blurred(for: $0) } ?? nil
        guard backdropURL == url else { return }
        withAnimation(.easeInOut(duration: 0.5)) { backdrop = image }
    }

    /// A pale color of the current cover, for the player's sliders and the
    /// buttons that are on.
    private(set) var accent = Color.white
    private var accentURL: URL?

    func loadAccent(_ url: URL?) async {
        guard url != accentURL else { return }
        accentURL = url
        let color = await url.asyncMap { await ImagePipeline.shared.accent(for: $0) } ?? nil
        guard accentURL == url else { return }
        withAnimation(.easeInOut(duration: 0.6)) { accent = color.map(Color.init(platformColor:)) ?? .white }
    }

    /// Loads the lyrics and saved delay of [item] unless they're loaded.
    ///
    /// A track streamed while the server downloads it has no length yet, which
    /// lyrics are matched by, so they load again once it has one.
    func load(_ item: QueueItem, model: AppModel) async {
        let key = "\(item.stid)|\(item.duration > 0)"
        guard key != lyricsStid else { return }
        lyricsStid = key
        lyrics = nil
        guard model.settings.settings.enableLyrics else {
            show(.empty, delay: 0)
            return
        }
        let track = item.track
        // Downloaded tracks keep their lyrics, which also show offline
        let saved = Downloads.savedLyrics(item.stid)
        let fetched: Lyrics
        if let saved {
            fetched = saved
        } else {
            fetched = await model.lyrics.fetch(
                name: track.name, artist: track.artists.first?.name ?? "", album: track.album?.name ?? "",
                durationSeconds: Int(item.duration))
            // Tracks downloaded before lyrics were saved with them get theirs now
            if model.downloadedIDs.contains(item.stid) { Downloads.saveLyrics(fetched, for: item.stid) }
        }
        let delay = (try? await model.database.lyricsDelay(item.stid)) ?? 0
        // A later track may have started while these loaded
        guard lyricsStid == key else { return }
        show(fetched, delay: delay)
    }

    /// Forgets the loaded lyrics, so they load again, such as after lyrics
    /// were turned on in the settings.
    func reloadLyrics() { lyricsStid = nil }

    private func show(_ lyrics: Lyrics, delay: Int) {
        self.lyrics = lyrics
        syncedLines = lyrics.syncedLines
        plainLines = lyrics.plain.isEmpty ? [] : lyrics.plain.components(separatedBy: "\n")
        self.delay = delay
        savedDelay = delay
        translateAgain()
    }

    // MARK: - Translation

    /// Whether each lyrics line shows its translation under it. It stays on
    /// across tracks, as the lyrics do.
    private(set) var translates = false
    /// The translations of the current lyrics, by line.
    private(set) var translations: [String: String] = [:]
    /// What the lyrics panel translates with; changing it translates again.
    var translation: TranslationSession.Configuration?

    func toggleTranslation(_ model: AppModel) async {
        translates.toggle()
        Haptics.select()
        guard translates else {
            translation = nil
            withAnimation(.easeInOut(duration: 0.3)) { translations = [:] }
            return
        }
        translation = TranslationSession.Configuration(source: nil, target: await targetLanguage(model))
    }

    /// Translates the lyrics now shown, such as the next track's.
    private func translateAgain() {
        translations = [:]
        if translates { translation?.invalidate() }
    }

    /// The app's language when Translation can translate into it, or else
    /// English.
    private func targetLanguage(_ model: AppModel) async -> Locale.Language {
        let wanted = Locale.Language(identifier: model.settings.settings.locale)
        let supported = await Self.supportedLanguages()
        return supported.contains { $0.languageCode == wanted.languageCode } ? wanted : Locale.Language(identifier: "en")
    }

    /// The languages Translation knows, asked for off the main actor, which
    /// its availability checker can't be sent to.
    @concurrent nonisolated private static func supportedLanguages() async -> [Locale.Language] {
        await LanguageAvailability().supportedLanguages
    }

    /// The lines shown, each once, without blank ones: what's translated.
    var linesToTranslate: [String] {
        let source = showsSynced ? syncedLines.map(\.text) : plainLines
        return Array(Set(source.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }))
    }

    /// Shows the [translated] lines, leaving out those already in the
    /// language translated into, or turns translation off when it failed.
    func showTranslations(_ translated: [String: String]?, model: AppModel) {
        guard let translated else {
            translates = false
            translation = nil
            model.messages.show(L10n.translationunavailable, systemImage: "translate", isError: true)
            return
        }
        let changed = translated.filter { $0.value.lowercased() != $0.key.lowercased() }
        withAnimation(.easeInOut(duration: 0.35)) { translations = changed }
    }

    // MARK: - Actions

    func toggleLyrics(_ model: AppModel) {
        guard model.settings.settings.enableLyrics else {
            model.messages.show(L10n.lyricsdisabled, systemImage: "quote.bubble")
            return
        }
        lyricsOn.toggle()
        Haptics.select()
        if lyricsOn, !lyricsExist {
            model.messages.show(L10n.nolyricsavailable, detail: L10n.wanttohelpoutlyrics, systemImage: "quote.bubble")
        }
    }

    func toggleQueue() {
        showsQueue.toggle()
        Haptics.select()
    }

    /// The lyric card being made, shown as a sheet over the player.
    var lyricCard: LyricCardRequest?

    /// Starts a lyric card of the current track with the line at [index]
    /// of [lines], left out blank ones.
    func shareLyrics(_ lines: [String], at index: Int, item: QueueItem?) {
        guard let item else { return }
        let kept = lines.indices.filter { !lines[$0].trimmingCharacters(in: .whitespaces).isEmpty }
        guard let held = kept.firstIndex(where: { $0 >= index }) ?? kept.indices.last else { return }
        Haptics.select()
        lyricCard = LyricCardRequest(
            item: item, lines: kept.map { lines[$0] }, held: held, translations: translations)
    }

    /// Shows the lyrics a quarter second earlier.
    func increaseDelay() { delay += 250 }

    /// Shows the lyrics a quarter second later.
    func decreaseDelay() { delay -= 250 }

    func resetDelay() { delay = 0 }

    /// Remembers the delay for the current track.
    func saveDelay(_ model: AppModel) async {
        guard let stid = lyricsStid else { return }
        try? await model.database.saveLyricsDelay(stid, milliseconds: delay)
        savedDelay = delay
        model.messages.show(L10n.successful, detail: L10n.successfullysavedsynctimedelay, systemImage: "clock")
        model.libraryChanged()
    }
}

extension Optional {
    /// The value transformed by the async [transform], or `nil`.
    func asyncMap<T>(_ transform: (Wrapped) async -> T) async -> T? {
        guard let self else { return nil }
        return await transform(self)
    }
}
