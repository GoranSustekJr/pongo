import PongoCore
import SwiftUI

/// The queue filling the player behind its controls, in sections: the
/// tracks played, folded away; those the user queued next (the one playing
/// shows in the controls);
/// the rest of the collection it was started from, which shuffling reorders;
/// and the tracks added after it, such as by a mix. A tap plays an entry, holding one lifts it to reorder,
/// swiping moves it up or removes it, and editing selects entries to remove
/// or download.
struct QueuePanel: View {
    @Environment(AppModel.self) private var model
    /// Space the player's controls take at the bottom.
    var bottomInset: CGFloat

    @State private var editing = false
    @State private var selection: Set<UUID> = []
    @State private var confirmHalt = false
    @State private var showsPlayed = false

    private typealias Entry = (index: Int, item: QueueItem)

    var body: some View {
        let queue = model.player.queue
        let entries: [Entry] = queue.playOrder.map { ($0, queue.items[$0]) }
        let position = queue.position ?? 0
        let played = Array(entries.prefix(position))
        let queued = Array(entries.dropFirst(position + 1).prefix(queue.queuedCount))
        let collection = Array(entries.dropFirst(position + 1 + queued.count).prefix(queue.collectionCount))
        let added = Array(entries.dropFirst(position + 1 + queued.count + collection.count))
        ScrollViewReader { proxy in
            List {
                if model.listening.isActive {
                    VStack(spacing: 6) {
                        ListeningBanner { model.showsListenTogether = true }
                        if model.listening.state == .live { SessionActions() }
                        if model.listening.isHost, !model.listening.suggestions.isEmpty { SuggestionsList() }
                    }
                        .listRowInsets(EdgeInsets(top: 0, leading: 15, bottom: 6, trailing: 15))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .moveDisabled(true)
                }
                if !played.isEmpty {
                    playedToggle(count: played.count)
                    if showsPlayed { rows(played, base: 0, dimmed: true) }
                }
                if !queued.isEmpty {
                    header(L10n.nextinqueue) {
                        EmptyView()
                    } trailing: {
                        Button(L10n.clear) {
                            Haptics.tap()
                            model.player.remove(at: queued.map(\.index))
                        }
                    }
                    rows(queued, base: position + 1, dimmed: false)
                }
                if !collection.isEmpty || (added.isEmpty && model.player.isMixing) {
                    header(L10n.upnext) { QueueSummary(upcoming: queued + collection + added) }
                    rows(collection, base: position + 1 + queued.count, dimmed: false)
                }
                if !added.isEmpty {
                    header(L10n.afterthat) {
                        if collection.isEmpty {
                            QueueSummary(upcoming: queued + added)
                        } else {
                            Text(L10n.afterthatdetail)
                                .font(.system(size: 13))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                    rows(added, base: position + 1 + queued.count + collection.count, dimmed: false)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)
            #if os(iOS)
                .contentMargins(.top, 84, for: .scrollContent)
                // Entries fade out before they reach the buttons on top, so none show behind them
                .mask {
                    VStack(spacing: 0) {
                        Color.clear.frame(height: 62)
                        LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom).frame(height: 16)
                        Color.black
                    }
                }
                // The last entry scrolls up clear of the player's controls
                .contentMargins(.bottom, bottomInset + 70, for: .scrollContent)
            #else
                .contentMargins(.top, 4, for: .scrollContent)
                .contentMargins(.bottom, bottomInset + 20, for: .scrollContent)
            #endif
            .ignoresSafeArea(edges: .bottom)
            .onAppear {
                // Opens at what plays next, with what played folded away above it
                if let next = (queued + collection + added).first {
                    proxy.scrollTo(next.item.id, anchor: UnitPoint(x: 0.5, y: 0.15))
                }
            }

        }
        #if os(iOS)
            .overlay(alignment: .top) { bar }
        #else
            // On a Mac the buttons get a row of their own, which the list starts below
            .safeAreaInset(edge: .top, spacing: 0) { bar.padding(.bottom, 10) }
        #endif
        #if os(iOS)
            .sheet(isPresented: Binding { model.showsListenTogether } set: { model.showsListenTogether = $0 }) {
                ListenTogetherView()
            }
        #endif
        .alert(L10n.haltmusicplayer, isPresented: $confirmHalt) {
            Button(L10n.cancel, role: .cancel) {}
            Button(L10n.halt, role: .destructive) { model.player.halt() }
        } message: {
            Text(L10n.haltmusicplayerbody)
        }
        .animation(.snappy, value: editing)
        .animation(.snappy, value: showsPlayed)
        .animation(.snappy, value: queue.items.map(\.id))
    }

    // MARK: - Sections

    private func header(
        _ title: String, @ViewBuilder subtitle: () -> some View = { EmptyView() },
        @ViewBuilder trailing: () -> some View = { EmptyView() }
    ) -> some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 20, weight: .bold))
                subtitle()
            }
            Spacer()
            trailing()
                .font(.system(size: 15, weight: .semibold))
                .tint(model.nowPlaying.accent)
        }
        .foregroundStyle(.white)
        .padding(.top, 14)
        .listRowInsets(EdgeInsets(top: 0, leading: 15, bottom: 4, trailing: 15))
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .moveDisabled(true)
    }

    private func playedToggle(count: Int) -> some View {
        Button {
            Haptics.select()
            showsPlayed.toggle()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "clock.arrow.circlepath")
                Text("\(L10n.played) · \(count)")
                Spacer()
                Image(systemName: "chevron.down")
                    .rotationEffect(.degrees(showsPlayed ? 180 : 0))
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(.white.opacity(0.75))
            .padding(.horizontal, 14)
            .frame(height: 40)
            .background(.white.opacity(0.1), in: .capsule)
            .contentShape(.capsule)
        }
        .buttonStyle(.press)
        .listRowInsets(EdgeInsets(top: 0, leading: 15, bottom: 4, trailing: 15))
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    /// [entries] of the play order from [base] on, which can be reordered
    /// among themselves.
    private func rows(_ entries: [Entry], base: Int, dimmed: Bool) -> some View {
        ForEach(entries, id: \.item.id) { entry in
            row(entry, dimmed: dimmed)
        }
        .onMove { offsets, destination in
            model.player.move(
                fromOffsets: IndexSet(offsets.map { $0 + base }), toOffset: destination + base)
        }
    }

    private func row(_ entry: Entry, dimmed: Bool) -> some View {
        let player = model.player
        let (index, item) = entry
        let isCurrent = index == player.queue.currentIndex
        return QueueRow(
            item: item, isCurrent: isCurrent, editing: editing, selected: selection.contains(item.id)
        ) {
            tap(item, index: index)
        }
        .opacity(dimmed ? 0.55 : 1)
        .id(item.id)
        .listRowInsets(EdgeInsets(top: 0, leading: 15, bottom: 0, trailing: 12))
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .moveDisabled(isCurrent)
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            if !isCurrent {
                Button(L10n.playnext, systemImage: "text.line.first.and.arrowtriangle.forward") {
                    Haptics.tap()
                    player.playNext(at: index)
                }
                .tint(.indigo)
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if !isCurrent {
                Button(L10n.delete, systemImage: "trash", role: .destructive) {
                    player.remove(at: [index])
                }
            }
        }
        .contextMenu {
            if !isCurrent {
                Button(L10n.playnext, systemImage: "text.line.first.and.arrowtriangle.forward") {
                    player.playNext(at: index)
                }
                Button(L10n.removefromqueue, systemImage: "minus.circle", role: .destructive) {
                    player.remove(at: [index])
                }
                Divider()
            }
            let favourite = model.favouriteIDs.contains(item.stid)
            Button(favourite ? L10n.unlike : L10n.like, systemImage: favourite ? "heart.fill" : "heart") {
                Task { await model.toggleFavourite(item.track) }
            }
            Button(L10n.addtoplaylist, systemImage: "music.note.list") {
                Task { await model.addToPlaylist([item.track]) }
            }
            if let album = item.track.album, !album.id.isEmpty {
                Divider()
                Button(L10n.album, systemImage: "square.stack") {
                    Task { await model.showAlbum(album.id) }
                }
            }
            ForEach(item.track.artists, id: \.id) { artist in
                Button(artist.name ?? L10n.artist, systemImage: "music.microphone") {
                    Task { await model.showArtist(artist) }
                }
            }
        }
    }

    private func tap(_ item: QueueItem, index: Int) {
        let player = model.player
        if editing {
            if !selection.insert(item.id).inserted { selection.remove(item.id) }
        } else if index == player.queue.currentIndex {
            player.togglePlayback()
        } else {
            player.skip(to: index)
        }
    }

    // MARK: - The bar on top

    /// Shuffle on the left, which the player has no other button for, and
    /// on the right listening together and the menu with everything else;
    /// lyrics and closing the queue are in the player's own controls.
    private var bar: some View {
        let player = model.player
        let session = model.listening
        let others = session.listeners.filter { $0.id != session.userID && $0.isPresent }.count
        return HStack(spacing: 10) {
            if editing {
                Button {
                    editing = false
                    selection = []
                } label: {
                    Label(L10n.done, systemImage: "checkmark")
                        .barPill(isOn: true)
                }
                .buttonStyle(.press)
            } else {
                Button {
                    player.setShuffle(!player.queue.shuffleEnabled)
                } label: {
                    Label(L10n.shuffle, systemImage: "shuffle")
                        .barPill(isOn: player.queue.shuffleEnabled)
                }
                .buttonStyle(.press)
                .disabled(!player.canShuffle)
                .opacity(player.canShuffle ? 1 : 0.55)
                let repeatMode = player.queue.repeatMode
                Button {
                    model.cycleRepeat()
                } label: {
                    Image(systemName: repeatMode == .one ? "repeat.1" : "repeat")
                        .contentTransition(.symbolEffect(.replace))
                        .barPill(isOn: repeatMode != .off)
                }
                .buttonStyle(.press)
                .accessibilityLabel(L10n.repeatmode)
                .sensoryFeedback(.selection, trigger: repeatMode)
            }
            Spacer(minLength: 0)
            HStack(spacing: 0) {
                Button {
                    model.showsListenTogether = true
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: session.isActive ? "person.2.wave.2.fill" : "person.2.wave.2")
                        if others > 0 {
                            Text("\(others)").font(.system(size: 14, weight: .bold).monospacedDigit())
                        }
                    }
                    .foregroundStyle(session.isActive ? AnyShapeStyle(.tint) : AnyShapeStyle(.white))
                    .padding(.horizontal, 14)
                    .frame(height: 42)
                    .contentShape(.rect)
                }
                .buttonStyle(.press)
                if !model.handoff.devices.isEmpty {
                    Rectangle().fill(.white.opacity(0.2)).frame(width: 1, height: 20)
                    Menu {
                        TransferMenuItems()
                    } label: {
                        Image(systemName: model.handoff.busyWith == nil ? "laptopcomputer.and.iphone" : "ellipsis")
                            .symbolEffect(.pulse, isActive: model.handoff.busyWith != nil)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .frame(height: 42)
                            .contentShape(.rect)
                    }
                    .menuStyle(.button)
                    .buttonStyle(.tappable)
                    .accessibilityLabel(L10n.transferto)
                }
                Rectangle().fill(.white.opacity(0.2)).frame(width: 1, height: 20)
                Menu {
                    menuItems
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(.white)
                        .padding(.horizontal, 15)
                        .frame(height: 42)
                        .contentShape(.rect)
                }
                .menuStyle(.button)
                .buttonStyle(.tappable)
            }
            .font(.system(size: 16, weight: .semibold))
            .playerChrome(in: Capsule())
        }
        .padding(.horizontal, 15)
        .padding(.top, 12)
        .tint(model.nowPlaying.accent)
        .sensoryFeedback(.selection, trigger: player.queue.shuffleEnabled)
        .animation(.snappy, value: editing)
        .animation(.snappy, value: session.isActive)
    }

    @ViewBuilder private var menuItems: some View {
        if editing {
            Button(L10n.cancel, systemImage: "xmark") {
                editing = false
                selection = []
            }
            Button(L10n.clear, systemImage: "trash", role: .destructive) { removeSelected() }
                .disabled(selection.isEmpty)
            Button(L10n.download, systemImage: "icloud.and.arrow.down") { download(selectedOnly: true) }
        } else {
            Button(L10n.edit, systemImage: "pencil") { editing = true }
            Divider()
            Button(L10n.saveasplaylist, systemImage: "music.note.list") {
                Task { await model.addToPlaylist(queueTracks(), creating: true) }
            }
            Button(L10n.download, systemImage: "icloud.and.arrow.down") { download(selectedOnly: false) }
            Divider()
            Button(L10n.clearupcoming, systemImage: "text.badge.xmark", role: .destructive) {
                Haptics.tap()
                model.player.clearUpcoming()
            }
            .disabled(model.player.queue.upcoming.isEmpty)
            Button(L10n.halt, systemImage: "stop.fill") { confirmHalt = true }
        }
    }

    /// The queue's tracks in play order, each once.
    private func queueTracks(_ ids: Set<UUID>? = nil) -> [Track] {
        let queue = model.player.queue
        var seen: Set<String> = []
        return queue.playOrder.map { queue.items[$0] }
            .filter { ids?.contains($0.id) ?? true }
            .map(\.track)
            .filter { seen.insert($0.id).inserted }
    }

    private func removeSelected() {
        let indexes = model.player.queue.items.indices.filter { selection.contains(model.player.queue.items[$0].id) }
        model.player.remove(at: indexes)
        editing = false
        selection = []
    }

    /// Downloads the selected tracks, or all when none are selected, into an
    /// offline playlist.
    private func download(selectedOnly: Bool) {
        let tracks = queueTracks(selectedOnly && !selection.isEmpty ? selection : nil)
        editing = false
        selection = []
        Task { await model.addToPlaylist(tracks, kind: .offline) }
    }
}

