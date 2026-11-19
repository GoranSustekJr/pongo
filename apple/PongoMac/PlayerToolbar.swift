import AVKit
import PongoCore
import SwiftUI

/// The player in the window's toolbar: the transport on the left, the song
/// playing in the middle and volume, AirPlay, lyrics and the queue on the
/// right.
struct PlayerToolbar: ToolbarContent {
    @Environment(AppModel.self) private var model

    var body: some ToolbarContent {
        let player = model.player
        let router = model.router
        let hasTrack = player.current != nil
        ToolbarItemGroup(placement: .navigation) {
            Button(L10n.shuffle, systemImage: "shuffle") { player.setShuffle(!player.queue.shuffleEnabled) }
                .foregroundStyle(player.queue.shuffleEnabled ? Color.pongoTeal : .primary)
                .disabled(!player.canShuffle || !hasTrack)
            Button(L10n.previous, systemImage: "backward.fill", action: player.skipToPrevious)
                .disabled(!hasTrack)
            Button(player.isPlaying ? L10n.pause : L10n.play, systemImage: player.isPlaying ? "pause.fill" : "play.fill",
                action: player.togglePlayback
            )
            .contentTransition(.symbolEffect(.replace))
            .disabled(!hasTrack)
            Button(L10n.next, systemImage: "forward.fill", action: player.skipToNext)
                .disabled(!hasTrack)
            Button(L10n.repeatmode, systemImage: player.queue.repeatMode == .one ? "repeat.1" : "repeat") {
                player.cycleRepeatMode()
            }
            .foregroundStyle(player.queue.repeatMode == .off ? Color.primary : Color.pongoTeal)
            .disabled(!hasTrack)
        }
        ToolbarItem(placement: .principal) {
            NowPlayingCapsule()
        }
        ToolbarItemGroup(placement: .primaryAction) {
            VolumeControl()
            RoutePicker().frame(width: 28, height: 28)
            Button(L10n.lyrics, systemImage: router.inspector == .lyrics ? "quote.bubble.fill" : "quote.bubble") {
                router.toggleInspector(.lyrics)
            }
            Button(L10n.queue, systemImage: "list.bullet") { router.toggleInspector(.queue) }
                .foregroundStyle(router.inspector == .queue ? Color.pongoTeal : .primary)
        }
    }
}

/// The song playing, like the display in the middle of Mac music apps: its
/// cover, which opens the full player, its title and artists, and where in
/// it the player is.
private struct NowPlayingCapsule: View {
    @Environment(AppModel.self) private var model
    @State private var hovering = false

    var body: some View {
        let player = model.player
        HStack(spacing: 10) {
            if let item = player.current {
                Button {
                    model.router.showsPlayer = true
                } label: {
                    CoverImage(url: item.track.coverURL(size: 150))
                        .frame(width: 34, height: 34)
                        .coverShape(6)
                        .overlay {
                            if hovering {
                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .background(.black.opacity(0.35))
                                    .coverShape(6)
                            }
                        }
                }
                .buttonStyle(.plain)
                .help(L10n.openplayer)
                VStack(spacing: 1) {
                    Marquee(text: item.track.name, alignment: .center)
                        .font(.system(size: 12, weight: .semibold))
                    Marquee(text: item.track.artistNames, alignment: .center)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Scrubber(item: item, showsTimes: hovering)
                }
                .frame(maxWidth: .infinity)
            } else {
                Image("Logo").resizable().scaledToFit().frame(width: 22, height: 22).opacity(0.6)
                Text(L10n.nothingplaying).font(.system(size: 12)).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.leading, 4)
        .padding(.trailing, 12)
        .frame(minWidth: 260, idealWidth: 420, maxWidth: 440, minHeight: 42, maxHeight: 42)
        .contentShape(.rect)
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.15), value: hovering)
    }
}

/// A thin bar of how far the track has played, which seeks where it's
/// clicked or dragged to.
struct Scrubber: View {
    @Environment(AppModel.self) private var model
    let item: QueueItem
    var showsTimes = false
    var height: CGFloat = 3
    var color: Color = .primary

    @State private var dragged: Double?
    @State private var seeking: Double?

    var body: some View {
        let player = model.player
        let duration = player.duration > 0 ? player.duration : item.duration
        let position = dragged.map { $0 * duration } ?? seeking ?? player.progress.position
        HStack(spacing: 6) {
            if showsTimes {
                Text(formatTime(position)).frame(width: 34, alignment: .trailing)
            }
            GeometryReader { geometry in
                let width = max(geometry.size.width, 1)
                let fraction = duration > 0 ? min(max(position / duration, 0), 1) : 0
                Capsule()
                    .fill(color.opacity(0.15))
                    .overlay(alignment: .leading) {
                        Capsule().fill(color.opacity(0.7)).frame(width: width * fraction)
                    }
                    .frame(height: dragged == nil ? height : height + 2)
                    .frame(maxHeight: .infinity)
                    .contentShape(.rect)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { dragged = min(max($0.location.x / width, 0), 1) }
                            .onEnded { drag in
                                let fraction = min(max(drag.location.x / width, 0), 1)
                                seeking = fraction * duration
                                dragged = nil
                                player.seek(to: fraction * duration)
                            }
                    )
            }
            .frame(height: 10)
            if showsTimes {
                Text("-" + formatTime(max(duration - position, 0))).frame(width: 38, alignment: .leading)
            }
        }
        .font(.system(size: 10).monospacedDigit())
        .foregroundStyle(.secondary)
        .onChange(of: player.progress.position) {
            if let target = seeking, abs(target - player.progress.position) < 1.5 { seeking = nil }
        }
        .onChange(of: item.id) { seeking = nil }
    }
}

/// The player's own volume, as a slider with a speaker that mutes.
private struct VolumeControl: View {
    @Environment(AppModel.self) private var model
    @State private var beforeMute = 1.0

    var body: some View {
        let player = model.player
        HStack(spacing: 6) {
            Button {
                if player.volume > 0 {
                    beforeMute = player.volume
                    player.setVolume(0)
                } else {
                    player.setVolume(beforeMute)
                }
            } label: {
                Image(systemName: speaker(player.volume))
                    .contentTransition(.symbolEffect(.replace))
                    .frame(width: 20)
            }
            .buttonStyle(.borderless)
            Slider(value: Binding(get: { player.volume }, set: player.setVolume), in: 0...1)
                .controlSize(.mini)
                .frame(width: 90)
        }
        .padding(.horizontal, 6)
        .help(L10n.volume)
    }

    private func speaker(_ volume: Double) -> String {
        switch volume {
        case 0: "speaker.slash.fill"
        case ..<0.34: "speaker.wave.1.fill"
        case ..<0.67: "speaker.wave.2.fill"
        default: "speaker.wave.3.fill"
        }
    }
}

/// The AirPlay button, which picks the speakers to play on.
struct RoutePicker: NSViewRepresentable {
    func makeNSView(context: Context) -> AVRoutePickerView {
        let view = AVRoutePickerView()
        view.isRoutePickerButtonBordered = false
        return view
    }

    func updateNSView(_ view: AVRoutePickerView, context: Context) {}
}
