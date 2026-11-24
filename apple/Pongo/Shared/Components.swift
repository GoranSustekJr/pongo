import PongoCore
import SwiftUI

// MARK: - Tracks

/// A track in a list, as the Flutter app draws it: cover, title, artists, and
/// whether it's playing or the server is fetching it.
struct TrackRow: View {
    @Environment(AppModel.self) private var model
    let track: Track
    /// The list the row is in, to tell whether this row is the one playing.
    var collectionID: String
    /// Whether the server can stream the track right away.
    var available = true
    var hidden = false
    /// Says why the track isn't on the server, where that matters.
    var serverNote: ServerNote?

    var body: some View {
        let current = model.player.current
        let isCurrent = current?.stid == track.id && current?.collectionID == collectionID
        HStack(spacing: 12) {
            CoverImage(url: track.coverURL(size: 150))
                .frame(width: 50, height: 50)
                .coverShape(7.5)
            VStack(alignment: .leading, spacing: 2) {
                Text(track.name).font(.system(size: 16.5, weight: .semibold))
                Text(track.artistNames).font(.system(size: 12.5)).opacity(0.78)
                if let serverNote {
                    Label(serverNote.text, systemImage: serverNote.systemImage)
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundStyle(serverNote.color)
                }
            }
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
            if hidden { Image(systemName: "eye.slash").font(.footnote).opacity(0.7) }
            if model.downloadingIDs.contains(track.id) {
                ProgressView().controlSize(.small).accessibilityLabel(L10n.downloading)
            } else if !track.isDownloaded, model.downloadedIDs.contains(track.id) {
                Image(systemName: "arrow.down.circle.fill").font(.caption).opacity(0.6)
            }
            TrackStatus(stid: track.id, isCurrent: isCurrent)
        }
        .frame(height: 65)
        .opacity(available && !hidden ? 1 : serverNote == nil ? 0.5 : 0.75)
        .contentShape(.rect)
    }
}

/// Why a track of the user's playlist isn't on the server.
enum ServerNote: Hashable {
    /// The server hasn't downloaded it yet; it does when it plays.
    case notYet
    case failed(DownloadFailure)

    init(failure: DownloadFailure?) {
        self = failure.map(ServerNote.failed) ?? .notYet
    }

    var text: String {
        switch self {
        case .notYet: L10n.notonserveryet
        case .failed(.noMatch): L10n.failednomatch
        case .failed(.catalog): L10n.failedcatalog
        case .failed(.download): L10n.faileddownload
        }
    }

    var systemImage: String {
        self == .notYet ? "icloud.slash" : "exclamationmark.triangle.fill"
    }

    var color: Color {
        self == .notYet ? .orange : .red
    }
}

/// A field that narrows a list of tracks to those whose title, artists or
/// album contain what's typed.
struct TrackSearchField: View {
    var prompt = L10n.searchinplaylist
    @Binding var text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField(prompt, text: $text)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                .submitLabel(.search)
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L10n.cancel)
            }
        }
        .font(.system(size: 16))
        .padding(.horizontal, 12)
        .frame(height: 38)
        .pongoGlass(in: Capsule(), interactive: true)
    }
}

extension Track {
    /// Whether the title, an artist or the album contains [query], ignoring
    /// case and diacritics, so "durdevdan" finds "Đurđevdan".
    func matches(_ query: String) -> Bool {
        let query = query.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return true }
        let fields = [name, artistNames, album?.name ?? ""]
        let folded = Self.fold(query)
        return fields.contains { Self.fold($0).contains(folded) }
    }

    private static func fold(_ text: String) -> String {
        // Folding leaves đ, which has no decomposition, as it is
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
            .replacingOccurrences(of: "đ", with: "d")
    }
}

