import AppKit
import PongoCore
import SwiftUI

/// The menu bar: Controls for the music and the song playing, Go for the
/// sidebar's sections, and the View and File items, with shortcuts so the
/// whole app works from the keyboard.
///
/// Space plays and pauses and Escape closes the full player (see
/// [PlayerKeyMonitor]); in a song list the arrow keys pick a song and Return
/// plays it (see TrackList).
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
            Button(L10n.seekforward) { seek(by: 10) }
                .keyboardShortcut(.rightArrow, modifiers: [.command, .option])
                .disabled(!hasTrack)
            Button(L10n.seekback) { seek(by: -10) }
                .keyboardShortcut(.leftArrow, modifiers: [.command, .option])
                .disabled(!hasTrack)
            Divider()
            Button(L10n.volumeup) { player.setVolume(min(player.volume + 0.1, 1)) }
                .keyboardShortcut(.upArrow, modifiers: .command)
            Button(L10n.volumedown) { player.setVolume(max(player.volume - 0.1, 0)) }
                .keyboardShortcut(.downArrow, modifiers: .command)
            Button(player.volume > 0 ? L10n.mute : L10n.unmute, action: toggleMute)
                .keyboardShortcut(.downArrow, modifiers: [.command, .option])
            Divider()
            Toggle(L10n.shuffle, isOn: Binding(get: { player.queue.shuffleEnabled }, set: player.setShuffle))
                .keyboardShortcut("s", modifiers: [.command, .option])
                .disabled(!player.canShuffle)
            // Says what repeats now; each press goes on to the next mode
            let repeatTitle =
                switch player.queue.repeatMode {
                case .off: L10n.repeatoff
                case .all: L10n.repeatthequeue
                case .one: L10n.repeatthissong
                }
            Button(repeatTitle) { model.cycleRepeat() }
                .keyboardShortcut("r", modifiers: [.command, .option])
                .disabled(!hasTrack)
            Divider()
            currentSong
            Divider()
            Button(L10n.listentogether + "…") { model.showsListenTogether = true }
                .keyboardShortcut("l", modifiers: [.command, .option])
            if !model.handoff.devices.isEmpty {
                Menu(L10n.transferto) {
                    ForEach(Array(model.handoff.devices.enumerated()), id: \.element.id) { index, device in
                        Button(device.name) { model.handoff.transfer(to: device) }
                            .keyboardShortcut(index < 9 ? KeyEquivalent(Character("\(index + 1)")) : "0", modifiers: [.control, .command])
                            .disabled(!model.handoff.canTransfer)
                    }
                }
                Menu(L10n.getqueuefrom) {
                    ForEach(model.handoff.devices) { device in
                        Button(device.name) { model.handoff.requestQueue(from: device) }
                            .disabled(model.handoff.busyWith != nil)
                    }
                }
            }
            Divider()
            Button(L10n.halt) { router.confirmsHalt = true }
                .keyboardShortcut(".", modifiers: .command)
                .disabled(!hasTrack)
        }
        CommandMenu(L10n.go) {
            section(L10n.home, .home, "1")
            section(L10n.playlists, .allPlaylists, "2")
            section(L10n.favouritesongs, .favourites, "3")
            section(L10n.downloads, .downloads, "4")
            section(L10n.sleep, .sleepAlarms, "5")
            section(L10n.stats, .stats, "6")
            section(L10n.friends, .friends, "7")
            Divider()
            Button(L10n.search) { router.focusSearch() }
                .keyboardShortcut("f", modifiers: .command)
            Button(L10n.back) {
                if router.showsPlayer { router.showsPlayer = false } else { router.path.removeLast() }
            }
            .keyboardShortcut("[", modifiers: .command)
            .disabled(!router.showsPlayer && router.path.isEmpty)
        }
        CommandGroup(before: .sidebar) {
            Button(router.showsPlayer ? L10n.closeplayer : L10n.openplayer) { router.showsPlayer.toggle() }
                .keyboardShortcut("f", modifiers: [.command, .shift])
                .disabled(!hasTrack)
            // In the full player they switch its own panel, elsewhere the side panel
            Button(L10n.lyrics) {
                if router.showsPlayer { model.togglePlayerLyrics() } else { router.toggleInspector(.lyrics) }
            }
            .keyboardShortcut("l", modifiers: .command)
            Button(L10n.queue) {
                if router.showsPlayer { model.togglePlayerQueue() } else { router.toggleInspector(.queue) }
            }
            .keyboardShortcut("u", modifiers: [.command, .option])
            Divider()
        }
        CommandGroup(replacing: .newItem) {
            Button(L10n.newplaylist + "…") { router.newPlaylist = .online }
                .keyboardShortcut("n", modifiers: .command)
            Button(L10n.newplaylistlocal + "…") { router.newPlaylist = .offline }
                .keyboardShortcut("n", modifiers: [.command, .option])
            Button(L10n.importplaylists + "…") {
                router.showsPlayer = false
                router.section = .allPlaylists
                // After the section change, which empties the path
                Task { @MainActor in router.path = [.importPlaylists] }
            }
            .keyboardShortcut("i", modifiers: [.command, .shift])
        }
    }

    /// What can be done with the song playing.
    @ViewBuilder private var currentSong: some View {
        let track = model.player.current?.track
        Section(L10n.currentsong) {
            let favourite = track.map { model.favouriteIDs.contains($0.id) } ?? false
            Button(favourite ? L10n.unlike : L10n.like) {
                if let track { Task { await model.toggleFavourite(track) } }
            }
            .keyboardShortcut("k", modifiers: .command)
            .disabled(track == nil || track?.isDownloaded == true)
            Button(L10n.download) {
                if let track { Task { await model.download(track) } }
            }
            .keyboardShortcut("d", modifiers: [.command, .option])
            .disabled(track == nil || track?.isDownloaded == true || track.map { model.downloadedIDs.contains($0.id) } == true)
            Button(L10n.addtoplaylist + "…") {
                if let track { Task { await model.addToPlaylist([track], kind: track.isDownloaded ? .offline : .online) } }
            }
            .keyboardShortcut("p", modifiers: [.command, .option])
            .disabled(track == nil)
            Button(L10n.showalbum) {
                if let id = track?.album?.id, !id.isEmpty { Task { await model.showAlbum(id) } }
            }
            .keyboardShortcut("j", modifiers: .command)
            .disabled(track?.album?.id.isEmpty ?? true)
            Button(L10n.showartist) {
                if let artist = track?.artists.first { Task { await model.showArtist(artist) } }
            }
            .keyboardShortcut("j", modifiers: [.command, .option])
            .disabled(track?.artists.isEmpty ?? true)
            Button(L10n.wrongversion) { model.versionRequest = track }
                .disabled(!(track?.id.allSatisfy(\.isNumber) ?? false))
        }
    }

    private func section(_ title: String, _ section: SidebarSection, _ key: KeyEquivalent) -> some View {
        Button(title) {
            model.router.showsPlayer = false
            model.router.section = section
            model.router.path = []
        }
        .keyboardShortcut(key, modifiers: .command)
    }

    private func seek(by seconds: Double) {
        let player = model.player
        let length = player.current?.duration ?? 0
        let target = max(player.exactPosition + seconds, 0)
        player.seek(to: length > 0 ? min(target, length - 1) : target)
    }

    private func toggleMute() {
        let player = model.player
        if player.volume > 0 {
            MuteMemory.volume = player.volume
            player.setVolume(0)
        } else {
            player.setVolume(MuteMemory.volume)
        }
    }
}

