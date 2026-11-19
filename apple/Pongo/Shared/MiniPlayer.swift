import PongoCore
import SwiftUI

/// The current track above the tab bar, like the Flutter app's: a tap or a
/// swipe up opens the player, swiping sideways skips and snaps back, and
/// holding it halts the player.
struct MiniPlayer: View {
    @Environment(AppModel.self) private var model
    @Environment(\.tabViewBottomAccessoryPlacement) private var placement
    @Environment(\.colorScheme) private var colorScheme

    /// How far the track info follows a sideways swipe.
    @State private var offset: CGFloat = 0
    @State private var skips = 0

    var body: some View {
        let player = model.player
        let backdrop = model.nowPlaying.backdrop
        if let item = player.current {
            let inline = placement == .inline
            HStack(spacing: 10) {
                CoverImage(url: item.track.coverURL(size: 150))
                    .frame(width: inline ? 28 : 38, height: inline ? 28 : 38)
                    .coverShape(inline ? 6 : 8)
                    .fixedSize()
                    .scaleEffect(player.isPlaying ? 1 : 0.9)
                    .animation(.spring(response: 0.45, dampingFraction: 0.55), value: player.isPlaying)
                VStack(alignment: .leading, spacing: 0) {
                    Marquee(text: item.track.name)
                        .font(.system(size: inline ? 14 : 15, weight: .medium))
                    if !inline {
                        Marquee(text: item.track.artistNames)
                            .font(.system(size: 13, weight: .light))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                .offset(x: offset)
                .opacity(1 - min(abs(offset) / 140, 0.6))
                .clipped()
                .id(item.id)
                .transition(.push(from: skips >= 0 ? .trailing : .leading).combined(with: .opacity))
                Button(action: player.togglePlayback) {
                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: inline ? 17 : 20))
                        .contentTransition(.symbolEffect(.replace))
                        .frame(width: 40, height: 40)
                        .contentShape(.rect)
                }
                .buttonStyle(.press)
            }
            .padding(.leading, inline ? 6 : 8)
            .padding(.trailing, 6)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background { background(backdrop) }
            .environment(\.colorScheme, backdrop == nil ? colorScheme : .dark)
            .contentShape(.rect)
            .task(id: "\(item.track.id)|\(model.settings.settings.useBlur)") {
                let url = model.settings.settings.useBlur ? item.track.coverURL(size: 300) : nil
                await model.nowPlaying.loadBackdrop(url)
            }
            .animation(.smooth(duration: 0.35), value: item.id)
            .onTapGesture { model.router.showsPlayer = true }
            .onLongPressGesture(minimumDuration: 0.5) { model.router.confirmsHalt = true }
            .simultaneousGesture(swipe)
            .sensoryFeedback(.impact(weight: .light), trigger: skips)
            .sensoryFeedback(.warning, trigger: model.router.confirmsHalt) { _, asks in asks }
        }
    }

    /// The song's colors filling the accessory's glass. They spill past its
    /// edges and the accessory's own shape cuts them, so they keep its shape
    /// while the tab bar grows and shrinks.
    @ViewBuilder private func background(_ backdrop: UIImage?) -> some View {
        if let backdrop {
            Image(uiImage: backdrop).resizable().scaledToFill()
                .overlay { Color.black.opacity(0.18) }
                .opacity(0.9)
                .padding(-30)
                .allowsHitTesting(false)
                .transition(.opacity)
                .id(backdrop)
        }
    }

    private var swipe: some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { drag in
                guard abs(drag.translation.width) > abs(drag.translation.height) else { return }
                offset = drag.translation.width * 0.6
            }
            .onEnded { drag in
                let width = drag.translation.width
                let height = drag.translation.height
                if abs(height) > abs(width) {
                    if height < -20 { model.router.showsPlayer = true }
                } else if width < -50 {
                    skips += 1
                    model.player.skipToNext()
                } else if width > 50 {
                    skips -= 1
                    model.player.skipToPrevious()
                }
                withAnimation(.spring(duration: 0.4, bounce: 0.3)) { offset = 0 }
            }
    }
}
