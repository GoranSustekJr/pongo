import PongoCore
import SwiftUI

/// The panel at the window's side: the lyrics or the queue over the cover's
/// colors, as in the iPhone's player.
struct InspectorView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let router = model.router
        let item = model.player.current
        ZStack {
            ArtworkBackground(url: item?.track.coverURL(size: 300), dim: 0.35, isMoving: model.player.isPlaying)
            if item == nil {
                LyricsMessage(title: L10n.nothingplaying)
            } else if router.inspector == .queue {
                QueuePanel(bottomInset: 0)
            } else {
                LyricsPanel(bottomInset: 0)
                    .environment(\.lyricsTextSize, 25)
                    .environment(\.closeLyrics) { model.router.inspector = nil }
            }
        }
        .environment(\.colorScheme, .dark)
    }
}

/// The player filling the window: the cover and controls on the left, and
/// the lyrics or the queue beside them, over the cover's moving colors.
struct MacNowPlayingView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let state = model.nowPlaying
        if let item = model.player.current {
            let mode = state.mode
            ZStack {
                ArtworkBackground(url: item.track.coverURL(size: 640), dim: 0.3, isMoving: model.player.isPlaying)
                HStack(spacing: 56) {
                    PlayerColumn(item: item, large: mode == .artwork)
                        .frame(maxWidth: mode == .artwork ? 520 : 400)
                    if mode != .artwork {
                        Group {
                            if mode == .lyrics {
                                LyricsPanel(bottomInset: 0).environment(\.lyricsTextSize, 32)
                            } else {
                                QueuePanel(bottomInset: 0)
                            }
                        }
                        .frame(maxWidth: 640)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 56)
                .padding(.top, 60)
                .padding(.bottom, 40)
                .animation(.spring(duration: 0.5, bounce: 0.12), value: mode)
            }
            .overlay(alignment: .topLeading) {
                Button {
                    model.router.showsPlayer = false
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 15, weight: .bold))
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(.plain)
                .pongoGlass(in: .circle, interactive: true)
                .keyboardShortcut(.cancelAction)
                .help(L10n.closeplayer)
                .padding(.leading, 84)
                .padding(.top, 12)
            }
            .environment(\.colorScheme, .dark)
            .foregroundStyle(.white)
            .tint(state.accent)
            .ignoresSafeArea()
        }
    }
}

/// The cover, title, progress and controls of the full player.
private struct PlayerColumn: View {
    @Environment(AppModel.self) private var model
    let item: QueueItem
    let large: Bool

    var body: some View {
        let player = model.player
        let state = model.nowPlaying
        VStack(spacing: 22) {
            CoverImage(url: item.track.coverURL(size: 640))
                .aspectRatio(1, contentMode: .fit)
                .coverShape(large ? 18 : 14)
                .shadow(color: .black.opacity(0.35), radius: 30, y: 14)
                .scaleEffect(player.isPlaying ? 1 : 0.9)
                .animation(.spring(duration: 0.5, bounce: 0.3), value: player.isPlaying)
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Marquee(text: item.track.name).font(.system(size: 22, weight: .bold))
                        ArtistLinks(artists: item.track.artists)
                            .font(.system(size: 17))
                            .opacity(0.75)
                    }
                    Spacer(minLength: 12)
                    Menu {
                        TrackMenu(track: item.track, collectionID: item.collectionID)
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 15, weight: .bold))
                            .frame(width: 32, height: 32)
                    }
                    .menuStyle(.button)
                    .menuIndicator(.hidden)
                    .buttonStyle(.plain)
                    .pongoGlass(in: .circle, interactive: true)
                }
                Scrubber(item: item, showsTimes: true, height: 6, color: .white)
                    .tint(state.accent)
                    .foregroundStyle(.white.opacity(0.75))
                    .padding(.top, 10)
            }
            HStack(spacing: 34) {
                Button { player.setShuffle(!player.queue.shuffleEnabled) } label: {
                    Image(systemName: "shuffle").font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(player.queue.shuffleEnabled ? state.accent : .white.opacity(0.55))
                }
                .disabled(!player.canShuffle)
                Button(action: player.skipToPrevious) {
                    Image(systemName: "backward.fill").font(.system(size: 30))
                }
                Button(action: player.togglePlayback) {
                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 46))
                        .contentTransition(.symbolEffect(.replace.downUp))
                        .frame(width: 56)
                }
                .keyboardShortcut(.space, modifiers: [])
                Button(action: player.skipToNext) {
                    Image(systemName: "forward.fill").font(.system(size: 30))
                }
                Button(action: player.cycleRepeatMode) {
                    Image(systemName: player.queue.repeatMode == .one ? "repeat.1" : "repeat")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(player.queue.repeatMode == .off ? .white.opacity(0.55) : state.accent)
                }
            }
            .buttonStyle(.press)
            HStack(spacing: 22) {
                Image(systemName: "speaker.fill").font(.system(size: 12)).opacity(0.6)
                Slider(value: Binding(get: { player.volume }, set: player.setVolume), in: 0...1)
                    .controlSize(.small)
                Image(systemName: "speaker.wave.3.fill").font(.system(size: 12)).opacity(0.6)
            }
            .frame(maxWidth: 300)
            HStack(spacing: 18) {
                modeButton(state.lyricsOn ? "quote.bubble.fill" : "quote.bubble", on: state.mode == .lyrics) {
                    state.toggleLyrics(model)
                }
                .opacity(state.lyricsExist ? 1 : 0.5)
                modeButton("list.bullet", on: state.mode == .queue) {
                    state.showsQueue.toggle()
                    if state.showsQueue { state.lyricsOn = false }
                }
                RoutePicker().frame(width: 34, height: 34)
            }
        }
    }

    private func modeButton(_ image: String, on: Bool, action: @escaping () -> Void) -> some View {
        Button {
            withAnimation(.spring(duration: 0.5, bounce: 0.12), action)
        } label: {
            Image(systemName: image)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(on ? .black : .white)
                .frame(width: 34, height: 34)
                .background(on ? AnyShapeStyle(.white) : AnyShapeStyle(.clear), in: .circle)
        }
        .buttonStyle(.plain)
        .pongoGlass(in: .circle, interactive: true)
    }
}

/// The track's artists, each opening its page.
private struct ArtistLinks: View {
    @Environment(AppModel.self) private var model
    let artists: [ArtistRef]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(artists.enumerated()), id: \.offset) { index, artist in
                Button(artist.name ?? "") {
                    Task {
                        model.router.showsPlayer = false
                        await model.showArtist(artist)
                    }
                }
                .pointerStyle(.link)
                if index < artists.count - 1 { Text(verbatim: ", ") }
            }
        }
        .lineLimit(1)
        .buttonStyle(.plain)
    }
}
