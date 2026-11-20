import AppIntents
import SwiftUI
import WidgetKit

#if os(macOS)
    import AppKit

    typealias WidgetImage = NSImage

    extension Image {
        init(widgetImage: NSImage) { self.init(nsImage: widgetImage) }
    }

    /// Plays or pauses from a widget. Mac widgets run their intents on their
    /// own, so this tells the app, which listens for it.
    struct TogglePlaybackIntent: AppIntent {
        static let title: LocalizedStringResource = "Play or pause"
        static let isDiscoverable = false

        func perform() async throws -> some IntentResult {
            DistributedNotificationCenter.default().postNotificationName(
                PongoWidgetKind.togglePlayback, object: nil, deliverImmediately: true)
            return .result()
        }
    }

    /// Skips to the next song from a widget.
    struct SkipToNextIntent: AppIntent {
        static let title: LocalizedStringResource = "Next song"
        static let isDiscoverable = false

        func perform() async throws -> some IntentResult {
            DistributedNotificationCenter.default().postNotificationName(
                PongoWidgetKind.skipToNext, object: nil, deliverImmediately: true)
            return .result()
        }
    }
#else
    import UIKit

    typealias WidgetImage = UIImage

    extension Image {
        init(widgetImage: UIImage) { self.init(uiImage: widgetImage) }
    }
#endif

/// The widgets' data, as the app last wrote it.
struct SnapshotEntry: TimelineEntry {
    var date = Date.now
    var snapshot: WidgetSnapshot
}

/// Hands the widgets what the app wrote; the app reloads them when it changes.
struct SnapshotProvider: TimelineProvider {
    func placeholder(in context: Context) -> SnapshotEntry {
        SnapshotEntry(snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (SnapshotEntry) -> Void) {
        completion(SnapshotEntry(snapshot: WidgetSnapshot.load() ?? .placeholder))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SnapshotEntry>) -> Void) {
        completion(Timeline(entries: [SnapshotEntry(snapshot: WidgetSnapshot.load() ?? WidgetSnapshot())], policy: .never))
    }
}

extension WidgetSnapshot {
    /// Something to show in the widget gallery before the app wrote anything.
    static var placeholder: WidgetSnapshot {
        var snapshot = WidgetSnapshot()
        snapshot.nowPlaying = Song(title: "Pongo", artist: "♪")
        snapshot.background = [0.08, 0.25, 0.27]
        snapshot.accent = [0.45, 0.9, 0.85]
        snapshot.month = "—"
        snapshot.top = (1...5).map { Song(title: "♪ \($0)", artist: "Pongo", plays: 6 - $0) }
        return snapshot
    }

    func label(_ key: String, _ fallback: String) -> String { labels[key] ?? fallback }
}

// MARK: - Now playing

/// The song playing, with play or pause and next.
struct NowPlayingWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: PongoWidgetKind.nowPlaying, provider: SnapshotProvider()) { entry in
            NowPlayingWidgetView(snapshot: entry.snapshot)
                .widgetURL(PongoLinks.player)
        }
        .configurationDisplayName("Now Playing")
        .description("The song playing in Pongo.")
        #if os(macOS)
            .supportedFamilies([.systemSmall, .systemMedium])
        #else
            .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
        #endif
    }
}

