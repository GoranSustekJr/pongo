import PongoCore
import SwiftUI

/// The current track full screen, like the Flutter app's player: a big cover
/// that pauses on tap over the cover's blurred colors, and the controls below.
/// The lyrics or the queue can take the cover's place, which then shrinks
/// next to the title.
struct NowPlayingView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Namespace private var namespace
    @State private var controlsHeight: CGFloat = 260
    @State private var confirmHalt = false

    var body: some View {
        let player = model.player
        let state = model.nowPlaying
        let mode = state.mode
        GeometryReader { geometry in
            ZStack {
                ArtworkBackground(url: player.current?.track.coverURL(size: 300), isMoving: player.isPlaying)
                switch mode {
                case .lyrics:
                    LyricsPanel(bottomInset: controlsHeight)
                        .transition(.opacity)
                case .queue:
                    QueuePanel(bottomInset: controlsHeight)
                        .transition(.opacity.combined(with: .offset(y: 60)))
                case .artwork:
                    EmptyView()
                }
                if let item = player.current {
                    VStack(spacing: 0) {
                        if mode == .artwork {
                            grabber
                            artwork(item, side: artworkSide(geometry.size))
                                .frame(maxHeight: .infinity)
                        } else {
                            Spacer(minLength: 0)
                        }
                        PlayerControls(item: item, mode: mode, namespace: namespace, confirmHalt: $confirmHalt)
                            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { controlsHeight = $0 }
                            .background(alignment: .bottom) { controlsBackground(mode) }
                    }
                }
            }
        }
        .animation(.spring(duration: 0.55, bounce: 0.12), value: mode)
        .foregroundStyle(.white)
        .tint(.white)
        .preferredColorScheme(.dark)
        #if os(iOS)
            .background { DarkInterface() }
        #endif
        .alert(L10n.haltmusicplayer, isPresented: $confirmHalt) {
            Button(L10n.cancel, role: .cancel) {}
            Button(L10n.halt, role: .destructive) { player.halt() }
        } message: {
            Text(L10n.haltmusicplayerbody)
        }
        .sheet(item: Bindable(model.nowPlaying).lyricCard) { request in
            LyricCardSheet(request: request)
        }
        .sheet(item: Bindable(model).playlistRequest) { request in
            PlaylistPicker(request: request)
        }
        .task(id: player.current?.stid) { await state.loadAccent(player.current?.track.coverURL(size: 300)) }
        .task(id: player.current.map { "\($0.stid)|\($0.duration > 0)" }) {
            if let item = player.current { await state.load(item, model: model) }
        }
        .onChange(of: player.current == nil) { _, empty in if empty { dismiss() } }
        .sensoryFeedback(.impact(weight: .light), trigger: player.isPlaying)
    }

    /// The cover's side: the screen's width less margins, unless the screen is
    /// too short for the controls below.
    private func artworkSide(_ size: CGSize) -> CGFloat {
        max(min(size.width - 36, size.height - controlsHeight - 70), 120)
    }

    private var grabber: some View {
        Capsule()
            .fill(.white.opacity(0.35))
            .frame(width: 38, height: 5)
            .padding(.top, 8)
            .frame(maxWidth: .infinity, minHeight: 22)
            .contentShape(.rect)
            .onTapGesture { dismiss() }
            .accessibilityLabel(L10n.close)
            .accessibilityAddTraits(.isButton)
    }

    /// The big cover; a tap plays or pauses, and it shrinks while paused.
    private func artwork(_ item: QueueItem, side: CGFloat) -> some View {
        let player = model.player
        return CoverImage(url: item.track.coverURL)
            .frame(width: side, height: side)
            .overlay { Color.black.opacity(player.isPlaying ? 0 : 0.1) }
            .coverShape(15)
            .matchedGeometryEffect(id: "artwork", in: namespace)
            .shadow(color: .black.opacity(player.isPlaying ? 0.4 : 0.25), radius: player.isPlaying ? 30 : 16, y: 14)
            .scaleEffect(player.isPlaying ? 1 : 0.85)
            .animation(.spring(response: 0.55, dampingFraction: 0.5), value: player.isPlaying)
            .onTapGesture { player.togglePlayback() }
            .frame(maxWidth: .infinity)
    }

    /// What lies behind the controls: a shade over synced lyrics and a glass
    /// panel over the queue.
    @ViewBuilder private func controlsBackground(_ mode: NowPlayingModel.Mode) -> some View {
        switch mode {
        case .lyrics:
            LinearGradient(
                colors: [.clear, .black.opacity(0.35), .black.opacity(0.55)], startPoint: .top, endPoint: .bottom
            )
            .padding(.top, -110)
            .ignoresSafeArea(edges: .bottom)
            .allowsHitTesting(false)
            .transition(.opacity)
        case .queue:
            Color.clear
                .playerChrome(in: RoundedRectangle(cornerRadius: 44, style: .continuous))
                .padding(EdgeInsets(top: -6, leading: 6, bottom: 6, trailing: 6))
                .ignoresSafeArea(edges: .bottom)
                .transition(.opacity)
        case .artwork:
            EmptyView()
        }
    }
}

