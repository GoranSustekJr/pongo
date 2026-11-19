import AppKit
import PongoCore
import SwiftUI

/// The Controls and View menu items, with the shortcuts Mac music apps use.
struct PlayerCommands: Commands {
    let model: AppModel

    var body: some Commands {
        let player = model.player
        let router = model.router
        let hasTrack = player.current != nil
        CommandMenu(L10n.controls) {
            Button(player.isPlaying ? L10n.pause : L10n.play, action: player.togglePlayback)
                .disabled(!hasTrack)
            Button(L10n.next, action: player.skipToNext)
                .keyboardShortcut(.rightArrow, modifiers: .command)
                .disabled(!hasTrack)
            Button(L10n.previous, action: player.skipToPrevious)
                .keyboardShortcut(.leftArrow, modifiers: .command)
                .disabled(!hasTrack)
            Divider()
            Button(L10n.volumeup) { player.setVolume(min(player.volume + 0.1, 1)) }
                .keyboardShortcut(.upArrow, modifiers: .command)
            Button(L10n.volumedown) { player.setVolume(max(player.volume - 0.1, 0)) }
                .keyboardShortcut(.downArrow, modifiers: .command)
            Divider()
            Toggle(L10n.shuffle, isOn: Binding(get: { player.queue.shuffleEnabled }, set: player.setShuffle))
                .disabled(!player.canShuffle)
            Picker(L10n.repeatmode, selection: Binding(get: { player.queue.repeatMode }) { player.setRepeatMode($0) }) {
                Text(L10n.repeatoff).tag(RepeatMode.off)
                Text(L10n.repeatthequeue).tag(RepeatMode.all)
                Text(L10n.repeatthissong).tag(RepeatMode.one)
            }
            Divider()
            Button(L10n.listentogether + "…") { model.showsListenTogether = true }
                .keyboardShortcut("l", modifiers: [.command, .option])
            Divider()
            Button(L10n.halt) { router.confirmsHalt = true }
                .disabled(!hasTrack)
        }
        CommandGroup(before: .sidebar) {
            Button(router.showsPlayer ? L10n.closeplayer : L10n.openplayer) { router.showsPlayer.toggle() }
                .keyboardShortcut("f", modifiers: [.command, .shift])
                .disabled(!hasTrack)
            Button(L10n.lyrics) { router.toggleInspector(.lyrics) }
                .keyboardShortcut("l", modifiers: .command)
            Button(L10n.queue) { router.toggleInspector(.queue) }
                .keyboardShortcut("u", modifiers: [.command, .option])
            Divider()
        }
        CommandGroup(after: .textEditing) {
            Button(L10n.search) { router.search(for: "") }
                .keyboardShortcut("f", modifiers: .command)
        }
    }
}

extension Router {
    /// Opens the side panel on [pane], or closes it if it shows that already.
    func toggleInspector(_ pane: InspectorPane) {
        inspector = inspector == pane ? nil : pane
    }
}

/// Plays and pauses with the space bar, as Mac music apps do, unless the
/// user is typing.
@MainActor
final class SpaceBarMonitor {
    private var monitor: Any?

    func start(_ player: Player) {
        guard monitor == nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak player] event in
            guard event.keyCode == 49, event.modifierFlags.intersection(.deviceIndependentFlagsMask).isEmpty,
                !(event.window?.firstResponder is NSText), event.window?.attachedSheet == nil,
                let player, player.current != nil
            else { return event }
            player.togglePlayback()
            return nil
        }
    }
}
