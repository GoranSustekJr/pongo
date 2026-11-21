import PhotosUI
import PongoCore
import SwiftUI

extension AppModel {
    func playlists(_ kind: PlaylistKind) async -> [UserPlaylist] {
        (try? await kind == .online ? database.onlinePlaylists() : database.localPlaylists()) ?? []
    }

    func trackCount(_ kind: PlaylistKind, _ id: Int) async -> Int {
        (try? await kind == .online ? database.onlineTrackCount(id) : database.localTrackCount(id)) ?? 0
    }

    /// Creates a playlist, unless one with [title] exists, and returns its ID.
    func createPlaylist(_ kind: PlaylistKind, title: String, cover: Data?) async -> Int? {
        let title = title.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else { return nil }
        guard !(await playlists(kind)).contains(where: { $0.title == title }) else {
            messages.show(L10n.playlistnamealreadyexists, systemImage: "exclamationmark.triangle", isError: true)
            return nil
        }
        let id =
            kind == .online
            ? try? await database.createOnlinePlaylist(title, cover: cover)
            : try? await database.createLocalPlaylist(title, cover: cover)
        libraryChanged()
        return id
    }
}

/// The user's online or offline playlists.
struct UserPlaylistsView: View {
    @Environment(AppModel.self) private var model
    let kind: PlaylistKind
    @State private var playlists: [UserPlaylist] = []
    @State private var counts: [Int: Int] = [:]
    @State private var loaded = false
    @State private var creating = false
    @State private var deleting: UserPlaylist?

    var body: some View {
        List {
            ForEach(playlists) { playlist in
                NavigationLink(value: Route.userPlaylist(kind, playlist)) {
                    HStack(spacing: 14) {
                        CoverImage(data: playlist.cover).frame(width: 60, height: 60).coverShape(10)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(playlist.title).font(.system(size: 17, weight: .semibold)).lineLimit(1)
                            Text("\(counts[playlist.id] ?? 0) \(L10n.plustracks)")
                                .font(.system(size: 13)).foregroundStyle(.secondary)
                        }
                    }
                }
                .groupedRowBackground()
                .swipeActions {
                    Button(L10n.delete, systemImage: "trash", role: .destructive) { deleting = playlist }
                }
            }
        }
        .listStyle(.insetGrouped)
        .pongoBackground()
        .overlay {
            if loaded && playlists.isEmpty {
                VStack(spacing: 16) {
                    EmptyMessage(systemImage: "music.note.list", title: L10n.createnewplaylistnow)
                    Button(L10n.newplaylist, systemImage: "plus") { creating = true }.buttonStyle(.glassProminent)
                            .tint(.pongoTeal)
                }
            }
        }
        .navigationTitle(kind == .online ? L10n.onlineplaylists : L10n.offlineplaylists)
        .toolbar {
            Button(L10n.newplaylist, systemImage: "plus") { creating = true }
        }
        .sheet(isPresented: $creating) {
            NavigationStack {
                PlaylistCreateForm(kind: kind, initialCover: nil) { _ in creating = false }
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) { Button(L10n.cancel) { creating = false } }
                    }
            }
            .presentationDetents([.medium, .large])
        }
        .confirmationDialog(
            L10n.removeplaylist, isPresented: Binding { deleting != nil } set: { if !$0 { deleting = nil } },
            titleVisibility: .visible, presenting: deleting
        ) { playlist in
            Button(L10n.delete, role: .destructive) { Task { await delete(playlist) } }
        }
        .task(id: model.libraryRevision) {
            playlists = await model.playlists(kind)
            for playlist in playlists { counts[playlist.id] = await model.trackCount(kind, playlist.id) }
            loaded = true
        }
    }

    private func delete(_ playlist: UserPlaylist) async {
        if kind == .online {
            try? await model.database.deleteOnlinePlaylist(playlist.id)
        } else {
            try? await model.database.deleteLocalPlaylist(playlist.id)
        }
        model.libraryChanged()
    }
}