/// Rows that dim while pressed, like the Flutter app's Cupertino buttons.
struct RowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.white.opacity(configuration.isPressed ? 0.08 : 0))
                    .padding(.horizontal, -8)
            }
            .opacity(configuration.isPressed ? 0.7 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == RowButtonStyle {
    static var row: RowButtonStyle { RowButtonStyle() }
}

/// Buttons that shrink and dim a little while pressed.
struct PressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .opacity(configuration.isPressed ? 0.6 : 1)
            .animation(.spring(duration: 0.25), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PressButtonStyle {
    static var press: PressButtonStyle { PressButtonStyle() }
}

/// The tracks of a collection, separated by thin lines; a tap plays one and
/// holding one shows its menu.
struct TrackList: View {
    let tracks: [Track]
    var collectionID: String
    /// IDs of tracks the server has to fetch before they play.
    var missing: Set<String> = []
    var hidden: [String: Bool] = [:]
    /// Whether the missing tracks say why they aren't on the server.
    var explainsMissing = false
    /// Why the server couldn't download some of the missing tracks.
    var failed: [String: DownloadFailure] = [:]
    var showsAlbum = true
    /// Removes a track from the user's playlist, from its menu; nil elsewhere.
    var remove: ((Track) -> Void)?
    var play: (Int) -> Void

    var body: some View {
        LazyVStack(spacing: 0) {
            DownloadProgressBar(stids: tracks.map(\.id)).padding(.bottom, 6)
            ForEach(Array(tracks.enumerated()), id: \.offset) { index, track in
                Button {
                    play(index)
                } label: {
                    let available = !missing.contains(track.id)
                    TrackRow(
                        track: track, collectionID: collectionID, available: available,
                        hidden: hidden[track.id] == true,
                        serverNote: explainsMissing && !available ? ServerNote(failure: failed[track.id]) : nil)
                }
                .buttonStyle(.row)
                .contextMenu {
                    TrackMenu(track: track, collectionID: collectionID, showsAlbum: showsAlbum)
                    if let remove {
                        Divider()
                        Button(L10n.removefromplaylist, systemImage: "trash", role: .destructive) { remove(track) }
                    }
                }
                if index < tracks.count - 1 {
                    Rectangle().fill(Color.pongoIcon.opacity(0.2)).frame(height: 0.5).padding(.leading, 62)
                }
            }
        }
        .padding(.horizontal, 15)
    }
}

/// How far the download of a list's tracks is, while any of them download.
struct DownloadProgressBar: View {
    @Environment(AppModel.self) private var model
    let stids: [String]

    var body: some View {
        if let progress = model.downloadProgress(of: stids) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Label(L10n.downloading, systemImage: "arrow.down.circle")
                    Spacer()
                    Text("\(progress.done) / \(progress.total)").monospacedDigit()
                }
                .font(.system(size: 13.5, weight: .semibold))
                ProgressView(value: Double(progress.done), total: Double(max(progress.total, 1)))
                    .tint(Color.pongoTeal)
            }
            .padding(12)
            .pongoGlass(in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .animation(.smooth, value: progress.done)
        }
    }
}

/// The actions on a track, in the Flutter app's order: downloading, adding
/// to a playlist, queueing and liking, then going to its album or artists.
struct TrackMenu: View {
    @Environment(AppModel.self) private var model
    let track: Track
    var collectionID = "search.single"
    var showsAlbum = true

    var body: some View {
        if track.isDownloaded {
            Button(L10n.addtoplaylist, systemImage: "music.note.list") {
                Task { await model.addToPlaylist([track], kind: .offline) }
            }
        } else {
            if !model.downloadedIDs.contains(track.id) {
                Button(L10n.download, systemImage: "icloud.and.arrow.down") {
                    Task { await model.download(track) }
                }
            }
            Button(L10n.addtoplaylist, systemImage: "music.note.list") {
                Task { await model.addToPlaylist([track]) }
            }
        }
        Divider()
        Button(L10n.firsttoqueue, systemImage: "text.line.first.and.arrowtriangle.forward") {
            Haptics.tap()
            Task { await model.player.addNext(track, collectionID: collectionID) }
        }
        Button(L10n.lasttoqueue, systemImage: "text.line.last.and.arrowtriangle.forward") {
            Haptics.tap()
            Task { await model.player.addLast(track, collectionID: collectionID) }
        }
        if !track.isDownloaded {
            Divider()
            let favourite = model.favouriteIDs.contains(track.id)
            Button(favourite ? L10n.unlike : L10n.like, systemImage: favourite ? "heart.fill" : "heart") {
                Task { await model.toggleFavourite(track) }
            }
        }
        // Catalog tracks only: files from the device have no other recordings
        if track.id.allSatisfy(\.isNumber) {
            Button(L10n.wrongversion, systemImage: "waveform.badge.magnifyingglass") {
                model.versionRequest = track
            }
        }
        if (showsAlbum && track.album != nil) || !track.artists.isEmpty {
            Divider()
        }
        if showsAlbum, let album = track.album, !album.id.isEmpty {
            Button(L10n.album, systemImage: "square.stack") { Task { await model.showAlbum(album.id) } }
        }
        ForEach(track.artists, id: \.id) { artist in
            Button(artist.name ?? L10n.artist, systemImage: "music.microphone") {
                Task { await model.showArtist(artist) }
            }
        }
    }
}

