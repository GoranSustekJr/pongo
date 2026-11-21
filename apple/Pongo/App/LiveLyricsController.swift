import ActivityKit
import PongoCore
import UIKit

/// Keeps the Live Activity in step with the player: the song, its cover's
/// colors and the lyrics line being sung, on the Lock Screen and in the
/// Dynamic Island.
@MainActor
final class LiveLyricsController {
    private unowned let model: AppModel
    private var activity: Activity<LyricsActivityAttributes>?
    private var shown: LyricsActivityAttributes.ContentState?
    /// The song the user swiped the activity away for, so it doesn't come
    /// back until the next one.
    private var dismissedStid: String?
    private var look: (stid: String, cover: Data?, background: [Double], accent: [Double])?
    private var loop: Task<Void, Never>?
    private var observers: [NSObjectProtocol] = []

    init(model: AppModel) {
        self.model = model
    }

    func start() {
        // Activities left over from the last run belong to a player that's gone
        for leftover in Activity<LyricsActivityAttributes>.activities {
            // ActivityKit's activities aren't marked Sendable, but are safe to use from any thread
            nonisolated(unsafe) let leftover = leftover
            Task { await leftover.end(nil, dismissalPolicy: .immediate) }
        }
        let center = NotificationCenter.default
        observers = [
            center.addObserver(forName: .pongoTogglePlayback, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.model.player.togglePlayback() }
            },
            center.addObserver(forName: .pongoSkipToNext, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.model.player.skipToNext() }
            },
            center.addObserver(forName: .pongoLyricsLine, object: nil, queue: .main) { [weak self] note in
                let forward = note.userInfo?["forward"] as? Bool ?? true
                MainActor.assumeIsolated { self?.jumpLine(forward: forward) }
            },
            center.addObserver(forName: .pongoLyricsTiming, object: nil, queue: .main) { [weak self] note in
                let earlier = note.userInfo?["earlier"] as? Bool ?? true
                MainActor.assumeIsolated {
                    guard let self else { return }
                    if earlier { self.model.nowPlaying.increaseDelay() } else { self.model.nowPlaying.decreaseDelay() }
                    Task { await self.refresh() }
                }
            },
        ]
        // Lines change at most a few times a second, as often as the player
        // reports its position. Without an activity it only checks whether
        // one should start, which can wait longer.
        loop = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refresh()
                let showing = self?.activity != nil
                try? await Task.sleep(for: showing ? .milliseconds(250) : .seconds(2))
            }
        }
    }

    private func refresh() async {
        let player = model.player
        // Only while listening together, where the lock screen shows what everyone hears
        guard model.settings.settings.showLiveLyrics, model.listening.isActive || isDemo, let item = player.current,
            ActivityAuthorizationInfo().areActivitiesEnabled
        else {
            await end()
            return
        }
        if model.settings.settings.enableLyrics { await model.nowPlaying.load(item, model: model) }
        let look = await look(for: item)
        let (line, next) = lines()
        let state = LyricsActivityAttributes.ContentState(
            title: item.track.name, artist: item.track.artistNames, line: line, nextLine: next,
            isPlaying: player.isPlaying, cover: look.cover, background: look.background, accent: look.accent,
            delay: model.nowPlaying.syncedLines.isEmpty ? nil : model.nowPlaying.delay)
        guard state != shown else { return }

        if let activity, activity.activityState == .active {
            shown = state
            nonisolated(unsafe) let activity = activity
            await activity.update(ActivityContent(state: state, staleDate: nil))
            return
        }
        if let activity {
            // Swiped away: not again for this song
            if activity.activityState == .dismissed { dismissedStid = item.stid }
            self.activity = nil
        }
        // A new activity starts with playback, and only while the app is open
        guard player.isPlaying || isDemo, dismissedStid != item.stid,
            UIApplication.shared.applicationState == .active
        else { return }
        activity = try? Activity.request(
            attributes: LyricsActivityAttributes(), content: ActivityContent(state: state, staleDate: nil))
        shown = activity == nil ? nil : state
    }

    private func end() async {
        guard let current = activity else { return }
        nonisolated(unsafe) let activity = current
        self.activity = nil
        shown = nil
        await activity.end(nil, dismissalPolicy: .immediate)
    }

    /// Seeks to the next line, or back to the start of the line being sung,
    /// or to the one before it when that just started.
    private func jumpLine(forward: Bool) {
        let state = model.nowPlaying
        let lines = state.syncedLines
        guard !lines.isEmpty else { return }
        let shift = Double(state.delay) / 1000
        let position = model.player.progress.position + shift + 0.25
        let index = lines.lastIndex { $0.time <= position }
        let target: Int
        if forward {
            target = (index ?? -1) + 1
        } else if let index {
            target = position - lines[index].time > 2 ? index : max(index - 1, 0)
        } else {
            target = 0
        }
        guard lines.indices.contains(target) else { return }
        model.player.seek(to: max(lines[target].time - shift, 0))
        Task { await refresh() }
    }

    /// The line being sung and the one after it, timed like the player's
    /// synced lyrics.
    private func lines() -> (String?, String?) {
        let state = model.nowPlaying
        let lines = state.syncedLines
        guard !lines.isEmpty else { return (nil, nil) }
        let position = model.player.progress.position + Double(state.delay) / 1000 + 0.25
        guard let index = lines.lastIndex(where: { $0.time <= position }) else { return (nil, lines.first?.text) }
        let text = lines[index].text.isEmpty ? "♪" : lines[index].text
        let next = lines[(index + 1)...].first { !$0.text.isEmpty }?.text
        return (text, next)
    }

    /// The cover as a tiny JPEG and its colors, worked out once per song.
    private func look(for item: QueueItem) async -> (stid: String, cover: Data?, background: [Double], accent: [Double]) {
        if let look, look.stid == item.stid { return look }
        var cover: Data?
        var accent = UIColor.white
        if let url = item.track.coverURL(size: 300) {
            if let image = await ImagePipeline.shared.image(for: url) {
                // Activity data must stay under 4 KB
                cover = await image.byPreparingThumbnail(ofSize: CGSize(width: 56, height: 56))?
                    .jpegData(compressionQuality: 0.55)
            }
            accent = await ImagePipeline.shared.accent(for: url) ?? .white
        }
        var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, alpha: CGFloat = 0
        accent.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        // A deep version of the cover's color, which white text reads well on
        let background = UIColor(hue: hue, saturation: saturation > 0.05 ? 0.6 : 0, brightness: 0.3, alpha: 1)
        let look = (item.stid, cover, rgb(background), rgb(accent))
        self.look = look
        return look
    }

    private func rgb(_ color: UIColor) -> [Double] {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return [red, green, blue].map(Double.init)
    }

    private var isDemo: Bool {
        #if DEBUG
            DemoMode.isOn
        #else
            false
        #endif
    }
}