/// One of the user's playlists: plays its shown tracks, and edits its title,
/// cover, order and which tracks are hidden.
struct UserPlaylistView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let kind: PlaylistKind
    @State var playlist: UserPlaylist
    @State private var tracks: [Track] = []
    @State private var hidden: [String: Bool] = [:]
    @State private var offlineDurations: [String: Int] = [:]
    @State private var availability = TrackAvailability()
    @State private var loaded = false
    @State private var editing = false
    @State private var renaming = false
    @State private var newTitle = ""
    @State private var pickingCover = false
    @State private var pickedCover: PhotosPickerItem?
    @State private var confirmDelete = false
    @State private var removing: Track?

    init(kind: PlaylistKind, playlist: UserPlaylist) {
        self.kind = kind
        _playlist = State(initialValue: playlist)
    }

    private var collectionID: String {
        kind == .online ? "online.playlist:\(playlist.id)" : "local.playlist:\(playlist.id)"
    }

    private var shown: [Track] { tracks.filter { hidden[$0.id] != true } }

    var body: some View {
        CollectionScreen(
            title: playlist.title, subtitle: "\(shown.count) \(L10n.plustracks)", coverData: playlist.cover
        ) {
            PlayShuffleBar(collectionID: collectionID, canShuffle: !shown.isEmpty && missing.isEmpty) {
                await play(index: 0)
            } shuffle: {
                await play(shuffle: true)
            }
            .disabled(shown.isEmpty)
        } content: {
            if loaded && tracks.isEmpty {
                EmptyMessage(systemImage: "music.note", title: L10n.notracks).padding(.top, 30)
            } else {
                TrackList(
                    tracks: tracks, collectionID: collectionID, missing: Set(missing), hidden: hidden,
                    showsAlbum: kind == .online, remove: { removing = $0 }
                ) { index in
                    let track = tracks[index]
                    guard let position = shown.firstIndex(of: track) else { return }
                    Task {
                        await model.player.playCollectionTrack(
                            collectionID: collectionID, stid: track.id, index: position
                        ) { await play(index: position) }
                    }
                }
            }
        } actions: {
            Button(L10n.edit, systemImage: "checklist") { editing = true }
                .disabled(tracks.isEmpty)
            Button(L10n.changename, systemImage: "pencil") {
                newTitle = playlist.title
                renaming = true
            }
            Button(L10n.taptochange, systemImage: "photo") { pickingCover = true }
            if kind == .online, !tracks.isEmpty {
                Button(L10n.download, systemImage: "icloud.and.arrow.down") {
                    Task { await model.addToPlaylist(tracks, kind: .offline, creating: true) }
                }
            }
            Divider()
            Button(L10n.delete, systemImage: "trash", role: .destructive) { confirmDelete = true }
        }
        .sheet(isPresented: $editing) {
            TrackEditor(title: playlist.title, tracks: tracks, hidden: hidden, reorder: saveOrder) { selected, finish in
                ConfirmButton(
                    title: L10n.removefromplaylist, systemImage: "trash", question: L10n.removetracksfromplaylist,
                    message: L10n.removeselectedfromplaylist
                ) {
                    Task {
                        await remove(selected)
                        finish()
                    }
                }
                Spacer()
                Button(L10n.hide, systemImage: "eye.slash") {
                    Task {
                        await setHidden(selected, true)
                        finish()
                    }
                }
                Button(L10n.show, systemImage: "eye") {
                    Task {
                        await setHidden(selected, false)
                        finish()
                    }
                }
                Button(L10n.addtoplaylist, systemImage: "music.note.list") {
                    finish()
                    Task { await model.addToPlaylist(selected, kind: kind) }
                }
            }
        }
        .alert(L10n.changename, isPresented: $renaming) {
            TextField(L10n.playlistname, text: $newTitle)
            Button(L10n.cancel, role: .cancel) {}
            Button(L10n.change) { Task { await rename() } }
        }
        .confirmationDialog(L10n.removeplaylist, isPresented: $confirmDelete, titleVisibility: .visible) {
            Button(L10n.delete, role: .destructive) { Task { await deletePlaylist() } }
        }
        .confirmationDialog(
            L10n.removetracksfromplaylist, isPresented: Binding { removing != nil } set: { if !$0 { removing = nil } },
            titleVisibility: .visible, presenting: removing
        ) { track in
            Button(L10n.removefromplaylist, role: .destructive) { Task { await remove([track]) } }
        } message: { track in
            Text(track.name)
        }
        .photosPicker(isPresented: $pickingCover, selection: $pickedCover, matching: .images)
        .onChange(of: pickedCover) { Task { await setCover() } }
        .task(id: model.libraryRevision) { await load() }
    }

    private var missing: [String] {
        guard kind == .online else { return [] }
        let known = availability.durations.merging(model.player.fetchedDurations) { first, _ in first }
        return shown.map(\.id).filter { known[$0] == nil }
    }

    private func load() async {
        let database = model.database
        if kind == .online {
            let entries = (try? await database.onlineTracks(playlist.id)) ?? []
            tracks = entries.map(\.track)
            hidden = Dictionary(entries.map { ($0.stid, $0.hidden) }) { first, _ in first }
            if !tracks.isEmpty, let found = try? await model.catalog.availability(tracks.map(\.id)) {
                availability = found
            }
        } else {
            let downloads = (try? await database.localTracks(playlist.id)) ?? []
            tracks = downloads.map(\.track)
            hidden = Dictionary(downloads.map { ($0.track.id, $0.hidden) }) { first, _ in first }
            offlineDurations = Dictionary(downloads.map { ($0.track.id, $0.durationMilliseconds) }) { first, _ in first }
        }
        loaded = true
    }

    private func play(index: Int? = nil, shuffle: Bool = false) async {
        if kind == .online {
            let durations = availability.durations.merging(model.player.fetchedDurations) { first, _ in first }
            await model.player.playOnline(collectionID, shown, durations: durations, index: index, shuffle: shuffle)
            if shuffle { model.suggestSongs(for: collectionID, trackCount: shown.count) }
        } else {
            model.player.playOffline(collectionID, shown, durations: offlineDurations, index: index, shuffle: shuffle)
        }
    }

    private func saveOrder(_ ordered: [Track]) async {
        if kind == .online {
            let entries = ordered.map { OnlinePlaylistTrack(opid: playlist.id, track: $0, hidden: hidden[$0.id] ?? false) }
            try? await model.database.reorderOnlineTracks(playlist.id, entries)
        } else {
            try? await model.database.reorderLocalTracks(playlist.id, ordered.map(\.id))
        }
        model.libraryChanged()
    }

    private func setHidden(_ selected: [Track], _ value: Bool) async {
        let stids = selected.map(\.id)
        if kind == .online {
            try? await model.database.setOnlineTracksHidden(playlist.id, stids, hidden: value)
        } else {
            try? await model.database.setLocalTracksHidden(playlist.id, stids, hidden: value)
        }
        model.libraryChanged()
    }

    private func remove(_ selected: [Track]) async {
        let stids = selected.map(\.id)
        if kind == .online {
            try? await model.database.removeOnlineTracks(playlist.id, stids)
        } else {
            try? await model.database.removeLocalTracks(playlist.id, stids)
        }
        model.libraryChanged()
    }

    private func rename() async {
        let title = newTitle.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty, title != playlist.title else { return }
        guard !(await model.playlists(kind)).contains(where: { $0.title == title }) else {
            model.messages.show(L10n.playlistnamealreadyexists, systemImage: "exclamationmark.triangle", isError: true)
            return
        }
        if kind == .online {
            try? await model.database.renameOnlinePlaylist(playlist.id, title)
        } else {
            try? await model.database.renameLocalPlaylist(playlist.id, title)
        }
        playlist.title = title
        model.libraryChanged()
    }

    private func setCover() async {
        guard let data = try? await pickedCover?.loadTransferable(type: Data.self),
            let cover = PlatformImage(data: data)?.squareThumbnail(side: 600)
        else { return }
        if kind == .online {
            try? await model.database.setOnlinePlaylistCover(playlist.id, cover)
        } else {
            try? await model.database.setLocalPlaylistCover(playlist.id, cover)
        }
        playlist.cover = cover
        model.libraryChanged()
    }

    private func deletePlaylist() async {
        if model.player.current?.collectionID == collectionID { model.player.halt() }
        if kind == .online {
            try? await model.database.deleteOnlinePlaylist(playlist.id)
        } else {
            try? await model.database.deleteLocalPlaylist(playlist.id)
        }
        model.libraryChanged()
        dismiss()
    }
}

