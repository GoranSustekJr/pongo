import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

@main
struct LiveLyricsBundle: WidgetBundle {
    var body: some Widget {
        LiveLyricsWidget()
        NowPlayingWidget()
        TopSongsWidget()
    }
}

/// The playing song's lyrics on the Lock Screen and in the Dynamic Island.
struct LiveLyricsWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LyricsActivityAttributes.self) { context in
            LockScreenLyrics(state: context.state)
                .activityBackgroundTint(color(context.state.background).opacity(0.85))
                .activitySystemActionForegroundColor(.white)
                .widgetURL(PongoLinks.lyrics)
        } dynamicIsland: { context in
            let state = context.state
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Cover(data: state.cover, side: 52)
                        .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Controls(isPlaying: state.isPlaying, accent: color(state.accent))
                        .padding(.trailing, 4)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 1) {
                        Text(state.title).font(.system(size: 15, weight: .semibold)).lineLimit(1)
                        Text(state.artist).font(.system(size: 13)).foregroundStyle(.secondary).lineLimit(1)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if let line = state.line {
                        VStack(spacing: 6) {
                            Text(line)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(color(state.accent))
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .contentTransition(.opacity)
                            LyricsControls(delay: state.delay)
                        }
                        .padding(.top, 4)
                    }
                }
            } compactLeading: {
                Cover(data: state.cover, side: 24, round: true)
            } compactTrailing: {
                Image(systemName: state.line == nil ? "music.note" : "quote.bubble.fill")
                    .foregroundStyle(color(state.accent))
                    .symbolEffect(.pulse, isActive: state.isPlaying)
            } minimal: {
                Cover(data: state.cover, side: 22, round: true)
            }
            .widgetURL(PongoLinks.lyrics)
            .keylineTint(color(state.accent))
        }
    }
}

/// The Lock Screen card: the song on top, the line being sung big below it
/// and the next one fainter.
private struct LockScreenLyrics: View {
    let state: LyricsActivityAttributes.ContentState

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Cover(data: state.cover, side: 44)
                VStack(alignment: .leading, spacing: 1) {
                    Text(state.title).font(.system(size: 15, weight: .semibold)).lineLimit(1)
                    Text(state.artist).font(.system(size: 13)).opacity(0.7).lineLimit(1)
                }
                Spacer(minLength: 8)
                Controls(isPlaying: state.isPlaying, accent: .white)
            }
            if let line = state.line {
                VStack(alignment: .leading, spacing: 4) {
                    Text(line)
                        .font(.system(size: 22, weight: .bold))
                        .lineLimit(2)
                        .shadow(color: color(state.accent).opacity(0.6), radius: 10)
                        .contentTransition(.opacity)
                    HStack(spacing: 8) {
                        Text(state.nextLine ?? " ")
                            .font(.system(size: 16, weight: .semibold))
                            .opacity(0.5)
                            .lineLimit(1)
                            .contentTransition(.opacity)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        LyricsControls(delay: state.delay)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .foregroundStyle(.white)
        .padding(16)
        .background {
            LinearGradient(
                colors: [color(state.background), color(state.background).mix(with: .black, by: 0.45)],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

/// Back a line and on a line, and the lyrics' timing, a little earlier or
/// later.
private struct LyricsControls: View {
    let delay: Int?

    var body: some View {
        HStack(spacing: 6) {
            HStack(spacing: 0) {
                Button(intent: LyricsLineIntent(forward: false)) {
                    Image(systemName: "chevron.up").frame(width: 26, height: 26)
                }
                .accessibilityLabel("Previous line")
                Button(intent: LyricsLineIntent(forward: true)) {
                    Image(systemName: "chevron.down").frame(width: 26, height: 26)
                }
                .accessibilityLabel("Next line")
            }
            .background(.white.opacity(0.14), in: .capsule)
            if let delay {
                HStack(spacing: 0) {
                    Button(intent: LyricsTimingIntent(earlier: false)) {
                        Image(systemName: "minus").frame(width: 24, height: 26)
                    }
                    .accessibilityLabel("Lyrics later")
                    Text(verbatim: delay == 0 ? "0s" : String(format: "%+.2gs", Double(delay) / 1000))
                        .font(.system(size: 11, weight: .semibold).monospacedDigit())
                        .contentTransition(.numericText(value: Double(delay)))
                        .frame(minWidth: 30)
                    Button(intent: LyricsTimingIntent(earlier: true)) {
                        Image(systemName: "plus").frame(width: 24, height: 26)
                    }
                    .accessibilityLabel("Lyrics earlier")
                }
                .background(.white.opacity(0.14), in: .capsule)
            }
        }
        .font(.system(size: 12, weight: .bold))
        .buttonStyle(.plain)
        .foregroundStyle(.white)
    }
}

/// Play or pause, and next.
private struct Controls: View {
    let isPlaying: Bool
    let accent: Color

    var body: some View {
        HStack(spacing: 14) {
            Button(intent: TogglePlaybackIntent()) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 20))
                    .contentTransition(.symbolEffect(.replace))
            }
            Button(intent: SkipToNextIntent()) {
                Image(systemName: "forward.fill").font(.system(size: 18))
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(accent)
    }
}

private struct Cover: View {
    let data: Data?
    let side: CGFloat
    /// Round, to fit the Dynamic Island's curve.
    var round = false

    var body: some View {
        Group {
            if let data, let image = UIImage(data: data) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                Image(systemName: "music.note").font(.system(size: side * 0.45)).foregroundStyle(.white.opacity(0.7))
            }
        }
        .frame(width: side, height: side)
        .background(.white.opacity(0.12))
        .clipShape(.rect(cornerRadius: round ? side / 2 : side * 0.22, style: .continuous))
    }
}

private func color(_ rgb: [Double]) -> Color {
    guard rgb.count == 3 else { return Color(white: 0.15) }
    return Color(red: rgb[0], green: rgb[1], blue: rgb[2])
}
