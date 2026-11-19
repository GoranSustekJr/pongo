import PongoCore
import SwiftUI
import Translation

/// The current track's lyrics filling the player behind its controls, with
/// the delay and synced/plain buttons on top.
struct LyricsPanel: View {
    @Environment(AppModel.self) private var model
    /// Space the player's controls take at the bottom.
    var bottomInset: CGFloat

    var body: some View {
        let state = model.nowPlaying
        ZStack(alignment: .top) {
            Group {
                if state.lyrics == nil {
                    ProgressView().tint(.white).controlSize(.large)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if state.showsSynced {
                    if state.syncedLines.isEmpty {
                        LyricsMessage(title: L10n.nosynclyrics)
                    } else {
                        SyncedLyricsView(lines: state.syncedLines, bottomInset: bottomInset)
                    }
                } else if state.plainLines.isEmpty {
                    LyricsMessage(title: L10n.noplainlyrics)
                } else {
                    PlainLyricsView(lines: state.plainLines, bottomInset: bottomInset)
                }
            }
            .transition(.opacity)
            .id(state.showsSynced)
            LyricsBar()
        }
        .translationTask(state.translation) { session in
            let lines = state.linesToTranslate
            guard !lines.isEmpty else { return }
            // Translation's types aren't marked Sendable, though the session is
            // made to be used from this task
            nonisolated(unsafe) let session = session
            nonisolated(unsafe) let requests = lines.enumerated().map { index, line in
                TranslationSession.Request(sourceText: line, clientIdentifier: String(index))
            }
            let translated: [String: String]? = try? await session.translations(from: requests)
                .reduce(into: [:]) { found, response in
                    guard let index = response.clientIdentifier.flatMap(Int.init), lines.indices.contains(index)
                    else { return }
                    found[lines[index]] = response.targetText
                }
            state.showTranslations(translated, model: model)
        }
        .animation(.easeInOut(duration: 0.35), value: state.showsSynced)
        .animation(.easeInOut(duration: 0.35), value: state.lyrics == nil)
    }
}

extension EnvironmentValues {
    /// The size of lyrics lines: big on the iPhone's player, smaller in the
    /// Mac's side panel.
    @Entry var lyricsTextSize: CGFloat = 35
    /// Closes the lyrics, where they show in a panel of their own rather than
    /// in the player.
    @Entry var closeLyrics: (() -> Void)?
}

/// Lyrics alignment as SwiftUI needs it.
extension LyricsAlignment {
    var text: TextAlignment {
        switch self {
        case .left, .justify: .leading
        case .center: .center
        case .right: .trailing
        }
    }

    var frame: Alignment {
        switch self {
        case .left, .justify: .leading
        case .center: .center
        case .right: .trailing
        }
    }

    var anchor: UnitPoint {
        switch self {
        case .left, .justify: .leading
        case .center: .center
        case .right: .trailing
        }
    }
}

/// Synced lyrics that follow the track: the current line is big, bright and
/// sharp, the others smaller, dimmer and blurred the further they are. A tap
/// on a line seeks to it; scrolling by hand pauses following for a moment.
struct SyncedLyricsView: View {
    @Environment(AppModel.self) private var model
    let lines: [LyricsLine]
    var bottomInset: CGFloat

    @State private var active: Int?
    @State private var userScrolling = false
    @State private var resume: Task<Void, Never>?
    #if os(macOS)
        @State private var scroller = LyricsScroller()
    #endif

    /// Where the current line sits, from the top of the screen.
    private let anchor = UnitPoint(x: 0.5, y: 0.4)

