import PongoCore
import SwiftUI
import WidgetKit

#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// Keeps the widgets' data in step with the app: the song playing, whether
/// it plays, and this month's top songs once a play counts.
@MainActor
final class WidgetPublisher {
    private weak var model: AppModel?
    private var snapshot = WidgetSnapshot.load() ?? WidgetSnapshot()
    private var coverStid: String?
    private var statsTask: Task<Void, Never>?

    init(model: AppModel) {
        self.model = model
    }

    #if os(macOS)
        private var observers: [NSObjectProtocol] = []
    #endif

    func start() {
        observe()
        statsChanged()
        #if os(macOS)
            // Mac widgets' buttons say what to do as distributed notifications
            let center = DistributedNotificationCenter.default()
            observers = [
                center.addObserver(forName: PongoWidgetKind.togglePlayback, object: nil, queue: .main) { [weak self] _ in
                    MainActor.assumeIsolated { self?.model?.player.togglePlayback() }
                },
                center.addObserver(forName: PongoWidgetKind.skipToNext, object: nil, queue: .main) { [weak self] _ in
                    MainActor.assumeIsolated { self?.model?.player.skipToNext() }
                },
            ]
        #endif
    }

    private func observe() {
        guard let player = model?.player else { return }
        withObservationTracking {
            _ = player.current?.stid
            _ = player.isPlaying
        } onChange: { [weak self] in
            Task { @MainActor in
                await self?.playerChanged()
                self?.observe()
            }
        }
        Task { await playerChanged() }
    }

    private func playerChanged() async {
        guard let player = model?.player else { return }
        guard let item = player.current else {
            if snapshot.nowPlaying != nil {
                snapshot.nowPlaying = nil
                snapshot.isPlaying = false
                publish(PongoWidgetKind.nowPlaying)
            }
            return
        }
        let changed = coverStid != item.stid || snapshot.isPlaying != player.isPlaying
        guard changed else { return }
        snapshot.isPlaying = player.isPlaying
        if coverStid != item.stid {
            coverStid = item.stid
            var song = WidgetSnapshot.Song(title: item.track.name, artist: item.track.artistNames)
            song.cover = await Self.cover(item.track.coverURL(size: 300), side: 170)
            if let url = item.track.coverURL(size: 300) {
                let accent = await ImagePipeline.shared.accent(for: url) ?? .white
                snapshot.accent = Self.rgb(accent)
                snapshot.background = Self.rgb(Self.deep(accent))
            }
            // A later song may have started meanwhile
            guard coverStid == item.stid else { return }
            snapshot.nowPlaying = song
        }
        publish(PongoWidgetKind.nowPlaying)
    }

    /// Reloads this month's top songs, as a play counted.
    func statsChanged() {
        statsTask?.cancel()
        statsTask = Task { [weak self] in
            // Plays come in bursts as songs change; one reload covers them
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled, let self, let database = self.model?.database,
                let stats = try? await TopSongsView.load(database)
            else { return }
            var top: [WidgetSnapshot.Song] = []
            for stat in stats.tracks.prefix(5) {
                var song = WidgetSnapshot.Song(title: stat.track.name, artist: stat.track.artistNames)
                song.plays = stat.plays
                song.cover = await Self.cover(stat.track.coverURL(size: 150), side: 90)
                top.append(song)
            }
            guard !Task.isCancelled else { return }
            self.snapshot.month = StatsView.title(of: stats.month, year: false)
            self.snapshot.monthPlays = stats.plays
            self.snapshot.monthMinutes = Int((stats.seconds / 60).rounded())
            self.snapshot.top = top
            self.publish(PongoWidgetKind.topSongs)
        }
    }

    private func publish(_ kind: String) {
        snapshot.labels = [
            "nothingPlaying": L10n.nothingplaying, "topSongs": L10n.topsongs, "plays": L10n.plays,
            "minutes": L10n.minuteslistened,
        ]
        snapshot.save()
        WidgetCenter.shared.reloadTimelines(ofKind: kind)
    }

    private static func cover(_ url: URL?, side: CGFloat) async -> Data? {
        guard let url, let image = await ImagePipeline.shared.image(for: url) else { return nil }
        #if os(macOS)
            let pixels = Int(side * 2)
            guard let bitmap = NSBitmapImageRep(
                bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8, samplesPerPixel: 4,
                hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0),
                let context = NSGraphicsContext(bitmapImageRep: bitmap)
            else { return nil }
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = context
            image.draw(in: NSRect(x: 0, y: 0, width: pixels, height: pixels))
            NSGraphicsContext.restoreGraphicsState()
            return bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.7])
        #else
            return await image.byPreparingThumbnail(ofSize: CGSize(width: side, height: side))?
                .jpegData(compressionQuality: 0.7)
        #endif
    }

    /// A deep version of [color], which white text reads well on.
    private static func deep(_ color: PlatformColor) -> PlatformColor {
        var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, alpha: CGFloat = 0
        srgb(color).getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        return PlatformColor(hue: hue, saturation: saturation > 0.05 ? 0.6 : 0, brightness: 0.3, alpha: 1)
    }

    private static func rgb(_ color: PlatformColor) -> [Double] {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        srgb(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return [red, green, blue].map(Double.init)
    }

    private static func srgb(_ color: PlatformColor) -> PlatformColor {
        #if os(macOS)
            color.usingColorSpace(.sRGB) ?? color
        #else
            color
        #endif
    }
}
