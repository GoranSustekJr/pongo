import PongoCore
import SwiftUI

/// The library tab, grouped as in the Flutter app: what's online, what's on
/// the device, and the sleep alarm.
struct LibraryView: View {
    @Environment(AppModel.self) private var model
    @State private var counts: [Route: Int] = [:]

    var body: some View {
        List {
            Section(L10n.online) {
                row(.favourites, "heart.fill", L10n.favouritesongs, "\(counts[.favourites] ?? 0) \(L10n.plustracks)")
                row(.userPlaylists(.online), "music.note.list", L10n.onlineplaylists,
                    "\(counts[.userPlaylists(.online)] ?? 0) \(L10n.playlists)")
            }
            Section(L10n.offline) {
                row(.downloads, "arrow.down.circle.fill", L10n.offlinesongs, "\(counts[.downloads] ?? 0) \(L10n.plustracks)")
                row(.userPlaylists(.offline), "square.stack.fill", L10n.offlineplaylists,
                    "\(counts[.userPlaylists(.offline)] ?? 0) \(L10n.playlists)")
            }
            Section(L10n.sleep) {
                row(.sleepAlarms, "moon.zzz.fill", L10n.sleep, L10n.sleepandalarmclock)
            }
        }
        .listStyle(.insetGrouped)
        .pongoBackground()
        .navigationTitle(L10n.library)
        .task(id: model.libraryRevision) {
            let database = model.database
            counts = [
                .favourites: (try? await database.favouriteCount()) ?? 0,
                .downloads: (try? await database.downloadCount()) ?? 0,
                .userPlaylists(.online): (try? await database.onlinePlaylistCount()) ?? 0,
                .userPlaylists(.offline): (try? await database.localPlaylistCount()) ?? 0,
            ]
        }
    }

    private func row(_ route: Route, _ image: String, _ title: String, _ subtitle: String) -> some View {
        NavigationLink(value: route) {
            GroupedRow(systemImage: image, title: title, subtitle: subtitle)
        }
        .groupedRowBackground()
    }
}

/// A button that asks before doing something it can't undo.
struct ConfirmButton: View {
    var title: String
    var systemImage: String
    var question: String
    var message: String
    var action: () -> Void

    @State private var asking = false

    var body: some View {
        Button(title, systemImage: systemImage, role: .destructive) { asking = true }
            .confirmationDialog(question, isPresented: $asking, titleVisibility: .visible) {
                Button(title, role: .destructive, action: action)
            } message: {
                Text(message)
            }
    }
}

/// A screen of library tracks without a cover: a large title, the floating
/// play bar that sticks below it, and the tracks.
struct LibraryTracksScreen<Bar: View, Content: View>: View {
    var title: String
    @ViewBuilder var bar: Bar
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                Section {
                    content.padding(.top, 6)
                } header: {
                    bar.padding(.horizontal, 15).padding(.vertical, 8)
                }
            }
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
        .background { AppBackground() }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.large)
    }
}

/// Tracks whose names or artists contain [filter], name matches first.
func filtered(_ tracks: [Track], by filter: String) -> [Track] {
    let query = filter.trimmingCharacters(in: .whitespaces).lowercased()
    guard !query.isEmpty else { return tracks }
    let byName = tracks.filter { $0.name.lowercased().contains(query) }
    let byArtist = tracks.filter { !byName.contains($0) && $0.artistNames.lowercased().contains(query) }
    return byName + byArtist
}

struct FavouritesView: View {
    @Environment(AppModel.self) private var model
    @State private var tracks: [Track] = []
    @State private var availability = TrackAvailability()
    @State private var filter = ""
    @State private var editing = false
    @State private var loaded = false
    private let collectionID = "library.favourites"