extension PlatformImage {
    /// The image cropped to a square of [side] points as JPEG, small enough
    /// to sync.
    func squareThumbnail(side: CGFloat) -> Data? {
        let scale = side / min(size.width, size.height)
        let drawn = CGSize(width: size.width * scale, height: size.height * scale)
        let frame = CGRect(x: (side - drawn.width) / 2, y: (side - drawn.height) / 2, width: drawn.width, height: drawn.height)
        #if os(macOS)
            guard let source = platformCGImage,
                let context = CGContext(
                    data: nil, width: Int(side), height: Int(side), bitsPerComponent: 8, bytesPerRow: 0,
                    space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
            else { return nil }
            context.interpolationQuality = .high
            context.draw(source, in: frame)
            return context.makeImage().flatMap {
                NSBitmapImageRep(cgImage: $0).representation(using: .jpeg, properties: [.compressionFactor: 0.8])
            }
        #else
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1
            let image = UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format).image { _ in
                draw(in: frame)
            }
            return image.jpegData(compressionQuality: 0.8)
        #endif
    }
}

/// A new playlist's cover and name. The cover starts as [initialCover] and a
/// tap picks a photo instead.
struct PlaylistCreateForm: View {
    @Environment(AppModel.self) private var model
    let kind: PlaylistKind
    var initialCover: URL?
    /// Called with the new playlist's ID once it's created.
    var created: (Int) async -> Void

