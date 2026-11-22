import PongoCore
import SwiftUI
import UniformTypeIdentifiers

#if os(iOS)
    import UIKit
#endif

/// Playlists being brought over from other services. It lives in the app's
/// model, so an import keeps going while the user looks at other screens.
@Observable
final class PlaylistImports {
    enum Phase {
        case choosing
        case importing(ImportProgress)
        case done([ImportOutcome])
    }

    private(set) var phase = Phase.choosing
    /// What the user gathered to import, in the order it was added.
    private(set) var candidates: [ImportPlaylist] = []
    var selected: Set<String> = []
    private(set) var readingLink = false
    private(set) var readingLibrary = false

    @ObservationIgnored private let repository: ImportRepository
    @ObservationIgnored private let importer: PlaylistImporter
    @ObservationIgnored private let messages: MessageCenter
    /// Called when the import changed the library.
    @ObservationIgnored var changed: () -> Void = {}
    @ObservationIgnored private var task: Task<Void, Never>?

    init(client: APIClient, database: Database, messages: MessageCenter) {
        repository = ImportRepository(client: client)
        importer = PlaylistImporter(database: database, matcher: repository)
        self.messages = messages
    }

    var isImporting: Bool {
        if case .importing = phase { return true }
        return false
    }

    var selectedPlaylists: [ImportPlaylist] { candidates.filter { selected.contains($0.id) } }

    // MARK: - Gathering

    /// Adds playlists, replacing ones added before, and selects them.
    private func add(_ playlists: [ImportPlaylist]) {
        for playlist in playlists {
            if let index = candidates.firstIndex(where: { $0.id == playlist.id }) {
                candidates[index] = playlist
            } else {
                candidates.append(playlist)
            }
            selected.insert(playlist.id)
        }
    }

    func remove(_ playlist: ImportPlaylist) {
        candidates.removeAll { $0.id == playlist.id }
        selected.remove(playlist.id)
    }

    /// Reads the shared playlist or album at [link]; returns whether it worked.
    func addLink(_ link: String) async -> Bool {
        let link = link.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !link.isEmpty, !readingLink else { return false }
        readingLink = true
        defer { readingLink = false }
        do {
            let playlist = try await repository.readLink(link)
            guard !playlist.songs.isEmpty else {
                messages.show(L10n.importerrornotfound, systemImage: "exclamationmark.triangle", isError: true)
                return false
            }
            add([playlist])
            return true
        } catch let error as ImportLinkError {
            let text =
                switch error {
                case .unsupported: L10n.importerrorunsupported
                case .likedSongs: L10n.importerrorliked
                case .isPrivate: L10n.importerrorprivate
                case .notFound: L10n.importerrornotfound
                case .unavailable: L10n.importerrorunavailable
                }
            messages.show(text, systemImage: "exclamationmark.triangle", isError: true)
        } catch {
            showRequestError(error)
        }
        return false
    }

    /// Adds the playlists of the Music app's library.
    func addMusicLibrary() async {
        guard !readingLibrary else { return }
        readingLibrary = true
        defer { readingLibrary = false }
        do {
            let playlists = try await MusicLibraryReader.playlists()
            if playlists.isEmpty {
                messages.show(L10n.importnolibrary, systemImage: "music.note.list")
            }
            add(playlists)
        } catch MusicLibraryReader.Failure.denied {
            messages.show(L10n.importerrordenied, systemImage: "lock", isError: true)
        } catch {
            messages.show(L10n.importerrorlibrary, systemImage: "exclamationmark.triangle", isError: true)
        }
    }

    /// Adds the playlists in the files, and in the files of folders, at [urls].
    func addFiles(_ urls: [URL]) async {
        let playlists = await Task.detached(priority: .userInitiated) { Self.read(urls) }.value
        guard !playlists.isEmpty else {
            messages.show(L10n.importerrorfiles, systemImage: "doc.questionmark", isError: true)
            return
        }
        add(playlists)
    }