/// Play and shuffle buttons of a track list, or a halt button while that list
/// plays, on a glass capsule. Lists that edit swap in their own actions.
struct PlayShuffleBar<EditActions: View>: View {
    @Environment(AppModel.self) private var model
    var collectionID: String
    var canShuffle = true
    var editing = false
    var play: () async -> Void
    var shuffle: () async -> Void
    @ViewBuilder var editActions: EditActions

    var body: some View {
        let player = model.player
        let playing = player.current?.collectionID == collectionID
        HStack(spacing: 0) {
            if editing {
                editActions
            } else if playing {
                Button {
                    player.halt()
                } label: {
                    Label(L10n.halt, systemImage: "stop.fill").frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .transition(.blurReplace)
            } else {
                Button {
                    Task { await play() }
                } label: {
                    Label(L10n.play, systemImage: "play.fill").frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .transition(.blurReplace)
                Button {
                    Task { await shuffle() }
                } label: {
                    Label(L10n.shuffle, systemImage: "shuffle").frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .opacity(canShuffle ? 1 : 0.5)
                .disabled(!canShuffle)
                .transition(.blurReplace)
            }
        }
        .font(.system(size: 19, weight: .medium))
        .buttonStyle(.press)
        .frame(height: 44)
        .contentShape(.capsule)
        .pongoGlass(in: Capsule(), interactive: true)
        .animation(.smooth(duration: 0.3), value: playing)
        .animation(.smooth(duration: 0.3), value: editing)
    }
}

extension PlayShuffleBar where EditActions == EmptyView {
    init(
        collectionID: String, canShuffle: Bool = true, play: @escaping () async -> Void,
        shuffle: @escaping () async -> Void
    ) {
        self.init(
            collectionID: collectionID, canShuffle: canShuffle, editing: false, play: play, shuffle: shuffle,
            editActions: { EmptyView() })
    }
}

// MARK: - Collections

/// The screen every track collection shares, as in the Flutter app: its cover
/// big at the top, stretching when pulled, over the cover's blurred colors;
/// a floating bar to play or shuffle that sticks below the navigation bar;
/// then the content.
struct CollectionScreen<Bar: View, Content: View, Actions: View>: View {
    @Environment(AppModel.self) private var model
    @Environment(\.colorScheme) private var colorScheme
    var title: String
    var subtitle = ""
    var coverURL: URL?
    var coverData: Data?
    var placeholder = "music.note.list"
    @ViewBuilder var bar: Bar
    @ViewBuilder var content: Content
    @ViewBuilder var actions: Actions

    @State private var collapsed = false

    var body: some View {
        let blurred = model.settings.settings.useBlur
        GeometryReader { geometry in
            let top = geometry.safeAreaInsets.top
            let coverHeight = max((geometry.size.height + top) * 0.5 - top, 200)
            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                    header(width: geometry.size.width, height: coverHeight, top: top)
                    Section {
                        content.padding(.top, 10)
                    } header: {
                        bar.padding(.horizontal, 15).padding(.vertical, 8)
                    }
                }
                .padding(.bottom, 40)
            }
            .onScrollGeometryChange(for: Bool.self) { scroll in
                scroll.contentOffset.y + scroll.contentInsets.top > coverHeight - 40
            } action: { _, isCollapsed in
                withAnimation(.easeInOut(duration: 0.2)) { collapsed = isCollapsed }
            }
        }
        .scrollEdgeEffectHidden(true, for: .all)
        .background { ArtworkBackground(url: coverURL, data: coverData, dim: 0.3) }
        .environment(\.colorScheme, blurred ? .dark : colorScheme)
        .navigationBarColorScheme(blurred || !collapsed ? .dark : nil)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(title).font(.headline).lineLimit(1).opacity(collapsed ? 1 : 0)
            }
            ToolbarItem(placement: .barTrailing) {
                Menu {
                    actions
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
        }
    }

    private func header(width: CGFloat, height: CGFloat, top: CGFloat) -> some View {
        Color.clear
            .frame(height: height)
            .overlay(alignment: .bottom) {
                Group {
                    if let coverData {
                        CoverImage(data: coverData, placeholder: placeholder)
                    } else {
                        CoverImage(url: coverURL, placeholder: placeholder)
                    }
                }
                .frame(width: width, height: height + top)
                .overlay {
                    LinearGradient(
                        stops: [
                            .init(color: .black.opacity(0.45), location: 0), .init(color: .clear, location: 0.3),
                            .init(color: .clear, location: 0.55), .init(color: .black.opacity(0.6), location: 1),
                        ], startPoint: .top, endPoint: .bottom)
                }
                .clipped()
                .visualEffect { content, proxy in
                    // Pulling down past the top stretches the cover upwards
                    let pull = max(proxy.frame(in: .scrollView).minY, 0)
                    return content.scaleEffect(1 + pull / max(proxy.size.height, 1), anchor: .bottom)
                }
            }
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.system(size: 30, weight: .bold)).lineLimit(2)
                    if !subtitle.isEmpty {
                        Text(subtitle).font(.system(size: 16, weight: .medium)).opacity(0.85).lineLimit(2)
                    }
                }
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.3), radius: 8)
                .padding(.horizontal, 20)
                .padding(.bottom, 14)
            }
    }
}

