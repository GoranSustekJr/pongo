import PongoCore
import SwiftUI

/// Lyrics to make a card of: the track's lines and the one held.
struct LyricCardRequest: Identifiable {
    let id = UUID()
    let item: QueueItem
    let lines: [String]
    let held: Int
    /// Translations of the lines, shown under them on the card.
    var translations: [String: String] = [:]
}

/// Makes an image of a few lyrics lines over the song's colors, with its
/// cover, title and artist, to share or save.
struct LyricCardSheet: View {
    @Environment(AppModel.self) private var model
    let request: LyricCardRequest

    @State private var selected: Set<Int> = []
    @State private var cover: PlatformImage?
    @State private var backdrop: PlatformImage?
    @State private var rendered: PlatformImage?

    /// More lines than this don't fit a card.
    private let maxLines = 6

    var body: some View {
        VStack(spacing: 18) {
            #if os(macOS)
                // A Mac sheet has no grabber to swipe it away
                HStack {
                    Spacer()
                    Button(L10n.done) { model.nowPlaying.lyricCard = nil }
                        .keyboardShortcut(.cancelAction)
                }
                .padding([.top, .horizontal], 14)
            #else
                Capsule().fill(.white.opacity(0.35)).frame(width: 38, height: 5).padding(.top, 8)
            #endif
            LyricCardView(
                lines: chosenLines, translations: request.translations, title: request.item.track.name, artist: request.item.track.artistNames,
                cover: cover, backdrop: backdrop, accent: model.nowPlaying.accent
            )
            .clipShape(.rect(cornerRadius: 22, style: .continuous))
            .shadow(color: .black.opacity(0.35), radius: 20, y: 10)
            .scaleEffect(0.82)
            .frame(width: LyricCardView.size.width * 0.82, height: LyricCardView.size.height * 0.82)
            .animation(.spring(duration: 0.35), value: selected)
            share
            Text(L10n.picklines)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.6))
            linePicker
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .background { ArtworkBackground(url: request.item.track.coverURL(size: 300), dim: 0.45) }
        .preferredColorScheme(.dark)
        .presentationDragIndicator(.hidden)
        .onAppear { selected = [request.held] }
        .task {
            guard let url = request.item.track.coverURL(size: 300) else { return }
            async let image = ImagePipeline.shared.image(for: url)
            async let blurred = ImagePipeline.shared.blurred(for: url)
            (cover, backdrop) = await (image, blurred)
        }
        .onChange(of: "\(selected.sorted())|\(cover != nil)|\(backdrop != nil)", initial: true) { render() }
    }

    private var chosenLines: [String] { selected.sorted().map { request.lines[$0] } }

    @ViewBuilder
    private var share: some View {
        if let rendered {
            let image = Image(platformImage: rendered)
            ShareLink(item: image, preview: SharePreview(request.item.track.name, image: image)) {
                Label(L10n.sharelyrics, systemImage: "square.and.arrow.up")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 22)
                    .frame(height: 46)
                    .background(model.nowPlaying.accent, in: .capsule)
            }
            .buttonStyle(.press)
            .simultaneousGesture(TapGesture().onEnded { Haptics.tap() })
        } else {
            ProgressView().tint(.white).frame(height: 46)
        }
    }

    private var linePicker: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(request.lines.enumerated()), id: \.offset) { index, line in
                        let isOn = selected.contains(index)
                        Button {
                            toggle(index)
                        } label: {
                            Text(line)
                                .font(.system(size: 19, weight: .bold))
                                .multilineTextAlignment(.leading)
                                .foregroundStyle(.white.opacity(isOn ? 1 : 0.45))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 9)
                                .background(.white.opacity(isOn ? 0.14 : 0), in: .rect(cornerRadius: 12))
                        }
                        .buttonStyle(.tappable)
                        .id(index)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .mask {
                LinearGradient(stops: [.init(color: .clear, location: 0), .init(color: .black, location: 0.06)],
                               startPoint: .top, endPoint: .bottom)
            }
            .onAppear { proxy.scrollTo(request.held, anchor: .center) }
        }
    }

    private func toggle(_ index: Int) {
        if selected.contains(index) {
            // A card always keeps a line
            guard selected.count > 1 else { return }
            selected.remove(index)
        } else {
            guard selected.count < maxLines else {
                Haptics.error()
                return
            }
            selected.insert(index)
        }
        Haptics.select()
    }

    private func render() {
        let renderer = ImageRenderer(
            content: LyricCardView(
                lines: chosenLines, translations: request.translations, title: request.item.track.name, artist: request.item.track.artistNames,
                cover: cover, backdrop: backdrop, accent: model.nowPlaying.accent))
        renderer.scale = 3
        rendered = renderer.platformImage
    }
}

/// The card itself, at the size it's shared in points: 1080 × 1350 pixels.
struct LyricCardView: View {
    static let size = CGSize(width: 360, height: 450)

    let lines: [String]
    var translations: [String: String] = [:]
    let title: String
    let artist: String
    let cover: PlatformImage?
    let backdrop: PlatformImage?
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(systemName: "quote.opening")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(accent)
            Spacer(minLength: 14)
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(line)
                        if let translation = translations[line] {
                            Text(translation)
                                .font(.system(size: lines.count <= 2 ? 18 : 15, weight: .semibold))
                                .opacity(0.65)
                        }
                    }
                }
            }
            .font(.system(size: lines.count <= 2 ? 30 : 24, weight: .heavy))
            .lineSpacing(1)
            .minimumScaleFactor(0.5)
            .shadow(color: accent.opacity(0.45), radius: 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            Spacer(minLength: 14)
            HStack(spacing: 11) {
                Group {
                    if let cover {
                        Image(platformImage: cover).resizable().scaledToFill()
                    } else {
                        Image(systemName: "music.note").foregroundStyle(.white.opacity(0.7))
                    }
                }
                .frame(width: 44, height: 44)
                .background(.white.opacity(0.12))
                .clipShape(.rect(cornerRadius: 8, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.system(size: 15, weight: .semibold)).lineLimit(1)
                    Text(artist).font(.system(size: 13)).opacity(0.7).lineLimit(1)
                }
                Spacer(minLength: 8)
                Text("Pongo")
                    .font(.system(size: 13, weight: .heavy))
                    .opacity(0.55)
            }
        }
        .foregroundStyle(.white)
        .padding(28)
        .frame(width: Self.size.width, height: Self.size.height)
        .background {
            ZStack {
                Color(white: 0.12)
                if let backdrop {
                    Image(platformImage: backdrop).resizable().scaledToFill().scaleEffect(1.3)
                }
                LinearGradient(
                    colors: [.black.opacity(0.15), .black.opacity(0.5)], startPoint: .top, endPoint: .bottom)
            }
        }
        .clipped()
        .environment(\.colorScheme, .dark)
    }
}