    nonisolated private static func read(_ urls: [URL]) -> [ImportPlaylist] {
        let readable: Set<String> = ["json", "csv", "tsv", "txt"]
        var playlists: [ImportPlaylist] = []
        for url in urls {
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            var files = [url]
            if (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true {
                let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: nil)
                files = (enumerator?.allObjects as? [URL] ?? [])
                    .sorted { $0.path.localizedStandardCompare($1.path) == .orderedAscending }
            }
            for file in files where readable.contains(file.pathExtension.lowercased()) {
                // Spotify's streaming history files are big and hold no playlists
                let size = (try? file.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
                guard size < 50_000_000, !file.lastPathComponent.hasPrefix("Streaming"),
                    let data = try? Data(contentsOf: file)
                else { continue }
                playlists += ImportFiles.playlists(in: data, named: file.lastPathComponent)
            }
        }
        return playlists
    }

    private func showRequestError(_ error: Error) {
        if case APIError.status(404, _) = error {
            messages.show(L10n.importerrorserver, systemImage: "server.rack", isError: true)
        } else {
            messages.show(L10n.importerrorunavailable, systemImage: "exclamationmark.triangle", isError: true)
        }
    }

    // MARK: - Importing

    func start() {
        let playlists = selectedPlaylists
        guard !playlists.isEmpty, !isImporting else { return }
        phase = .importing(ImportProgress(done: 0, total: 0, found: 0))
        task = Task {
            let finish = Self.keepRunning()
            defer { finish() }
            do {
                let outcomes = try await importer.run(playlists) { progress in
                    Task { @MainActor in
                        if case .importing = self.phase { self.phase = .importing(progress) }
                    }
                }
                candidates.removeAll { playlist in playlists.contains { $0.id == playlist.id } }
                selected.subtract(playlists.map(\.id))
                phase = .done(outcomes)
                changed()
            } catch is CancellationError {
                phase = .choosing
            } catch {
                phase = .choosing
                if case APIError.status(404, _) = error {
                    showRequestError(error)
                } else {
                    messages.show(L10n.importerrorfailed, systemImage: "exclamationmark.triangle", isError: true)
                }
            }
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
    }

    func startOver() {
        phase = .choosing
    }

    /// Puts [track] in place of the song [unmatched] couldn't find.
    func choose(_ track: Track, for unmatched: UnmatchedSong, in outcome: ImportOutcome) async {
        do {
            replace(outcome, with: try await importer.choose(track, for: unmatched, in: outcome))
            changed()
        } catch {
            messages.show(L10n.importerrorfailed, systemImage: "exclamationmark.triangle", isError: true)
        }
    }

    func skip(_ unmatched: UnmatchedSong, in outcome: ImportOutcome) {
        var outcome = outcome
        outcome.unmatched.removeAll { $0.position == unmatched.position }
        replace(outcome, with: outcome)
    }

    private func replace(_ outcome: ImportOutcome, with updated: ImportOutcome) {
        guard case .done(var outcomes) = phase, let index = outcomes.firstIndex(where: { $0.id == outcome.id })
        else { return }
        outcomes[index] = updated
        phase = .done(outcomes)
    }

    /// Asks the system to let the import finish when the app goes to the
    /// background, and keeps the screen on meanwhile; returns what ends that.
    private static func keepRunning() -> () -> Void {
        #if os(iOS)
            let application = UIApplication.shared
            let background = application.beginBackgroundTask(withName: "Import playlists")
            application.isIdleTimerDisabled = true
            return {
                application.isIdleTimerDisabled = false
                if background != .invalid { application.endBackgroundTask(background) }
            }
        #else
            let activity = ProcessInfo.processInfo.beginActivity(
                options: .userInitiated, reason: "Importing playlists")
            return { ProcessInfo.processInfo.endActivity(activity) }
        #endif
    }
}

#if DEBUG
    extension PlaylistImports {
        /// Sample lists, or what importing them did, for screenshots.
        func showDemo(results: Bool) {
            let songs = [
                ImportSong(title: "Cesarica", artists: ["Oliver Dragojević"]),
                ImportSong(title: "Moja štikla", artists: ["Severina"]),
                ImportSong(title: "Blinding Lights", artists: ["The Weeknd"]),
            ]
            add([
                ImportPlaylist(id: "demo-1", name: "Ljeto 2026", source: .spotify, songs: songs + songs + songs),
                ImportPlaylist(
                    id: "demo-2", name: "All Out 80s", source: .spotify, songs: Array(repeating: songs[2], count: 100),
                    truncated: true),
                ImportPlaylist(id: "demo-3", name: "Klapa", source: .appleMusic, songs: songs),
                ImportPlaylist(
                    id: "demo-4", name: ImportFiles.likedSongsName, source: .spotify, songs: songs,
                    destination: .favourites),
            ])
            selected.remove("demo-2")
            guard results else { return }
            let lost = UnmatchedSong(
                position: 1, song: songs[1],
                alternatives: [
                    Track(id: "1", name: "Moja stikla (Extended Version)", artists: [ArtistRef(id: "2", name: "Severina")], album: nil)
                ])
            phase = .done([
                ImportOutcome(
                    playlist: candidates[0], opid: nil, merged: false, added: 8, alreadyThere: 0, unmatched: [lost]),
                ImportOutcome(
                    playlist: candidates[3], opid: nil, merged: false, added: 3, alreadyThere: 0, unmatched: []),
            ])
        }
    }
#endif

// MARK: - Screens

/// Brings playlists over from Spotify and Apple Music.
struct ImportPlaylistsView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let imports = model.imports
        Group {
            switch imports.phase {
            case .choosing: ImportChooser()
            case .importing(let progress): ImportProgressView(progress: progress)
            case .done(let outcomes): ImportResultsView(outcomes: outcomes)
            }
        }
        .navigationTitle(L10n.importplaylists)
    }
}