/// An entry of the queue: a big cover, title and artists, and the playing dot
/// with a handle, or a checkmark while editing.
private struct QueueRow: View {
    @Environment(AppModel.self) private var model
    let item: QueueItem
    let isCurrent: Bool
    let editing: Bool
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12.5) {
                CoverImage(url: item.track.coverURL(size: 150))
                    .frame(width: 65, height: 65)
                    .coverShape(7.5)
                VStack(alignment: .leading, spacing: 2.5) {
                    Text(item.track.name)
                        .font(.system(size: 18.5, weight: .semibold))
                    Text(item.track.artistNames)
                        .font(.system(size: 14))
                        .opacity(0.78)
                }
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                if model.player.suggestedIDs.contains(item.id), !editing {
                    // A suggestion of smart shuffle, which a tap keeps in the playlist
                    Button {
                        Task { await model.keepSuggestion(item) }
                    } label: {
                        Label(L10n.addtoplaylist, systemImage: "plus.circle")
                            .labelStyle(.iconOnly)
                            .font(.system(size: 22))
                            .frame(width: 40, height: 40)
                            .contentShape(.rect)
                    }
                    .buttonStyle(.press)
                    .overlay(alignment: .topTrailing) {
                        Image(systemName: "sparkles").font(.system(size: 10)).offset(x: 2, y: 4)
                    }
                } else if item.isMix {
                    Image(systemName: "sparkles").font(.caption).opacity(0.6)
                }
                if let adder = model.listening.listener(item.addedBy), !editing {
                    // Who added it, while listening together
                    ListenerAvatar(listener: adder, size: 22)
                        .help("\(L10n.addedby) \(adder.name)")
                        .accessibilityLabel("\(L10n.addedby) \(adder.name)")
                }
                if editing {
                    Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 25))
                        .contentTransition(.symbolEffect(.replace))
                        .frame(width: 47, height: 47)
                } else {
                    // Holding a row lifts it to reorder, so it needs no handle
                    TrackStatus(stid: item.stid, isCurrent: isCurrent)
                }
            }
            .foregroundStyle(.white)
            .frame(height: 85)
            .padding(.horizontal, isCurrent ? 8 : 0)
            .background {
                if isCurrent {
                    RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.white.opacity(0.12))
                }
            }
            .contentShape(.rect)
        }
        .buttonStyle(.tappable)
    }
}