    var body: some View {
        let alignment = model.settings.settings.lyricsTextAlign
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView {
                    // Every line laid out, not lazily, so scrolling to the current one lands
                    // exactly even when lines wrap to different heights
                    VStack(alignment: alignment.frame.horizontal, spacing: 22) {
                        ForEach(lines) { line in
                            lineView(line, alignment: alignment)
                                .id(line.id)
                                #if os(macOS)
                                    .onGeometryChange(for: CGRect.self) {
                                        $0.frame(in: .named(LyricsScroller.space))
                                    } action: { scroller.frames[line.id] = $0 }
                                #endif
                                .onTapGesture {
                                    model.player.seek(to: max(line.time - Double(model.nowPlaying.delay) / 1000, 0))
                                    resumeFollowing(proxy, after: .zero)
                                }
                                // Held, or right-clicked on a Mac, the line goes on a card to share
                                .onLongPressGesture(minimumDuration: 0.45) { share(line) }
                                .contextMenu {
                                    Button(L10n.sharelyrics, systemImage: "square.and.arrow.up") { share(line) }
                                }
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, geometry.size.height * anchor.y)
                    .padding(.bottom, geometry.size.height * (1 - anchor.y) + bottomInset)
                    #if os(macOS)
                        .coordinateSpace(.named(LyricsScroller.space))
                        .background { ScrollViewFinder(scroller: scroller) }
                    #endif
                }
                .scrollIndicators(.hidden)
                .onScrollPhaseChange { _, phase in
                    if phase == .interacting {
                        resume?.cancel()
                        withAnimation(.easeOut(duration: 0.25)) { userScrolling = true }
                    } else if phase == .idle, userScrolling {
                        resumeFollowing(proxy, after: .seconds(2.5))
                    }
                }
                .onChange(of: active) { _, index in
                    guard !userScrolling else { return }
                    glide(proxy, to: index)
                }
                .task {
                    // Once laid out: a Mac's scroll view doesn't exist yet when this appears,
                    // and would stay at the top
                    await Task.yield()
                    scroll(proxy, to: active)
                }
                // A resized panel rewraps the lines, which moves the current one
                .onChange(of: geometry.size) {
                    guard !userScrolling else { return }
                    scroll(proxy, to: active)
                }
                .background {
                    ActiveLineTracker(lines: lines, active: $active)
                }
            }
        }
        .mask { LyricsMask(bottomInset: bottomInset) }
        .ignoresSafeArea(edges: .bottom)
    }

    private func lineView(_ line: LyricsLine, alignment: LyricsAlignment) -> some View {
        let distance = line.id - (active ?? -1)
        let opacity: Double =
            switch distance {
            case 0: 1
            case 1: 0.78
            case 2: 0.6
            default: 0.4
            }
        // Before the first line is sung, it stays sharp as the one coming up
        let upcoming = active == nil && line.id == lines.first?.id
        let blur: CGFloat =
            switch distance {
            case 0: 0
            case 1: upcoming ? 0 : 2.25
            case -1: 2.75
            default: 3.5
            }
        return LyricsLineView(
            line: line, translation: model.nowPlaying.translations[line.text], alignment: alignment,
            isActive: distance == 0 && !userScrolling,
            opacity: userScrolling ? max(opacity, 0.6) : opacity, blur: userScrolling ? 0 : blur)
    }

    private func share(_ line: LyricsLine) {
        model.nowPlaying.shareLyrics(lines.map(\.text), at: lines.firstIndex(of: line) ?? 0, item: model.player.current)
    }

    private func scroll(_ proxy: ScrollViewProxy, to index: Int?) {
        let id = index ?? lines.first?.id ?? 0
        #if os(macOS)
            if scroller.scroll(to: id, anchor: anchor.y, animated: false) { return }
        #endif
        proxy.scrollTo(id, anchor: anchor)
    }

    /// Moves to the line at [index] smoothly. A Mac's scroll view jumps when
    /// SwiftUI animates it, so there the scroll view glides itself.
    private func glide(_ proxy: ScrollViewProxy, to index: Int?) {
        #if os(macOS)
            if scroller.scroll(to: index ?? lines.first?.id ?? 0, anchor: anchor.y, animated: true) { return }
        #endif
        withAnimation(.spring(duration: 0.5, bounce: 0.1)) { scroll(proxy, to: index) }
    }

    private func resumeFollowing(_ proxy: ScrollViewProxy, after delay: Duration) {
        resume?.cancel()
        resume = Task {
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled else { return }
            withAnimation(.spring(duration: 0.6, bounce: 0.1)) { userScrolling = false }
            glide(proxy, to: active)
        }
    }
}