private struct ImportChooser: View {
    @Environment(AppModel.self) private var model
    @State private var link = ""
    @State private var choosingFiles = false

    var body: some View {
        @Bindable var imports = model.imports
        List {
            Section {
                Text(L10n.importdescription).font(.subheadline).foregroundStyle(.secondary)
            }
            .listRowBackground(Color.clear)

            if !imports.candidates.isEmpty {
                Section {
                    ForEach(imports.candidates) { playlist in
                        CandidateRow(playlist: playlist, selected: $imports.selected)
                            .groupedRowBackground()
                            .swipeActions {
                                Button(L10n.delete, systemImage: "trash", role: .destructive) {
                                    imports.remove(playlist)
                                }
                            }
                            .contextMenu {
                                Button(L10n.delete, systemImage: "trash", role: .destructive) {
                                    imports.remove(playlist)
                                }
                            }
                    }
                } header: {
                    HStack {
                        Text(L10n.importtoimport)
                        Spacer()
                        let all = imports.selected.count == imports.candidates.count
                        Button(all ? L10n.importselectnone : L10n.selectall) {
                            imports.selected = all ? [] : Set(imports.candidates.map(\.id))
                        }
                        .font(.footnote)
                        .buttonStyle(.borderless)
                    }
                }
            }

            Section {
                HStack {
                    TextField(L10n.importlinkplaceholder, text: $link)
                        .textContentType(.URL)
                        .autocorrectionDisabled()
                        #if os(iOS)
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                        #endif
                        .onSubmit(addLink)
                    if imports.readingLink {
                        ProgressView()
                    } else if link.isEmpty {
                        #if os(iOS)
                            PasteButton(payloadType: String.self) { strings in
                                guard let pasted = strings.first else { return }
                                Task { @MainActor in
                                    link = pasted
                                    addLink()
                                }
                            }
                            .labelStyle(.iconOnly)
                            .buttonBorderShape(.capsule)
                        #endif
                    } else {
                        Button(L10n.importadd, action: addLink).buttonStyle(.borderless)
                    }
                }
                .groupedRowBackground()
            } header: {
                Text(L10n.importfromlink)
            } footer: {
                Text(L10n.importlinkfooter)
            }

            Section {
                Button {
                    Task { await imports.addMusicLibrary() }
                } label: {
                    GroupedRow(systemImage: "music.note.house", title: L10n.importreadlibrary) {
                        if imports.readingLibrary { ProgressView() }
                    }
                }
                .disabled(imports.readingLibrary)
                .groupedRowBackground()
            } header: {
                Text(L10n.importapplelibrary)
            } footer: {
                Text(L10n.importlibraryfooter)
            }

            Section {
                Button {
                    choosingFiles = true
                } label: {
                    GroupedRow(systemImage: "doc.badge.plus", title: L10n.importchoosefiles)
                }
                .groupedRowBackground()
            } header: {
                Text(L10n.importfiles)
            } footer: {
                Text(L10n.importfilesfooter)
            }

        }
        .listStyle(.insetGrouped)
        .pongoBackground()
        .safeAreaInset(edge: .bottom) {
            if !imports.candidates.isEmpty {
                let count = imports.selectedPlaylists.count
                let songs = imports.selectedPlaylists.reduce(0) { $0 + $1.songs.count }
                Button {
                    imports.start()
                } label: {
                    Text("\(L10n.importstart) · \(count) \(L10n.playlists.lowercased()) · \(songs) \(L10n.plustracks)")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.glassProminent)
                .tint(.pongoTeal)
                .disabled(count == 0)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
            }
        }
        .fileImporter(
            isPresented: $choosingFiles,
            allowedContentTypes: [.json, .commaSeparatedText, .tabSeparatedText, .plainText, .folder],
            allowsMultipleSelection: true
        ) { result in
            guard case .success(let urls) = result, !urls.isEmpty else { return }
            Task { await imports.addFiles(urls) }
        }
    }

