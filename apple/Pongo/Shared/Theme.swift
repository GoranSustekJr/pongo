import PongoCore
import SwiftUI

// MARK: - Colors

extension Color {
    /// The teal of the Flutter app's accents.
    static let pongoTeal = Color(red: 32 / 255, green: 178 / 255, blue: 170 / 255)
    /// Cards and placeholders: navy in dark mode, white in light mode.
    static let pongoCard = adaptive(
        light: .white, dark: PlatformColor(red: 28 / 255, green: 39 / 255, blue: 85 / 255, alpha: 1))
    /// The navy behind everything in dark mode, off-white in light mode.
    static let pongoSurface = adaptive(
        light: PlatformColor(white: 0.996, alpha: 1),
        dark: PlatformColor(red: 20 / 255, green: 28 / 255, blue: 61 / 255, alpha: 1))
}

extension EnvironmentValues {
    /// Whether controls float on Liquid Glass or on a plain blur.
    @Entry var usesLiquidGlass = true
}

// MARK: - Backgrounds

/// The gradient image behind the app's screens.
struct AppBackground: View {
    var body: some View {
        Color.pongoSurface
            .overlay { Image("Background").resizable().scaledToFill() }
            .clipped()
            .ignoresSafeArea()
    }
}

extension View {
    /// Puts the app's gradient behind a screen and hides the list background
    /// that would cover it.
    func pongoBackground() -> some View {
        scrollContentBackground(.hidden)
            .scrollEdgeEffectHidden(true, for: .all)
            .background { AppBackground() }
    }

    /// Liquid Glass behind the view, or a translucent material when the user
    /// turned glass off.
    func pongoGlass<S: Shape>(in shape: S, interactive: Bool = false) -> some View {
        modifier(PongoGlass(shape: shape, interactive: interactive))
    }
}

private struct PongoGlass<S: Shape>: ViewModifier {
    @Environment(\.usesLiquidGlass) private var liquidGlass
    let shape: S
    let interactive: Bool

    func body(content: Content) -> some View {
        if liquidGlass {
            content.glassEffect(.regular.interactive(interactive), in: shape)
        } else {
            content.background(.ultraThinMaterial, in: shape)
        }
    }
}

/// A cover blurred until only its colors remain, behind the player and
/// collections like the Flutter app's blurhash. Falls back to the app's
/// gradient when blur is off or there's no cover.
struct ArtworkBackground: View {
    @Environment(AppModel.self) private var model
    var url: URL?
    /// A cover stored with a playlist, used when there's no URL.
    var data: Data?
    /// How much black lies over the colors, so white text stays readable.
    var dim = 0.25
    /// Whether the colors move, as behind a song that's playing. They stop
    /// where they are when it's paused.
    var isMoving = false

    @State private var image: PlatformImage?
    /// Seconds the colors moved before they last stopped.
    @State private var movedBefore: Double = 0
    @State private var movingSince: Date?

    var body: some View {
        let settings = model.settings.settings
        let moving = isMoving && settings.useDynamicBlurhash && settings.useAnimations
        ZStack {
            if settings.useBlur, let image {
                Color.black
                    .overlay {
                        TimelineView(.animation(minimumInterval: 1 / 30, paused: movingSince == nil)) { context in
                            colors(image, phase: movedBefore + (movingSince.map { context.date.timeIntervalSince($0) } ?? 0))
                        }
                    }
                    .clipped()
                    .transition(.opacity)
                    .id(image)
                Color.black.opacity(dim)
            } else {
                AppBackground()
                Color.black.opacity(dim / 2)
            }
        }
        .animation(.easeInOut(duration: 0.6), value: image)
        .ignoresSafeArea()
        .task(id: url?.absoluteString ?? data.map { "data:\($0.hashValue)" }) {
            if let url {
                image = await ImagePipeline.shared.blurred(for: url)
            } else if let data {
                image = await ImagePipeline.shared.blurred(data: data)
            } else {
                image = nil
            }
        }
        .onChange(of: moving, initial: true) { _, moving in
            if moving {
                movingSince = movingSince ?? Date()
            } else if let since = movingSince {
                movedBefore += Date().timeIntervalSince(since)
                movingSince = nil
            }
        }
    }