    var body: some View {
        let shown = filtered(tracks, by: filter)
        LibraryTracksScreen(title: L10n.favouritesongs) {
            PlayShuffleBar(collectionID: collectionID, canShuffle: !tracks.isEmpty && missing.isEmpty) {
                await play(index: 0)
            } shuffle: {
                await play(shuffle: true)
            }
            .disabled(tracks.isEmpty)
        } content: {
            if loaded && tracks.isEmpty {
                EmptyMessage(systemImage: "heart", title: L10n.findyourfavouritesongsnow).padding(.top, 60)
            } else {
                TrackList(tracks: shown, collectionID: collectionID, missing: Set(missing)) { index in
                    let track = shown[index]
                    guard let position = tracks.firstIndex(of: track) else { return }
                    Task {
                        await model.player.playCollectionTrack(
                            collectionID: collectionID, stid: track.id, index: position
                        ) { await play(index: position) }
                    }
                }
            }
        }
        .searchable(text: $filter)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(L10n.edit) { editing = true }.disabled(tracks.isEmpty)
            }
        }
        .sheet(isPresented: $editing) {
            TrackEditor(title: L10n.favouritesongs, tracks: tracks) { selected, finish in
                ConfirmButton(
                    title: L10n.removefromfavourites, systemImage: "heart.slash", question: L10n.removefromfavourites,
                    message: L10n.removefromfavouritesbody
                ) {
                    Task {
                        try? await model.database.removeFavourites(selected.map(\.id))
                        model.libraryChanged()
                        finish()
                    }
                }
                Spacer()
                Button(L10n.addtoplaylist, systemImage: "music.note.list") {
                    finish()
                    Task { await model.addToPlaylist(selected) }
                }
                Button(L10n.download, systemImage: "icloud.and.arrow.down") {
                    finish()
                    Task { await model.addToPlaylist(selected, kind: .offline) }
                }
            }
        }
        .task(id: model.libraryRevision) { await load() }
    }

    private var durations: [String: Double] {
        availability.durations.merging(model.player.fetchedDurations) { first, _ in first }
    }

    private var missing: [String] { tracks.map(\.id).filter { durations[$0] == nil } }

    private func load() async {
        tracks = ((try? await model.database.favourites()) ?? []).map(\.track)
        loaded = true
        guard !tracks.isEmpty else { return }
        if let found = try? await model.catalog.availability(tracks.map(\.id)) { availability = found }
    }

    private func play(index: Int? = nil, shuffle: Bool = false) async {
        await model.player.playOnline(collectionID, tracks, durations: durations, index: index, shuffle: shuffle)
        if shuffle { model.suggestSongs(for: collectionID, trackCount: tracks.count) }
    }
}

/// The downloaded tracks, sorted as the user likes and filtered by a search.
struct DownloadsView: View {
    @Environment(AppModel.self) private var model
    @State private var downloads: [DownloadedTrack] = []
    @State private var filter = ""
    @State private var editing = false
    @State private var loaded = false
    private let collectionID = "library.locals"

    var body: some View {
        let sorted = sortedTracks
        let shown = filtered(sorted, by: filter)
        LibraryTracksScreen(title: L10n.offlinesongs) {
            PlayShuffleBar(collectionID: collectionID, canShuffle: !sorted.isEmpty) {
                play(sorted, index: 0)
            } shuffle: {
                play(sorted, shuffle: true)
            }
            .disabled(sorted.isEmpty)
        } content: {
            if loaded && downloads.isEmpty {
                EmptyMessage(systemImage: "arrow.down.circle", title: L10n.downloadtracksnow).padding(.top, 60)
            } else {
                TrackList(tracks: shown, collectionID: collectionID, showsAlbum: false) { index in
                    let track = shown[index]
                    guard let position = sorted.firstIndex(of: track) else { return }
                    Task {
                        await model.player.playCollectionTrack(
                            collectionID: collectionID, stid: track.id, index: position
                        ) { play(sorted, index: position) }
                    }
                }
            }
        }
        .searchable(text: $filter)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Picker(selection: model.settings.binding(\.localsSort)) {
                        Text(verbatim: "A-Z").tag(LocalsSort.titleAscending)
                        Text(verbatim: "Z-A").tag(LocalsSort.titleDescending)
                        Text(L10n.firstadded).tag(LocalsSort.firstAdded)
                        Text(L10n.lastadded).tag(LocalsSort.lastAdded)
                    } label: {}
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(L10n.edit) { editing = true }.disabled(downloads.isEmpty)
            }
        }
        .sheet(isPresented: $editing) {
            TrackEditor(title: L10n.offlinesongs, tracks: sorted) { selected, finish in
                ConfirmButton(
                    title: L10n.delete, systemImage: "trash", question: L10n.removefromdownloaded,
                    message: L10n.removefromdownloadedbody
                ) {
                    remove(selected.map(\.id))
                    finish()
                }
                Spacer()
                Button(L10n.addtoplaylist, systemImage: "music.note.list") {
                    finish()
                    Task { await model.addToPlaylist(selected, kind: .offline) }
                }
            }
        }
        .task(id: model.libraryRevision) {
            downloads = (try? await model.database.downloads()) ?? []
            loaded = true
        }
    }

    private var sortedTracks: [Track] {
        let sorted: [DownloadedTrack] =
            switch model.settings.settings.localsSort {
            case .titleAscending: downloads.sorted { $0.track.name.localizedCaseInsensitiveCompare($1.track.name) == .orderedAscending }
            case .titleDescending: downloads.sorted { $0.track.name.localizedCaseInsensitiveCompare($1.track.name) == .orderedDescending }
            case .firstAdded: downloads.sorted { $0.rowID < $1.rowID }
            case .lastAdded: downloads.sorted { $0.rowID > $1.rowID }
            }
        return sorted.map(\.track)
    }

    private func play(_ tracks: [Track], index: Int? = nil, shuffle: Bool = false) {
        let durations = Dictionary(downloads.map { ($0.track.id, $0.durationMilliseconds) }) { first, _ in first }
        model.player.playOffline(collectionID, tracks, durations: durations, index: index, shuffle: shuffle)
    }

    private func remove(_ stids: [String]) {
        if model.player.current?.collectionID == collectionID { model.player.halt() }
        Task {
            try? await model.downloads.remove(stids)
            model.libraryChanged()
        }
    }
}