// MARK: - Shelves

/// A cover with its title, for the rows on the home and artist screens.
struct Tile: View {
    var image: URL?
    var title: String
    var subtitle = ""
    var circle = false
    var placeholder = "music.note"

    var body: some View {
        VStack(alignment: circle ? .center : .leading, spacing: 5) {
            CoverImage(url: image, placeholder: placeholder)
                .frame(width: 140, height: 140)
                .clipShape(circle ? AnyShape(Circle()) : AnyShape(RoundedRectangle(cornerRadius: 14, style: .continuous)))
            Text(title).font(.system(size: 14, weight: .medium)).lineLimit(1)
            if !subtitle.isEmpty {
                Text(subtitle).font(.system(size: 12)).opacity(0.69).lineLimit(1)
            }
        }
        .frame(width: 140, alignment: circle ? .center : .leading)
        .contentShape(.rect)
    }
}

/// A sideways scrolling row of tiles under a title.
struct Shelf<Item: Identifiable, Content: View>: View {
    var title: String
    var items: [Item]
    @ViewBuilder var content: (Item) -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(title)
            ScrollView(.horizontal) {
                LazyHStack(alignment: .top, spacing: 15) {
                    ForEach(items, content: content)
                }
                .scrollTargetLayout()
                .padding(.horizontal, 17.5)
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned)
            .buttonStyle(.press)
        }
    }
}

// MARK: - Grouped rows

extension Color {
    /// The icons' color: white on dark, near black on light.
    static let pongoIcon = adaptive(
        light: PlatformColor(white: 0, alpha: 0.8), dark: PlatformColor(white: 1, alpha: 0.9))
}