/// How many tracks are still to come, how long they take and when they end,
/// kept apart so only it follows the playback position.
private struct QueueSummary: View {
    @Environment(AppModel.self) private var model
    let upcoming: [(index: Int, item: QueueItem)]

    var body: some View {
        let player = model.player
        let left = max(player.duration - player.progress.position, 0) + upcoming.reduce(0) { $0 + $1.item.duration }
        // To the minute, so it doesn't change with every tick
        let minutes = (left / 60).rounded(.up)
        let locale = Locale(identifier: L10n.selectedLanguage)
        let length = Duration.seconds(minutes * 60).formatted(
            .units(allowed: [.hours, .minutes], width: .abbreviated).locale(locale))
        let end = Date.now.addingTimeInterval(minutes * 60).formatted(
            Date.FormatStyle(date: .omitted, time: .shortened).locale(locale))
        VStack(alignment: .leading, spacing: 3) {
            Text("\(upcoming.count) \(L10n.plustracks) · \(length) · \(L10n.endsat) \(end)")
            if player.isMixing {
                Label(L10n.mixkeepsgoing, systemImage: "sparkles")
            }
        }
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(.white.opacity(0.65))
    }
}

extension View {
    /// A label as a frosted pill in the queue's bar, lit when [isOn].
    fileprivate func barPill(isOn: Bool) -> some View {
        font(.system(size: 15, weight: .semibold))
            .foregroundStyle(isOn ? .black.opacity(0.8) : .white)
            .padding(.horizontal, 16)
            .frame(height: 42)
            .contentShape(.capsule)
            .playerChrome(in: Capsule(), isOn: isOn)
            .animation(.snappy, value: isOn)
    }
}

extension AppModel {
    /// Off, then the track, then the whole queue, as in the Flutter app;
    /// a running sleep alarm keeps it as it is.
    func cycleRepeat() {
        guard player.activeSleepAlarm == -1 else {
            messages.show(L10n.sleepalarmisenabled, systemImage: "alarm", isError: true)
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
