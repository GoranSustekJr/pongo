import PongoCore
import SwiftUI

/// The window as in Mac music apps: the library in the sidebar with the
/// search field on top, the picked section beside it, the player in the
/// toolbar and lyrics or the queue in a panel at the side. The full player
/// takes over the window.
struct MainWindow: View {
    @Environment(AppModel.self) private var model
    @State private var query = ""

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
        List(selection: $router.section) {
            Section {
                Label(L10n.home, systemImage: "house").tag(SidebarSection.home)
                Label(L10n.search, systemImage: "magnifyingglass").tag(SidebarSection.search)
            }
            Section(L10n.library) {
                Label(L10n.favouritesongs, systemImage: "heart").tag(SidebarSection.favourites)
                Label(L10n.offlinesongs, systemImage: "arrow.down.circle").tag(SidebarSection.downloads)
                Label(L10n.sleep, systemImage: "moon.zzz").tag(SidebarSection.sleepAlarms)
                Label(L10n.stats, systemImage: "chart.bar").tag(SidebarSection.stats)
                Label(L10n.top25, systemImage: "flame").tag(SidebarSection.topSongs)
                Label(L10n.importplaylists, systemImage: "square.and.arrow.down.on.square")
                    .tag(SidebarSection.importPlaylists)
            }
            Section(L10n.friends) {
                Label(L10n.friends, systemImage: "person.2").tag(SidebarSection.friends)
                Label(L10n.followedplaylists, systemImage: "heart.text.square").tag(SidebarSection.followedPlaylists)
                Button {
                    model.showsListenTogether = true
                } label: {
                    HStack {
                        Label(
                            L10n.listentogether,
                            systemImage: model.listening.isActive ? "person.2.wave.2.fill" : "person.2.wave.2")
                        Spacer()
                        if model.listening.isActive { LiveDot() }
                    }
                }
                .buttonStyle(.plain)
            }
            playlistSection(L10n.onlineplaylists, kind: .online, playlists: online)
            playlistSection(L10n.offlineplaylists, kind: .offline, playlists: offline)
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .bottom) { AccountButton() }
        .task(id: model.libraryRevision) {
            online = await model.playlists(.online)
            offline = await model.playlists(.offline)
        }
    }

    private func playlistSection(_ title: String, kind: PlaylistKind, playlists: [UserPlaylist]) -> some View {
        Section(title) {
            Label(L10n.playlists, systemImage: kind == .online ? "music.note.list" : "square.stack")
                .tag(SidebarSection.playlists(kind))
            ForEach(playlists) { playlist in
                Label {
                    Text(playlist.title).lineLimit(1)
                } icon: {
                    CoverImage(data: playlist.cover).frame(width: 18, height: 18).coverShape(4)
                }
                .tag(SidebarSection.playlist(kind, playlist))
            }
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
            .buttonStyle(.plain)
            .help(L10n.profile)
            Button {
                open(.general)
            } label: {
                Image(systemName: "gearshape").font(.system(size: 15)).frame(width: 26, height: 26)
            }
            .buttonStyle(.plain)
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
        case .topSongs: TopSongsView()
        case .importPlaylists: ImportPlaylistsView()
        case .friends: FriendsView()
        case .followedPlaylists: FollowedPlaylistsView()
        case .playlists(let kind): UserPlaylistsView(kind: kind)
        case .playlist(let kind, let playlist):
            UserPlaylistView(kind: kind, playlist: playlist).id(playlist.id)
        }
    }
}