/// A row of the library and settings screens: an icon, a title with an
/// optional subtitle, and something at its end.
struct GroupedRow<Trailing: View>: View {
    var systemImage: String
    var title: String
    var subtitle: String?
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 21))
                .foregroundStyle(Color.pongoIcon)
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.system(size: 16)).lineLimit(1)
                if let subtitle {
                    Text(subtitle).font(.system(size: 12)).foregroundStyle(.secondary).lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            trailing
        }
        .frame(minHeight: 44)
    }
}

extension GroupedRow where Trailing == EmptyView {
    init(systemImage: String, title: String, subtitle: String? = nil) {
        self.init(systemImage: systemImage, title: title, subtitle: subtitle) { EmptyView() }
    }
}

/// A grouped row whose value is picked from a menu at its end.
struct MenuRow<Value: Hashable, Options: View>: View {
    var systemImage: String
    var title: String
    var subtitle: String?
    @Binding var selection: Value
    @ViewBuilder var options: Options

    var body: some View {
        GroupedRow(systemImage: systemImage, title: title, subtitle: subtitle) {
            Picker(title, selection: $selection) { options }
                .labelsHidden()
                .pickerStyle(.menu)
                .fixedSize()
        }
        .groupedRowBackground()
    }
}

extension View {
    /// The translucent navy card behind grouped rows.
    func groupedRowBackground() -> some View {
        listRowBackground(Color.pongoCard.opacity(0.55))
    }
}

/// A message filling an empty screen.
struct EmptyMessage: View {
    var systemImage: String
    var title: String
    var detail: String?

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage).font(.system(size: 44)).foregroundStyle(Color.pongoIcon)
            Text(title).font(.system(size: 19, weight: .semibold))
            if let detail { Text(detail).font(.subheadline).foregroundStyle(.secondary) }
        }
        .multilineTextAlignment(.center)
        .padding(30)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Editing