#if os(macOS)
    /// Scrolls the lyrics' AppKit scroll view itself, which glides where a
    /// SwiftUI animation makes it jump. Where each line lies is measured once
    /// per layout and kept here, so scrolling redraws nothing.
    @MainActor
    final class LyricsScroller {
        static let space = "lyrics"
        weak var scrollView: NSScrollView?
        var frames: [Int: CGRect] = [:]

        /// Puts the line [id] at [anchor] of the scroll view's height.
        /// Returns whether it could, which it can't before the first layout.
        func scroll(to id: Int, anchor: CGFloat, animated: Bool) -> Bool {
            guard let scrollView, let frame = frames[id], let document = scrollView.documentView else { return false }
            let clip = scrollView.contentView
            let height = clip.bounds.height
            let top = -clip.contentInsets.top
            let bottom = max(document.frame.height - height + clip.contentInsets.bottom, top)
            // The anchor is in the part not under the toolbar
            let visible = height - clip.contentInsets.top - clip.contentInsets.bottom
            let y = min(max(frame.minY + frame.height * anchor - (clip.contentInsets.top + visible * anchor), top), bottom)
            let origin = NSPoint(x: clip.bounds.origin.x, y: y)
            if animated {
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.55
                    context.timingFunction = CAMediaTimingFunction(controlPoints: 0.25, 0.8, 0.3, 1)
                    context.allowsImplicitAnimation = true
                    clip.animator().setBoundsOrigin(origin)
                }
            } else {
                clip.setBoundsOrigin(origin)
            }
            scrollView.reflectScrolledClipView(clip)
            return true
        }
    }

    /// Finds the scroll view the lyrics are in.
    private struct ScrollViewFinder: NSViewRepresentable {
        let scroller: LyricsScroller

        func makeNSView(context: Context) -> NSView { NSView() }

        func updateNSView(_ view: NSView, context: Context) {
            guard scroller.scrollView == nil else { return }
            Task { @MainActor in scroller.scrollView = view.enclosingScrollView }
        }
    }
#endif

/// One line of synced lyrics.
private struct LyricsLineView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.lyricsTextSize) private var textSize
    let line: LyricsLine
    /// The line in the user's language, shown under it.
    let translation: String?
    let alignment: LyricsAlignment
    let isActive: Bool
    let opacity: Double
    let blur: CGFloat

    var body: some View {
        // One text for both states, so turning current grows, brightens and
        // lights it up instead of swapping it
        VStack(alignment: alignment.frame.horizontal, spacing: 6) {
            Text(line.text.isEmpty ? "♪" : line.text)
                .font(.system(size: textSize, weight: .bold))
            if let translation {
                Text(translation)
                    .font(.system(size: textSize * 0.6, weight: .semibold))
                    .opacity(0.6)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
            .multilineTextAlignment(alignment.text)
            .foregroundStyle(.white.opacity(isActive ? 1 : opacity))
            .shadow(color: model.nowPlaying.accent.opacity(isActive ? 0.7 : 0), radius: 18)
            .frame(maxWidth: .infinity, alignment: alignment.frame)
            .scaleEffect(isActive ? 1 : 0.85, anchor: alignment.anchor)
            .blur(radius: blur)
            .animation(.spring(duration: 0.45, bounce: 0.25), value: isActive)
            .animation(.easeInOut(duration: 0.35), value: opacity)
            .animation(.easeInOut(duration: 0.35), value: blur)
            .contentShape(.rect)
    }
}

/// Watches the track's position and reports which line is current, so only
/// this tiny view updates several times a second.
private struct ActiveLineTracker: View {
    @Environment(AppModel.self) private var model
    let lines: [LyricsLine]
    @Binding var active: Int?

    var body: some View {
        // Lines turn current a quarter second early, as in the Flutter app
        let position = model.player.progress.position + Double(model.nowPlaying.delay) / 1000 + 0.25
        let current = lines.lastIndex { $0.time <= position }.map { lines[$0].id }
        Color.clear
            .onChange(of: current, initial: true) { _, line in active = line }
    }
}

/// Plain lyrics, scrolled by hand.
struct PlainLyricsView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.lyricsTextSize) private var textSize
    let lines: [String]
    var bottomInset: CGFloat

    var body: some View {
        let alignment = model.settings.settings.lyricsTextAlign
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: alignment.frame.horizontal, spacing: 0) {
                    ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                        let blank = line.trimmingCharacters(in: .whitespaces).isEmpty
                        VStack(alignment: alignment.frame.horizontal, spacing: 6) {
                            Text(blank ? " " : line)
                                .font(.system(size: blank ? 15 : textSize, weight: .bold))
                            if let translation = model.nowPlaying.translations[line] {
                                Text(translation).font(.system(size: textSize * 0.6, weight: .semibold)).opacity(0.6)
                            }
                        }
                            .multilineTextAlignment(alignment.text)
                            .frame(maxWidth: .infinity, alignment: alignment.frame)
                            .padding(.vertical, blank ? 4 : 15)
                            .contentShape(.rect)
                            .onLongPressGesture(minimumDuration: 0.45) {
                                model.nowPlaying.shareLyrics(lines, at: index, item: model.player.current)
                            }
                            .contextMenu {
                                Button(L10n.sharelyrics, systemImage: "square.and.arrow.up") {
                                    model.nowPlaying.shareLyrics(lines, at: index, item: model.player.current)
                                }
                            }
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, geometry.size.height * 0.3)
                .padding(.bottom, geometry.size.height * 0.4 + bottomInset)
            }
            .scrollIndicators(.hidden)
        }
        .foregroundStyle(.white)
        .mask { LyricsMask(bottomInset: bottomInset) }
        .ignoresSafeArea(edges: .bottom)
    }
}

