import PongoCore
import SwiftUI

/// The window as in Mac music apps: the library in the sidebar with the
/// search field on top, the picked section beside it, the player in the
/// toolbar and lyrics or the queue in a panel at the side. The full player
/// takes over the window.
struct MainWindow: View {
    @Environment(AppModel.self) private var model
    @State private var query = ""
    @FocusState private var searchFocused: Bool

    var body: some View {
        @Bindable var router = model.router
        ZStack {
            // The full player replaces the library rather than covering it, so
            // nothing hidden under it takes clicks or keeps the keyboard
            if router.showsPlayer, model.player.current != nil {
                MacNowPlayingView()
                    .transition(.opacity.combined(with: .scale(scale: 1.04)))
            } else {
                library(router: router)
            }
            ReactionsOverlay()
        }
        // The sidebar shows where the user is; the toolbar holds the player
        .toolbar(removing: .title)
        .animation(.smooth(duration: 0.35), value: router.showsPlayer)
        .frame(minWidth: 900, minHeight: 600)
        .onChange(of: router.section) { router.path = [] }
        // The lyrics and colors of each track, for the side panel and the player
        .task(id: model.player.current.map { "\($0.stid)|\($0.duration > 0)" }) {
            guard let item = model.player.current else { return }
            await model.nowPlaying.load(item, model: model)
        }
        .task(id: model.player.current?.stid) {
            await model.nowPlaying.loadAccent(model.player.current?.track.coverURL(size: 300))
        }
        .onChange(of: model.player.current == nil) { _, empty in
            if empty { router.showsPlayer = false }
        }
        .onChange(of: router.searchRequest, initial: true) {
            guard let request = router.searchRequest else { return }
            router.searchRequest = nil
            query = request
            if !request.isEmpty { model.rememberSearch(request) }
        }
        .sheet(item: Bindable(model.nowPlaying).lyricCard) { request in
            LyricCardSheet(request: request)
                .frame(width: 460, height: 720)
        }
        .sheet(item: Binding { model.playlistRequest } set: { model.playlistRequest = $0 }) { request in
            PlaylistPicker(request: request)
                .frame(minWidth: 420, minHeight: 480)
        }
        .sheet(item: Binding { model.versionRequest } set: { model.versionRequest = $0 }) { track in
            NavigationStack { TrackVersionsView(track: track) }
                .frame(minWidth: 480, minHeight: 560)
        }
        .sheet(isPresented: Binding { model.showsListenTogether } set: { model.showsListenTogether = $0 }) {
            ListenTogetherView()
        }
        .sheet(item: $router.newPlaylist) { kind in
            NavigationStack {
                PlaylistCreateForm(kind: kind, initialCover: nil) { id in
                    router.newPlaylist = nil
                    // Opens the new playlist, ready for songs
                    if let playlist = await model.playlists(kind).first(where: { $0.id == id }) {
                        router.section = .playlist(kind, playlist)
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(L10n.cancel) { router.newPlaylist = nil }
                    }
                }
            }
            .frame(minWidth: 420, minHeight: 420)
        }
        .alert(
            L10n.invitetitle,
            isPresented: Binding { model.invites.first != nil } set: { _ in },
            presenting: model.invites.first
        ) { invite in
            Button(L10n.join) { model.answer(invite, accept: true) }
            Button(L10n.notnow, role: .cancel) { model.answer(invite, accept: false) }
        } message: { invite in
            Text("\(invite.from.name) \(L10n.invitebody)")
        }
        .alert(L10n.haltmusicplayer, isPresented: $router.confirmsHalt) {
            Button(L10n.cancel, role: .cancel) {}
            Button(L10n.halt, role: .destructive) { model.player.halt() }
        } message: {
            Text(L10n.haltmusicplayerbody)
        }
    }

    /// The sidebar, the picked section, the toolbar and the side panel.
    private func library(router: Router) -> some View {
        @Bindable var router = router
        return NavigationSplitView {
            Sidebar()
                .navigationSplitViewColumnWidth(min: 200, ideal: 230, max: 320)
        } detail: {
            NavigationStack(path: $router.path) {
                SectionView(section: router.section ?? .home, query: $query)
                    .navigationDestination(for: Route.self, destination: RouteView.init)
            }
            // Controls are white; teal marks what is on or selected
            .tint(.primary)
            .inspector(isPresented: inspectorShown) {
                InspectorView()
                    .inspectorColumnWidth(min: 340, ideal: 420, max: 560)
            }
        }
        .searchable(text: $query, placement: .sidebar, prompt: L10n.searchsongsartistsalbums)
        .searchFocused($searchFocused)
        .onChange(of: router.searchFocusRequests) { searchFocused = true }
        .onSubmit(of: .search) { model.rememberSearch(query) }
        .onChange(of: query) { _, query in
            if !query.isEmpty, router.section != .search {
                router.section = .search
            }
        }
        .toolbar { PlayerToolbar() }
    }