/// Selects tracks of a list to act on several at once, and reorders them
/// when the list allows it.
struct TrackEditor<Actions: View>: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    var title: String
    @State var tracks: [Track]
    var hidden: [String: Bool] = [:]
    /// IDs of the tracks that aren't on the server, marked and selectable at once.
    var missing: Set<String> = []
    /// Saves a new order; nil when the list can't be reordered.
    var reorder: (([Track]) async -> Void)?
    @ViewBuilder var actions: (_ selected: [Track], _ finish: @escaping () -> Void) -> Actions

    @State private var selection: Set<String> = []
    @State private var query = ""

    /// The tracks the search leaves.
    private var listed: [Track] { tracks.filter { $0.matches(query) } }

    /// Selects the missing tracks, or deselects them when they're all selected.
    private func selectMissing() {
        selection = missing.isSubset(of: selection) ? selection.subtracting(missing) : selection.union(missing)
    }

    var body: some View {
        #if os(macOS)
            macBody
        #else
            NavigationStack {
                list
                    .searchable(text: $query, prompt: L10n.searchinplaylist)
                    .navigationTitle(selection.isEmpty ? title : "\(selection.count) \(L10n.selected)")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar { toolbar }
            }
        #endif
    }

    #if os(macOS)
        /// A Mac sheet has no toolbar, so the title, the selection and the
        /// actions sit in the sheet itself, with buttons to move songs as well
        /// as dragging them.
        private var macBody: some View {
            let allSelected = !listed.isEmpty && Set(listed.map(\.id)).isSubset(of: selection)
            return VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(selection.isEmpty ? title : "\(selection.count) \(L10n.selected)").font(.headline)
                        if reorder != nil {
                            Text(L10n.dragtoreorder).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    if !missing.isEmpty {
                        Button(L10n.selectnotonserver, systemImage: "icloud.slash", action: selectMissing)
                    }
                    Button(allSelected ? L10n.deselectall : L10n.selectall) {
                        let ids = Set(listed.map(\.id))
                        selection = allSelected ? selection.subtracting(ids) : selection.union(ids)
                    }
                }
                .padding(14)
                if tracks.count > 1 {
                    TrackSearchField(text: $query).padding(.horizontal, 14).padding(.bottom, 10)
                }
                Divider()
                List(selection: $selection) {
                    ForEach(listed) { track in
                        row(track).tag(track.id)
                    }
                    .onMove(perform: query.isEmpty ? moveAction : nil)
                }
                .listStyle(.inset)
                Divider()
                HStack(spacing: 10) {
                    if reorder != nil {
                        Button(L10n.moveup, systemImage: "arrow.up") { shift(-1) }
                            .disabled(!canShift(-1))
                        Button(L10n.movedown, systemImage: "arrow.down") { shift(1) }
                            .disabled(!canShift(1))
                        Divider().frame(height: 18)
                    }
                    actions(tracks.filter { selection.contains($0.id) }, { dismiss() })
                        .disabled(selection.isEmpty)
                    Button(L10n.done) { dismiss() }
                        .keyboardShortcut(.defaultAction)
                }
                .padding(14)
            }
            .frame(minWidth: 620, idealWidth: 680, minHeight: 520, idealHeight: 640)
        }

        /// Moves the selected tracks one place up (-1) or down (1), keeping
        /// their order among themselves.
        private func shift(_ step: Int) {
            guard canShift(step) else { return }
            let selected = tracks.indices.filter { selection.contains(tracks[$0].id) }
            var moved = tracks
            for index in step < 0 ? selected : selected.reversed() {
                moved.swapAt(index, index + step)
            }
            tracks = moved
            Task { await reorder?(moved) }
        }

        private func canShift(_ step: Int) -> Bool {
            guard query.isEmpty else { return false }
            let selected = tracks.indices.filter { selection.contains(tracks[$0].id) }
            guard let first = selected.first, let last = selected.last else { return false }
            return step < 0 ? first > 0 : last < tracks.count - 1
        }
    #endif

    private var list: some View {
        List(selection: $selection) {
            ForEach(listed) { track in
                row(track).tag(track.id).listRowBackground(Color.clear)
            }
            .onMove(perform: query.isEmpty ? moveAction : nil)
        }
        .listStyle(.plain)
        .pongoBackground()
        .alwaysSelecting()
    }

    private func row(_ track: Track) -> some View {
        let isHidden = hidden[track.id] == true
        return HStack(spacing: 12) {
            CoverImage(url: track.coverURL(size: 150)).frame(width: 44, height: 44).coverShape(6)
            VStack(alignment: .leading, spacing: 2) {
                Text(track.name).font(.system(size: 16, weight: .semibold))
                Text(track.artistNames).font(.system(size: 12.5)).foregroundStyle(.secondary)
            }
            .lineLimit(1)
            Spacer(minLength: 0)
            if missing.contains(track.id) {
                Image(systemName: "icloud.slash").foregroundStyle(.orange).accessibilityLabel(L10n.notonserveryet)
            }
            if isHidden { Image(systemName: "eye.slash").foregroundStyle(.secondary) }
        }
        .opacity(isHidden ? 0.6 : 1)
    }

    @ToolbarContentBuilder private var toolbar: some ToolbarContent {
        let ids = Set(listed.map(\.id))
        let allSelected = !ids.isEmpty && ids.isSubset(of: selection)
        ToolbarItem(placement: .barLeading) {
            Button(allSelected ? L10n.deselectall : L10n.selectall) {
                selection = allSelected ? selection.subtracting(ids) : selection.union(ids)
            }
        }
        if !missing.isEmpty {
            ToolbarItem(placement: .barLeading) {
                Button(L10n.selectnotonserver, systemImage: "icloud.slash", action: selectMissing)
            }
        }
        ToolbarItem(placement: .confirmationAction) {
            Button(L10n.done) { dismiss() }
        }
        ToolbarItemGroup(placement: .barBottom) {
            actions(tracks.filter { selection.contains($0.id) }, { dismiss() })
                .disabled(selection.isEmpty)
        }
    }

    private var moveAction: ((IndexSet, Int) -> Void)? {
        guard reorder != nil else { return nil }
        return { offsets, destination in move(offsets, destination) }
    }

    private func move(_ offsets: IndexSet, _ destination: Int) {
        tracks.move(fromOffsets: offsets, toOffset: destination)
        let ordered = tracks
        Task { await reorder?(ordered) }
    }
}