/// Fades lyrics in below the buttons on top and out before the controls,
/// so no line runs under them.
private struct LyricsMask: View {
    var bottomInset: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom).frame(height: 110)
            Color.black
            LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom).frame(height: 80)
            Color.clear.frame(height: bottomInset)
        }
    }
}

/// Says that a track has no lyrics of a kind and how to add them.
struct LyricsMessage: View {
    var title: String

    var body: some View {
        VStack(spacing: 6) {
            Text(title).font(.system(size: 29, weight: .bold))
            Text(L10n.wanttohelpoutlyrics).font(.system(size: 15, weight: .medium)).opacity(0.85)
        }
        .multilineTextAlignment(.center)
        .foregroundStyle(.white)
        .padding(.horizontal, 30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 160)
    }
}

/// The buttons over the lyrics: closing them, shifting synced lyrics in time
/// and switching between synced and plain lyrics.
struct LyricsBar: View {
    @Environment(AppModel.self) private var model
    @Environment(\.closeLyrics) private var closeLyrics

    var body: some View {
        let state = model.nowPlaying
        HStack(spacing: 0) {
            Spacer()
            GlassIconButton(systemImage: "quote.bubble.fill", isOn: true) {
                withAnimation(.spring(duration: 0.55, bounce: 0.12)) {
                    if let closeLyrics { closeLyrics() } else { state.toggleLyrics(model) }
                }
            }
            Spacer()
            HStack(spacing: 0) {
                Button(action: state.decreaseDelay) {
                    Image(systemName: "minus").frame(width: 40, height: 40).contentShape(.rect)
                }
                Spacer(minLength: 0)
                Text(verbatim: "\(Double(state.delay) / 1000) s")
                    .font(.system(size: 13, weight: .semibold).monospacedDigit())
                    .contentTransition(.numericText(value: Double(state.delay)))
                    .frame(maxHeight: .infinity)
                    .contentShape(.rect)
                    .onTapGesture { withAnimation(.snappy) { state.resetDelay() } }
                    .onLongPressGesture { Task { await state.saveDelay(model) } }
                Spacer(minLength: 0)
                Button(action: state.increaseDelay) {
                    Image(systemName: "plus").frame(width: 40, height: 40).contentShape(.rect)
                }
            }
            .font(.system(size: 16, weight: .semibold))
            .buttonStyle(.press)
            .frame(width: 150, height: 42)
            .playerChrome(in: Capsule())
            .opacity(state.showsSynced ? 1 : 0.5)
            .disabled(!state.showsSynced)
            .animation(.snappy, value: state.delay)
            .sensoryFeedback(.success, trigger: state.savedDelay)
            .sensoryFeedback(.selection, trigger: state.delay)
            Spacer()
            GlassIconButton(systemImage: "translate", isOn: state.translates) {
                Task { await state.toggleTranslation(model) }
            }
            Spacer()
        }
        .foregroundStyle(.white)
        .tint(state.accent)
        .padding(.top, 12)
    }
}