    @State private var title = ""
    @State private var cover: Data?
    @State private var pickedPhoto: PhotosPickerItem?
    @State private var pickingPhoto = false
    @State private var working = false
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 22) {
            Button {
                pickingPhoto = true
            } label: {
                Group {
                    if let cover {
                        CoverImage(data: cover)
                    } else {
                        CoverImage(url: initialCover, placeholder: "photo.badge.plus")
                    }
                }
                .frame(width: 170, height: 170)
                .coverShape(16)
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(width: 38, height: 38)
                        .glassEffect(.regular, in: .circle)
                        .padding(8)
                }
                .shadow(color: .black.opacity(0.3), radius: 16, y: 8)
            }
            .buttonStyle(.press)
            TextField(L10n.playlistname, text: $title)
                .font(.system(size: 20, weight: .semibold))
                .multilineTextAlignment(.center)
                .focused($focused)
                .submitLabel(.done)
                .onSubmit { Task { await create() } }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .glassEffect(.regular, in: .capsule)
                .padding(.horizontal, 30)
            Button {
                Task { await create() }
            } label: {
                Group {
                    if working { ProgressView() } else { Text(L10n.create) }
                }
                .font(.headline)
                .frame(maxWidth: 220)
            }
            .buttonStyle(.glassProminent)
            .tint(.pongoTeal)
            .controlSize(.large)
            .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || working)
            Spacer(minLength: 0)
        }
        .padding(.top, 24)
        .frame(maxWidth: .infinity)
        .navigationTitle(L10n.createnewplaylist)
        .navigationBarTitleDisplayMode(.inline)
        .photosPicker(isPresented: $pickingPhoto, selection: $pickedPhoto, matching: .images)
        .onChange(of: pickedPhoto) {
            Task {
                guard let data = try? await pickedPhoto?.loadTransferable(type: Data.self) else { return }
                cover = PlatformImage(data: data)?.squareThumbnail(side: 600)
            }
        }
        .onAppear { focused = true }
    }

    private func create() async {
        guard !working else { return }
        working = true
        defer { working = false }
        var data = cover
        if data == nil, let initialCover {
            data = await ImagePipeline.shared.image(for: initialCover)?.squareThumbnail(side: 300)
        }
        guard let id = await model.createPlaylist(kind, title: title, cover: data) else { return }
        await created(id)
    }
}