    private func addLink() {
        let current = link
        Task {
            if await model.imports.addLink(current), link == current { link = "" }
        }
    }
}

private struct CandidateRow: View {
    let playlist: ImportPlaylist
    @Binding var selected: Set<String>

    var body: some View {
        let isSelected = selected.contains(playlist.id)
        Button {
            if isSelected { selected.remove(playlist.id) } else { selected.insert(playlist.id) }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color.pongoTeal : .secondary)
                CoverImage(url: playlist.image.flatMap(URL.init(string:)), placeholder: "music.note.list")
                    .frame(width: 44, height: 44)
                    .coverShape(7)
                VStack(alignment: .leading, spacing: 2) {
                    Text(playlist.name).font(.system(size: 16, weight: .semibold)).lineLimit(1)
                    Text(subtitle).font(.system(size: 12)).foregroundStyle(.secondary).lineLimit(1)
                    if playlist.destination == .favourites {
                        Label(L10n.importtofavourites, systemImage: "heart.fill")
                            .font(.system(size: 12)).foregroundStyle(.secondary)
                    }
                    if playlist.truncated {
                        Label(
                            playlist.source == .spotify ? L10n.importpartial : L10n.importpartialother,
                            systemImage: "exclamationmark.triangle.fill")
                            .font(.system(size: 12)).foregroundStyle(.orange)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    private var subtitle: String {
        let source =
            switch playlist.source {
            case .spotify: "Spotify"
            case .appleMusic: "Apple Music"
            case .file: L10n.importfiles
            }
        let read = playlist.songs.count
        let count =
            if !playlist.truncated {
                "\(read)"
            } else if let total = playlist.total, total > read {
                "\(read)/\(total)"
            } else {
                "\(read)+"
            }
        return "\(source) · \(count) \(L10n.plustracks)"
    }
}

private struct ImportProgressView: View {
    @Environment(AppModel.self) private var model
    let progress: ImportProgress

    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            ProgressView(value: Double(progress.done), total: Double(max(progress.total, 1)))
                .tint(.pongoTeal)
                .frame(maxWidth: 360)
            Text(L10n.importfinding).font(.title3.weight(.semibold))
            Text("\(progress.done) / \(progress.total) · \(progress.found) \(L10n.importfound)")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
            Text(L10n.importkeepopen).font(.footnote).foregroundStyle(.secondary)
            Button(L10n.cancel, role: .cancel) { model.imports.cancel() }
                .buttonStyle(.glass)
            Spacer()
        }
        .padding(30)
        .frame(maxWidth: .infinity)
        .pongoBackground()
    }
}

private struct ImportResultsView: View {
    @Environment(AppModel.self) private var model
    let outcomes: [ImportOutcome]
    @State private var searching: SongSearch?

    struct SongSearch: Identifiable {
        var id: Int { unmatched.position }
        var unmatched: UnmatchedSong
        var outcome: ImportOutcome
    }