    private var inspectorShown: Binding<Bool> {
        Binding { model.router.inspector != nil } set: { shown in
            if !shown { model.router.inspector = nil }
        }
    }
}

// MARK: - Sidebar

private struct Sidebar: View {
    @Environment(AppModel.self) private var model
    @State private var online: [UserPlaylist] = []
    @State private var offline: [UserPlaylist] = []

    var body: some View {
        @Bindable var router = model.router
        // Search is the field on top; importing is in the File menu
        List(selection: $router.section) {
            Section {
                Label(L10n.home, systemImage: "house").tag(SidebarSection.home)
            }
            Section(L10n.library) {
                Label(L10n.playlists, systemImage: "music.note.list").tag(SidebarSection.allPlaylists)
                Label(L10n.favouritesongs, systemImage: "heart").tag(SidebarSection.favourites)
                Label(L10n.downloads, systemImage: "arrow.down.circle").tag(SidebarSection.downloads)
                Label(L10n.sleep, systemImage: "moon.zzz").tag(SidebarSection.sleepAlarms)
                Label(L10n.stats, systemImage: "chart.bar").tag(SidebarSection.stats)
                Label(L10n.friends, systemImage: "person.2").tag(SidebarSection.friends)
            }
            if !online.isEmpty || !offline.isEmpty {
                Section(L10n.playlists) {
                    playlistRows(.online, online)
                    playlistRows(.offline, offline)
                }
            }
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .bottom) { AccountButton() }
        .task(id: model.libraryRevision) {
            online = await model.playlists(.online)
            offline = await model.playlists(.offline)
        }
    }

    private func playlistRows(_ kind: PlaylistKind, _ playlists: [UserPlaylist]) -> some View {
        ForEach(playlists) { playlist in
            Label {
                HStack(spacing: 4) {
                    Text(playlist.title).lineLimit(1)
                    // Offline playlists live on this Mac only; downloaded ones play without the server
                    if kind == .offline || model.downloadedPlaylists.contains(playlist.id) {
                        Spacer(minLength: 0)
                        Image(systemName: "arrow.down.circle").font(.system(size: 10)).foregroundStyle(.secondary)
                    }
                }
            } icon: {
                CoverImage(data: playlist.cover).frame(width: 18, height: 18).coverShape(4)
            }
            .tag(SidebarSection.playlist(kind, playlist))
        }
    }
}

/// The user at the bottom of the sidebar, which opens their account in the
/// Settings window, and a button for the preferences.
private struct AccountButton: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openSettings) private var openSettings
    @AppStorage(MacSettingsView.tabKey) private var settingsTab = MacSettingsView.Pane.general
    @State private var profile: UserProfile?
    @State private var hovering = false

    var body: some View {
        HStack(spacing: 10) {
            Button {
                open(.profile)
            } label: {
                HStack(spacing: 10) {
                    CoverImage(profile?.picture, placeholder: "person.fill")
                        .frame(width: 30, height: 30)
                        .clipShape(.circle)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(profile?.name ?? L10n.profile)
                            .font(.system(size: 13, weight: .semibold))
                        Text(profile?.email ?? L10n.yourprofile)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    .lineLimit(1)
                    Spacer(minLength: 0)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.tappable)
            .help(L10n.profile)
            Button {
                open(.general)
            } label: {
                Image(systemName: "gearshape").font(.system(size: 15)).frame(width: 26, height: 26)
            }
            .buttonStyle(.tappable)
            .foregroundStyle(.secondary)
            .help(L10n.preferences)
        }
        .padding(8)
        .background(.primary.opacity(hovering ? 0.08 : 0), in: .rect(cornerRadius: 10))
        .onHover { hovering = $0 }
        .padding(.horizontal, 10)
        .padding(.bottom, 10)
        .task(id: model.auth.isSignedIn) {
            profile = model.auth.isSignedIn ? try? await model.auth.fetchProfile() : nil
        }
    }

    private func open(_ pane: MacSettingsView.Pane) {
        settingsTab = pane
        openSettings()
    }
}

// MARK: - Sections

private struct SectionView: View {
    let section: SidebarSection
    @Binding var query: String

    var body: some View {
        switch section {
        case .home:
            RecommendationsView().navigationTitle(L10n.home)
        case .search:
            SearchView(query: $query).navigationTitle(L10n.search)
        case .favourites: FavouritesView()
        case .downloads: DownloadsView()
        case .sleepAlarms: SleepAlarmsView()
        case .stats: StatsView()
        case .friends: FriendsView()
        case .allPlaylists: UserPlaylistsView(kind: nil)
        case .playlists(let kind): UserPlaylistsView(kind: kind)
        case .playlist(let kind, let playlist):
            UserPlaylistView(kind: kind, playlist: playlist).id(playlist.id)
        }
    }
}