    /// The blurred cover twice, turning slowly against each other, so its
    /// colors flow into one another.
    private func colors(_ image: PlatformImage, phase: Double) -> some View {
        ZStack {
            Image(platformImage: image).resizable().scaledToFill()
                .scaleEffect(1.6)
                .rotationEffect(.degrees(phase * 7))
            Image(platformImage: image).resizable().scaledToFill()
                .scaleEffect(2.1)
                .rotationEffect(.degrees(150 - phase * 11))
                .offset(x: sin(phase * 0.35) * 70, y: cos(phase * 0.27) * 110)
                .opacity(0.6)
        }
    }
}

// MARK: - Text

/// A section heading on the home and artist screens.
struct SectionTitle: View {
    var title: String

    init(_ title: String) { self.title = title }

    var body: some View {
        Text(title)
            .font(.system(size: 22, weight: .bold))
            .tracking(-0.4)
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
    }
}

/// One line of text that scrolls sideways when it doesn't fit, pausing at
/// its start, as the Flutter app's marquee does.
struct Marquee: View {
    var text: String
    /// Where the text sits when it fits.
    var alignment: Alignment = .leading
    /// Points per second.
    var speed: Double = 30
    var gap: CGFloat = 40

    @State private var textWidth: CGFloat = 0
    @State private var boxWidth: CGFloat = 0

    var body: some View {
        let overflows = textWidth > boxWidth + 1
        Text(text)
            .lineLimit(1)
            .fixedSize()
            .hidden()
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { textWidth = $0 }
            // Takes the width it's given, however long the text, so it never pushes its neighbours aside
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { boxWidth = $0 }
            .overlay(alignment: overflows ? .leading : alignment) {
                if overflows {
                    TimelineView(.animation(minimumInterval: 1 / 30)) { context in
                        HStack(spacing: gap) {
                            Text(text).fixedSize()
                            Text(text).fixedSize()
                        }
                        .offset(x: offset(at: context.date))
                    }
                    .mask {
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0), .init(color: .black, location: 0.04),
                                .init(color: .black, location: 0.92), .init(color: .clear, location: 1),
                            ], startPoint: .leading, endPoint: .trailing)
                    }
                } else {
                    Text(text).lineLimit(1)
                }
            }
            .clipped()
    }

    private func offset(at date: Date) -> CGFloat {
        let distance = Double(textWidth + gap)
        let pause = 2.0
        let period = distance / speed + pause
        let time = date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: period)
        return time < pause ? 0 : -CGFloat((time - pause) * speed)
    }
}

// MARK: - Controls

/// A slider like the Flutter app's interactive one: a thin capsule that
/// thickens while it's dragged and stretches when pulled past its ends.
/// Dragging moves the value by how far the finger moved, not to where it is.
struct ElasticSlider<Leading: View, Trailing: View>: View {
    /// The value between 0 and 1.
    var value: Double
    var height: CGFloat = 7
    var focusedHeight: CGFloat = 12
    var onChanged: (Double) -> Void = { _ in }
    var onEnded: (Double) -> Void = { _ in }
    @ViewBuilder var leading: Leading
    @ViewBuilder var trailing: Trailing

    @State private var dragged: Double?
    @State private var start = 0.0
    /// Points pulled past an end, negative past the start.
    @State private var stretch: CGFloat = 0