    var body: some View {
        List {
            Section {
                let added = outcomes.reduce(0) { $0 + $1.added }
                let missing = outcomes.reduce(0) { $0 + $1.unmatched.count }
                GroupedRow(
                    systemImage: missing == 0 ? "checkmark.circle.fill" : "checkmark.circle",
                    title: "\(L10n.importsummary): \(outcomes.count) \(L10n.playlists.lowercased())",
                    subtitle: "\(added) \(L10n.importadded)"
                        + (missing > 0 ? " · \(missing) \(L10n.importnotfound.lowercased())" : ""))
                .groupedRowBackground()
            }
            ForEach(outcomes) { outcome in
                Section {
                    summaryRow(outcome)
                    ForEach(outcome.unmatched) { unmatched in
                        UnmatchedRow(
                            unmatched: unmatched,
                            choose: { track in Task { await model.imports.choose(track, for: unmatched, in: outcome) } },
                            search: { searching = SongSearch(unmatched: unmatched, outcome: outcome) },
                            skip: { model.imports.skip(unmatched, in: outcome) })
                        .groupedRowBackground()
                    }
                } header: {
                    Text(PlaylistImporter.title(for: outcome.playlist))
                } footer: {
                    if !outcome.unmatched.isEmpty { Text(L10n.importnotfounddetail) }
                }
            }
        }
        .listStyle(.insetGrouped)
        .pongoBackground()
        .toolbar {
            Button(L10n.importmore, systemImage: "plus") { model.imports.startOver() }
        }
        .sheet(item: $searching) { search in
            NavigationStack {
                ImportSongSearchView(song: search.unmatched.song) { track in
                    searching = nil
                    Task { await model.imports.choose(track, for: search.unmatched, in: search.outcome) }
                }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button(L10n.cancel) { searching = nil } }
                }
            }
            #if os(macOS)
                .frame(minWidth: 460, minHeight: 520)
            #endif
        }
    }

    @ViewBuilder
    private func summaryRow(_ outcome: ImportOutcome) -> some View {
        let row = GroupedRow(
            systemImage: outcome.playlist.destination == .favourites ? "heart.fill" : "music.note.list",
            title: "\(outcome.added) \(L10n.importadded)"
                + (outcome.alreadyThere > 0 ? " · \(outcome.alreadyThere) \(L10n.importalreadythere)" : ""),
            subtitle: outcome.merged
                ? L10n.importmerged : (outcome.unmatched.isEmpty ? L10n.importallfound : nil))
        if outcome.playlist.destination == .favourites {
            NavigationLink(value: Route.favourites) { row }.groupedRowBackground()
        } else if let opid = outcome.opid {
            NavigationLink(
                value: Route.userPlaylist(
                    .online, UserPlaylist(id: opid, title: PlaylistImporter.title(for: outcome.playlist), cover: nil))
            ) { row }
            .groupedRowBackground()
        } else {
            row.groupedRowBackground()
        }
    }
}

private struct UnmatchedRow: View {
    let unmatched: UnmatchedSong
    var choose: (Track) -> Void
    var search: () -> Void
    var skip: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "questionmark.circle").font(.title3).foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(unmatched.song.title).font(.system(size: 15, weight: .semibold))
                Text(unmatched.song.artists.joined(separator: ", ")).font(.system(size: 12)).foregroundStyle(.secondary)
            }
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
            Menu(L10n.importchoose) {
                ForEach(unmatched.alternatives) { track in
                    Button("\(track.name) — \(track.artistNames)") { choose(track) }
                }
                if !unmatched.alternatives.isEmpty { Divider() }
                Button(L10n.search, systemImage: "magnifyingglass", action: search)
                Button(L10n.skip, systemImage: "forward", action: skip)
            }
            .fixedSize()
        }
        .padding(.vertical, 2)
    }
}

/// Searches the catalog for a song that wasn't found, starting with its name.
private struct ImportSongSearchView: View {
    @Environment(AppModel.self) private var model
    let song: ImportSong
    var pick: (Track) -> Void
    @State private var query = ""
    @State private var results: [Track] = []
    @State private var searching = false

    var body: some View {
        List {
            ForEach(results) { track in
                Button {
                    pick(track)
                } label: {
                    TrackRow(track: track, collectionID: "import.search")
                }
                .buttonStyle(.plain)
                .groupedRowBackground()
            }
        }
        .listStyle(.insetGrouped)
        .pongoBackground()
        .overlay {
            if searching && results.isEmpty { ProgressView() }
        }
        .navigationTitle(L10n.importpicksong)
        .searchable(text: $query)
        .onSubmit(of: .search) { Task { await search() } }
        .task {
            query = ([song.artists.first].compactMap { $0 } + [song.title]).joined(separator: " ")
            await search()
        }
    }

    private func search() async {
        let query = query.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return }
        searching = true
        defer { searching = false }
        results = (try? await model.catalog.search(query, market: model.settings.settings.market))?.tracks ?? []
    }
}