/// Adds tracks to one of the user's playlists or a new one, like the Flutter
/// app's playlist handler: the tracks on top, then the playlists, with a
/// bookmark on those that hold them already.
struct PlaylistPicker: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let request: PlaylistRequest
    @State private var playlists: [UserPlaylist] = []
    @State private var contents: [Int: Set<String>] = [:]
    @State private var creating = false
    @State private var working = false

    var body: some View {
        NavigationStack {
            Group {
                if creating {
                    PlaylistCreateForm(kind: request.kind, initialCover: request.tracks.first?.coverURL(size: 300)) { id in
                        await add(to: id)
                    }
                } else {
                    list
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.cancel) {
                        if creating && !request.creating { creating = false } else { dismiss() }
                    }
                }
                if working {
                    ToolbarItem(placement: .confirmationAction) { ProgressView() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(.thinMaterial)
        .interactiveDismissDisabled(working)
        .onAppear { creating = request.creating }
        .task { await load() }
    }

    private var list: some View {
        List {
            Section {
                HStack(spacing: 14) {
                    CoverImage(url: request.tracks.first?.coverURL(size: 150)).frame(width: 56, height: 56).coverShape(8)
                    VStack(alignment: .leading, spacing: 2) {
                        if request.tracks.count == 1, let track = request.tracks.first {
                            Text(track.name).font(.headline).lineLimit(1)
                            Text(track.artistNames).font(.subheadline).foregroundStyle(.secondary).lineLimit(1)
                        } else {
                            Text("\(request.tracks.count) \(L10n.plustracks)").font(.headline)
                            Text(L10n.selectedtracks).font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                }
                .listRowBackground(Color.clear)
            }
            Section {
                Button {
                    withAnimation(.snappy) { creating = true }
                } label: {
                    GroupedRow(systemImage: "plus.circle.fill", title: L10n.createnewplaylist)
                }
                .foregroundStyle(.primary)
            }
            Section(request.kind == .online ? L10n.onlineplaylists : L10n.offlineplaylists) {
                ForEach(playlists) { playlist in
                    let holdsAll = request.tracks.allSatisfy { contents[playlist.id]?.contains($0.id) == true }
                    Button {
                        Task { await add(to: playlist.id) }
                    } label: {
                        HStack(spacing: 12) {
                            CoverImage(data: playlist.cover).frame(width: 48, height: 48).coverShape(8)
                            Text(playlist.title).foregroundStyle(.primary).lineLimit(1)
                            Spacer()
                            if holdsAll {
                                Image(systemName: "bookmark.fill").foregroundStyle(Color.pongoTeal)
                                    .accessibilityLabel(L10n.alreadyinplaylist)
                            }
                        }
                    }
                    .disabled(working)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .navigationTitle(L10n.addtoplaylist)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func load() async {
        let database = model.database
        playlists = await model.playlists(request.kind)
        for playlist in playlists {
            if request.kind == .online {
                contents[playlist.id] = Set(((try? await database.onlineTracks(playlist.id)) ?? []).map(\.stid))
            } else {
                contents[playlist.id] = Set(((try? await database.localTracks(playlist.id)) ?? []).map(\.track.id))
            }
        }
    }

    /// Adds the tracks to the playlist with [id], downloading them first for
    /// an offline playlist.
    private func add(to id: Int) async {
        working = true
        defer { working = false }
        let database = model.database
        if request.kind == .offline, !request.toDownload.isEmpty, !(await downloadMissing()) {
            return
        }
        var added = 0
        for track in request.tracks {
            let new =
                request.kind == .online
                ? (try? await database.addOnlineTrack(OnlinePlaylistTrack(opid: id, track: track))) ?? false
                : (try? await database.addLocalTrack(id, track.id)) ?? false
            if new { added += 1 }
        }
        if added == 0 {
            model.messages.show(L10n.playlistalreadycontainsthistrack, systemImage: "bookmark.fill")
        } else {
            model.messages.show(L10n.successful, systemImage: "text.badge.checkmark")
        }
        model.libraryChanged()
        dismiss()
    }

    private func downloadMissing() async -> Bool {
        model.messages.show(L10n.downloadhasstarted, systemImage: "arrow.down.circle")
        let tracks = request.tracks.filter { request.toDownload.contains($0.id) }.map { (track: $0, cover: String?.none) }
        do {
            guard try await model.downloads.downloadAll(tracks) else { return false }
            model.messages.show(L10n.downloadsucceeded, systemImage: "arrow.down.circle")
            return true
        } catch {
            model.messages.show(L10n.downloadfailed, systemImage: "exclamationmark.triangle", isError: true)
            return false
        }
    }
}