/// The title, progress, transport, volume and the row of extra buttons.
private struct PlayerControls: View {
    @Environment(AppModel.self) private var model
    let item: QueueItem
    let mode: NowPlayingModel.Mode
    let namespace: Namespace.ID
    @Binding var confirmHalt: Bool

    var body: some View {
        VStack(spacing: 0) {
            TitleRow(item: item, mode: mode, namespace: namespace)
            PlayerProgress(item: item)
            transport
            VolumeRow()
            // Lyrics have their own bar; from the cover and the queue, this row switches between them
            if mode != .lyrics {
                bottomRow.transition(.opacity)
            }
        }
        .padding(.horizontal, 15)
        .padding(.top, 10)
        .padding(.bottom, mode == .lyrics ? 8 : 0)
    }

    private var transport: some View {
        let player = model.player
        return HStack(spacing: 0) {
            Spacer()
            Button(action: player.skipToPrevious) {
                Image(systemName: "backward.fill").font(.system(size: 34)).frame(width: 64, height: 60)
            }
            Spacer()
            Button(action: player.togglePlayback) {
                ZStack {
                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 55))
                        .contentTransition(.symbolEffect(.replace.downUp))
                        .opacity(player.isBuffering ? 0 : 1)
                    if player.isBuffering { ProgressView().tint(.white).controlSize(.large) }
                }
                .frame(width: 80, height: 64)
            }
            Spacer()
            Button(action: player.skipToNext) {
                Image(systemName: "forward.fill").font(.system(size: 34)).frame(width: 64, height: 60)
            }
            Spacer()
        }
        .buttonStyle(.press)
        .frame(height: 64)
    }

    private var bottomRow: some View {
        let player = model.player
        let state = model.nowPlaying
        let repeatMode = player.queue.repeatMode
        return HStack(spacing: 0) {
            Button {
                withAnimation(.spring(duration: 0.55, bounce: 0.12)) { state.toggleLyrics(model) }
            } label: {
                Image(systemName: state.lyricsOn ? "quote.bubble.fill" : "quote.bubble")
                    .opacity(state.lyricsExist ? 1 : 0.55)
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            Button {
                cycleRepeat()
            } label: {
                Image(systemName: repeatMode == .one ? "repeat.1" : "repeat")
                    .opacity(repeatMode == .off ? 0.55 : 1)
                    .contentTransition(.symbolEffect(.replace))
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            Menu {
                moreMenu
            } label: {
                Image(systemName: "ellipsis")
                    .rotationEffect(.degrees(90))
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(.rect)
            }
            Button {
                withAnimation(.spring(duration: 0.55, bounce: 0.12)) { state.toggleQueue() }
            } label: {
                Image(systemName: state.showsQueue ? "rectangle.stack.fill" : "rectangle.stack")
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
        }
        .font(.system(size: 19))
        .buttonStyle(.press)
        .padding(.top, 2)
        .sensoryFeedback(.selection, trigger: repeatMode)
    }

    @ViewBuilder private var moreMenu: some View {
        let track = item.track
        if !track.isDownloaded {
            if !model.downloadedIDs.contains(track.id) {
                Button(L10n.download, systemImage: "icloud.and.arrow.down") {
                    Task { await model.download(track) }
                }
            }
            Button(L10n.addtoplaylist, systemImage: "music.note.list") {
                Task { await model.addToPlaylist([track]) }
            }
            let favourite = model.favouriteIDs.contains(track.id)
            Button(favourite ? L10n.unlike : L10n.like, systemImage: favourite ? "heart.fill" : "heart") {
                Task { await model.toggleFavourite(track) }
            }
        } else {
            Button(L10n.addtoplaylist, systemImage: "music.note.list") {
                Task { await model.addToPlaylist([track], kind: .offline) }
            }
        }
        Divider()
        if let album = track.album, !album.id.isEmpty, !track.isDownloaded {
            Button(L10n.album, systemImage: "square.stack") { Task { await model.showAlbum(album.id) } }
        }
        ForEach(track.artists, id: \.id) { artist in
            Button(artist.name ?? L10n.artist, systemImage: "music.microphone") {
                Task { await model.showArtist(artist) }
            }
        }
        if isDJMix(item) {
            Divider()
            Button("Shazam", systemImage: "shazam.logo") { Task { await model.shazam(item.stid) } }
        }
        Divider()
        Button(L10n.halt, systemImage: "stop.fill") { confirmHalt = true }
    }

    /// Off, then the track, then the whole queue, as in the Flutter app.
    private func cycleRepeat() {
        let player = model.player
        guard player.activeSleepAlarm == -1 else {
            model.messages.show(L10n.sleepalarmisenabled, systemImage: "alarm", isError: true)
            return
        }
        let next: RepeatMode =
            switch player.queue.repeatMode {
            case .off: .one
            case .one: .all
            case .all: .off
            }
        player.setRepeatMode(next)
    }
}

/// The title and artists, centered while playing; next to them the small
/// cover while lyrics or the queue show.
private struct TitleRow: View {
    @Environment(AppModel.self) private var model
    let item: QueueItem
    let mode: NowPlayingModel.Mode
    let namespace: Namespace.ID

    var body: some View {
        let player = model.player
        let centered = mode == .artwork && player.isPlaying
        let alignment: Alignment = centered ? .center : .leading
        HStack(spacing: 12) {
            if mode != .artwork {
                CoverImage(url: item.track.coverURL(size: 300))
                    .frame(width: 50, height: 50)
                    .coverShape(5)
                    .matchedGeometryEffect(id: "artwork", in: namespace)
                    .scaleEffect(player.isPlaying ? 1 : 0.85)
                    .animation(.spring(response: 0.55, dampingFraction: 0.5), value: player.isPlaying)
                    .onTapGesture { player.togglePlayback() }
            }
            VStack(spacing: 0) {
                Marquee(text: item.track.name, alignment: alignment)
                    .font(.system(size: 22, weight: .bold))
                    .frame(height: 28)
                ArtistLinks(artists: item.track.artists, alignment: alignment)
                    .frame(height: 24)
            }
            .animation(.smooth(duration: 0.5), value: centered)
        }
        .frame(height: 54)
    }
}

/// Whether [item] is a long mix of several songs, which Shazam can name.
private func isDJMix(_ item: QueueItem) -> Bool {
    item.isMix || item.track.name.range(of: #"Mix #\d{1,2}"#, options: .regularExpression) != nil
}

/// The artists of a track, each opening its page; scrolls sideways when they
/// don't fit.
private struct ArtistLinks: View {
    @Environment(AppModel.self) private var model
    let artists: [ArtistRef]
    var alignment: Alignment

    @State private var width: CGFloat = 0

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 0) {
                ForEach(Array(artists.enumerated()), id: \.offset) { index, artist in
                    Button(artist.name ?? "") { Task { await model.showArtist(artist) } }
                    if index < artists.count - 1 { Text(verbatim: ", ") }
                }
            }
            .font(.system(size: 18.5))
            .lineLimit(1)
            .fixedSize()
            .frame(minWidth: width, alignment: alignment)
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
        .buttonStyle(.plain)
    }
}

/// How far the track has played, which can be dragged to seek, with the
/// album under it that opens on tap.
private struct PlayerProgress: View {
    @Environment(AppModel.self) private var model
    let item: QueueItem

    /// The part of the track dragged to, while dragging.
    @State private var dragged: Double?
    /// The second sought to, until the player gets there.
    @State private var seeking: Double?

    var body: some View {
        let player = model.player
        let duration = player.duration > 0 ? player.duration : item.duration
        let position = dragged.map { $0 * duration } ?? seeking ?? player.progress.position
        let album = item.track.album
        VStack(spacing: 0) {
            ElasticSlider(
                value: duration > 0 ? position / duration : 0, height: 7, focusedHeight: 11.5,
                onChanged: { dragged = $0 },
                onEnded: { fraction in
                    seeking = fraction * duration
                    dragged = nil
                    player.seek(to: fraction * duration)
                }
            )
            .frame(height: 22)
            .tint(model.nowPlaying.accent)
            HStack(spacing: 8) {
                Text(formatTime(position)).frame(width: 54, alignment: .leading)
                Button {
                    if let album, !album.id.isEmpty, !item.track.isDownloaded {
                        Task { await model.showAlbum(album.id) }
                    }
                } label: {
                    Marquee(text: album?.name ?? "", alignment: .center)
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                Text("-" + formatTime(max(duration - position, 0))).frame(width: 54, alignment: .trailing)
            }
            .font(.system(size: 14).monospacedDigit())
            .foregroundStyle(.white.opacity(0.78))
            .frame(height: 28)
        }
        .padding(.top, 8)
        .onChange(of: player.progress.position) { _, now in
            if let seeking, abs(now - seeking) < 1.5 { self.seeking = nil }
        }
        .task(id: seeking) {
            guard seeking != nil else { return }
            try? await Task.sleep(for: .seconds(2))
            seeking = nil
        }
    }
}

/// The device's volume, with an icon showing its level and the AirPlay
/// picker at its end.
private struct VolumeRow: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        #if os(iOS)
            let level = model.volume.level
            ElasticSlider(value: level, height: 7, focusedHeight: 14, onChanged: { model.volume.set($0) }) {
                Image(systemName: icon(level))
                    .font(.system(size: 16))
                    .contentTransition(.symbolEffect(.replace))
                    .frame(width: 26)
            } trailing: {
                RoutePicker().frame(width: 28, height: 28)
            }
            .frame(height: 50)
            .tint(model.nowPlaying.accent)
        #endif
    }

    private func icon(_ level: Double) -> String {
        switch level {
        case ...0: "speaker.slash.fill"
        case ...0.33: "speaker.wave.1.fill"
        case ...0.67: "speaker.wave.2.fill"
        default: "speaker.wave.3.fill"
        }
    }
}

#if os(iOS)
    /// Makes the window dark while the player is open. Menus held open on a
    /// track are drawn on the window, outside the player, so they'd follow
    /// the phone's appearance and come out light under the player's white
    /// text. The window's own appearance comes back once the player closes.
    private struct DarkInterface: UIViewRepresentable {
        func makeUIView(context: Context) -> DarkView { DarkView() }
        func updateUIView(_ uiView: DarkView, context: Context) {}

        final class DarkView: UIView {
            private var previous: UIUserInterfaceStyle?

            override func willMove(toWindow newWindow: UIWindow?) {
                super.willMove(toWindow: newWindow)
                if newWindow == nil, let window, let previous {
                    window.overrideUserInterfaceStyle = previous
                    self.previous = nil
                }
            }

            override func didMoveToWindow() {
                super.didMoveToWindow()
                guard let window, previous == nil else { return }
                previous = window.overrideUserInterfaceStyle
                window.overrideUserInterfaceStyle = .dark
            }
        }
    }
#endif