private struct NowPlayingWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let snapshot: WidgetSnapshot

    var body: some View {
        let accent = rgbColor(snapshot.accent, fallback: .white)
        Group {
            if let song = snapshot.nowPlaying {
                switch family {
                case .accessoryRectangular:
                    VStack(alignment: .leading, spacing: 1) {
                        Label("Pongo", systemImage: snapshot.isPlaying ? "waveform" : "pause.fill")
                            .font(.caption2.weight(.semibold))
                        Text(song.title).font(.headline).lineLimit(1)
                        Text(song.artist).font(.caption).lineLimit(1).opacity(0.75)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                case .systemMedium:
                    HStack(spacing: 14) {
                        WidgetCover(data: song.cover, side: 118, radius: 14)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(song.title).font(.system(size: 17, weight: .bold)).lineLimit(2)
                            Text(song.artist).font(.system(size: 14)).opacity(0.75).lineLimit(1)
                            Spacer(minLength: 6)
                            WidgetControls(isPlaying: snapshot.isPlaying, accent: accent, size: 26)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                default:
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(alignment: .top) {
                            WidgetCover(data: song.cover, side: 62, radius: 10)
                            Spacer()
                            Button(intent: TogglePlaybackIntent()) {
                                Image(systemName: snapshot.isPlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(accent)
                                    .frame(width: 40, height: 40)
                                    .background(.white.opacity(0.15), in: .circle)
                            }
                            .buttonStyle(.plain)
                        }
                        Spacer(minLength: 4)
                        Text(song.title).font(.system(size: 15, weight: .bold)).lineLimit(2)
                        Text(song.artist).font(.system(size: 12)).opacity(0.75).lineLimit(1)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Image(systemName: "music.note").font(.title2)
                    Text(snapshot.label("nothingPlaying", "Nothing is playing"))
                        .font(.system(size: 15, weight: .semibold))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            }
        }
        .foregroundStyle(.white)
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [rgbColor(snapshot.background), rgbColor(snapshot.background).mix(with: .black, by: 0.45)],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

private struct WidgetControls: View {
    let isPlaying: Bool
    let accent: Color
    let size: CGFloat

    var body: some View {
        HStack(spacing: 22) {
            Button(intent: TogglePlaybackIntent()) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
            }
            Button(intent: SkipToNextIntent()) {
                Image(systemName: "forward.fill")
            }
        }
        .font(.system(size: size))
        .buttonStyle(.plain)
        .foregroundStyle(accent)
    }
}

// MARK: - Top songs

/// This month's most played songs.
struct TopSongsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: PongoWidgetKind.topSongs, provider: SnapshotProvider()) { entry in
            TopSongsWidgetView(snapshot: entry.snapshot)
                .widgetURL(PongoLinks.topSongs)
        }
        .configurationDisplayName("Top Songs")
        .description("Your most played songs this month.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

private struct TopSongsWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let snapshot: WidgetSnapshot

    private let teal = Color(red: 0.36, green: 0.85, blue: 0.8)

    var body: some View {
        let count = family == .systemLarge ? 5 : 3
        VStack(alignment: .leading, spacing: family == .systemLarge ? 10 : 6) {
            HStack(alignment: .firstTextBaseline) {
                Label(snapshot.label("topSongs", "Top songs"), systemImage: "flame.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(teal)
                Spacer()
                Text(snapshot.month).font(.system(size: 13, weight: .semibold)).opacity(0.7)
            }
            if snapshot.top.isEmpty {
                Spacer()
                Image(systemName: "chart.bar").font(.title).opacity(0.6).frame(maxWidth: .infinity)
                Spacer()
            } else {
                ForEach(Array(snapshot.top.prefix(count).enumerated()), id: \.offset) { index, song in
                    HStack(spacing: 10) {
                        Text("\(index + 1)")
                            .font(.system(size: 15, weight: .heavy).monospacedDigit())
                            .foregroundStyle(index == 0 ? teal : .white.opacity(0.6))
                            .frame(width: 16)
                        WidgetCover(data: song.cover, side: family == .systemLarge ? 44 : 34, radius: 6)
                        VStack(alignment: .leading, spacing: 0) {
                            Text(song.title).font(.system(size: 14, weight: .semibold)).lineLimit(1)
                            Text(song.artist).font(.system(size: 12)).opacity(0.7).lineLimit(1)
                        }
                        Spacer(minLength: 4)
                        if let plays = song.plays {
                            Text("\(plays)").font(.system(size: 13, weight: .semibold).monospacedDigit()).opacity(0.75)
                        }
                    }
                }
                if family == .systemLarge {
                    Spacer(minLength: 0)
                    HStack {
                        Text("\(snapshot.monthPlays) \(snapshot.label("plays", "plays"))")
                        Spacer()
                        Text("\(snapshot.monthMinutes) \(snapshot.label("minutes", "minutes").lowercased())")
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .opacity(0.7)
                }
            }
        }
        .foregroundStyle(.white)
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [Color(red: 0.05, green: 0.2, blue: 0.22), Color(red: 0.02, green: 0.07, blue: 0.09)],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

// MARK: - Pieces

private struct WidgetCover: View {
    let data: Data?
    let side: CGFloat
    let radius: CGFloat

    var body: some View {
        Group {
            if let data, let image = WidgetImage(data: data) {
                Image(widgetImage: image).resizable().scaledToFill()
            } else {
                Image(systemName: "music.note").font(.system(size: side * 0.4)).foregroundStyle(.white.opacity(0.7))
            }
        }
        .frame(width: side, height: side)
        .background(.white.opacity(0.12))
        .clipShape(.rect(cornerRadius: radius, style: .continuous))
    }
}

private func rgbColor(_ rgb: [Double], fallback: Color = Color(white: 0.15)) -> Color {
    guard rgb.count == 3 else { return fallback }
    return Color(red: rgb[0], green: rgb[1], blue: rgb[2])
}