    var body: some View {
        HStack(spacing: 10) {
            leading.scaleEffect(stretch < 0 ? 1.15 : 1)
            GeometryReader { geometry in
                let width = geometry.size.width
                let shown = min(max(dragged ?? value, 0), 1)
                Capsule()
                    .fill(.white.opacity(0.14))
                    .overlay(alignment: .leading) {
                        Rectangle().fill(.tint).frame(width: (width + abs(stretch)) * shown)
                    }
                    .clipShape(.capsule)
                    .frame(width: width + abs(stretch), height: dragged == nil ? height : focusedHeight)
                    .offset(x: min(stretch, 0))
                    .frame(width: width, height: geometry.size.height, alignment: .leading)
                    .contentShape(.rect)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { drag in
                                if dragged == nil { start = value }
                                let raw = start + drag.translation.width / max(width, 1)
                                let clamped = min(max(raw, 0), 1)
                                if (clamped == 0 || clamped == 1), dragged != clamped, dragged != nil {
                                    Haptics.edge()
                                }
                                withAnimation(.interactiveSpring) {
                                    dragged = clamped
                                    stretch = Self.rubberBand((raw - clamped) * width)
                                }
                                onChanged(clamped)
                            }
                            .onEnded { _ in
                                onEnded(dragged ?? value)
                                withAnimation(.spring(duration: 0.4, bounce: 0.35)) {
                                    dragged = nil
                                    stretch = 0
                                }
                            }
                    )
            }
            .frame(height: 28)
            trailing.scaleEffect(stretch > 0 ? 1.15 : 1)
        }
        .animation(.spring(duration: 0.3), value: dragged == nil)
    }

    /// Pulling further moves the capsule less and less.
    private static func rubberBand(_ overshoot: CGFloat) -> CGFloat {
        let limit: CGFloat = 18
        let pulled = limit * (1 - 1 / (abs(overshoot) / limit * 0.55 + 1))
        return overshoot < 0 ? -pulled : pulled
    }
}

extension ElasticSlider where Leading == EmptyView, Trailing == EmptyView {
    init(
        value: Double, height: CGFloat = 7, focusedHeight: CGFloat = 12,
        onChanged: @escaping (Double) -> Void = { _ in }, onEnded: @escaping (Double) -> Void = { _ in }
    ) {
        self.init(
            value: value, height: height, focusedHeight: focusedHeight, onChanged: onChanged, onEnded: onEnded,
            leading: { EmptyView() }, trailing: { EmptyView() })
    }
}

/// A round glass button with an icon, for the player's top bars.
struct GlassIconButton: View {
    var systemImage: String
    var dimmed = false
    /// Lights the button up, for a mode or setting that's on.
    var isOn = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            GlassIcon(systemImage: systemImage, dimmed: dimmed, isOn: isOn)
        }
        .buttonStyle(.press)
    }
}

/// The look of a [GlassIconButton], for menus that need their own label.
struct GlassIcon: View {
    var systemImage: String
    var dimmed = false
    var isOn = false

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(isOn ? .black.opacity(0.8) : .white.opacity(dimmed ? 0.5 : 1))
            .contentTransition(.symbolEffect(.replace))
            .frame(width: 42, height: 42)
            .contentShape(.circle)
            .playerChrome(in: Circle(), isOn: isOn)
            .animation(.snappy, value: isOn)
    }
}

extension View {
    /// The frosted, see-through backing of the player's buttons over lyrics
    /// and the queue: the song's colors show through it blurred. White when
    /// [isOn].
    func playerChrome<S: Shape>(in shape: S, isOn: Bool = false) -> some View {
        background {
            ZStack {
                shape.fill(.ultraThinMaterial)
                if isOn {
                    shape.fill(.tint)
                } else {
                    shape.fill(.white.opacity(0.1))
                }
                shape.stroke(.white.opacity(isOn ? 0 : 0.22), lineWidth: 0.75)
            }
            .environment(\.colorScheme, .dark)
            .shadow(color: .black.opacity(0.15), radius: 10, y: 4)
        }
    }
}

/// The dot that marks the playing track in lists, as in the Flutter app.
struct PlayingDot: View {
    var isPlaying: Bool

    var body: some View {
        Image(systemName: "circle.fill")
            .font(.system(size: 8))
            .symbolEffect(.pulse, options: .repeating, isActive: isPlaying)
            .frame(width: 20)
    }
}

/// What a track row shows at its end: a spinner while the server fetches the
/// track, or the dot while it plays.
struct TrackStatus: View {
    @Environment(AppModel.self) private var model
    var stid: String
    /// Whether this row is the entry playing, beyond having the same track.
    var isCurrent: Bool

    var body: some View {
        let player = model.player
        ZStack {
            if player.fetchingTracks.contains(stid) {
                ProgressView().controlSize(.small)
            } else if isCurrent {
                PlayingDot(isPlaying: player.isPlaying)
            }
        }
        .frame(width: 22)
        .animation(.easeInOut(duration: 0.2), value: isCurrent)
    }
}