/// The volume before muting from the menu, to go back to.
@MainActor private enum MuteMemory {
    static var volume = 0.5
}

extension AppModel {
    /// Shows the lyrics beside the full player in place of the queue, or
    /// hides them if they show.
    func togglePlayerLyrics() {
        let state = nowPlaying
        if state.mode == .lyrics {
            state.lyricsOn = false
        } else {
            state.showsQueue = false
            state.lyricsOn = false
            state.toggleLyrics(self)
        }
    }

    /// Shows the queue beside the full player in place of the lyrics, or
    /// hides it if it shows.
    func togglePlayerQueue() {
        let state = nowPlaying
        if state.mode == .queue {
            state.showsQueue = false
        } else {
            state.lyricsOn = false
            state.showsQueue = true
        }
    }
}

extension Router {
    /// Opens the side panel on [pane], or closes it if it shows that already.
    func toggleInspector(_ pane: InspectorPane) {
        inspector = inspector == pane ? nil : pane
    }

    /// Puts the cursor in the search field at the top of the sidebar.
    func focusSearch() {
        showsPlayer = false
        searchFocusRequests += 1
    }
}

/// Plays and pauses with the space bar, as Mac music apps do, unless the
/// user is typing, and closes the full player with Escape, wherever the
/// keyboard focus is.
@MainActor
final class PlayerKeyMonitor {
    private var monitor: Any?

    func start(_ model: AppModel) {
        guard monitor == nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak model] event in
            guard let model, event.modifierFlags.intersection(.deviceIndependentFlagsMask).isEmpty,
                event.window?.attachedSheet == nil
            else { return event }
            switch event.keyCode {
            case 49 where !(event.window?.firstResponder is NSText) && model.player.current != nil:
                model.player.togglePlayback()
                return nil
            case 53 where model.router.showsPlayer:
                model.router.showsPlayer = false
                return nil
            default:
                return event
            }
        }
    }
}
