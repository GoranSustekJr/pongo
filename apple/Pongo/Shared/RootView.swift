import Observation
import PongoCore
import SwiftUI

/// The app's tabs.
enum AppTab: Hashable {
    case home, library, settings
}

/// A screen pushed onto a tab's navigation stack.
enum Route: Hashable {
    case album(Album)
    case artist(Artist)
    case playlist(Playlist)
    case genre(BrowseCategory)
    case favourites
    case downloads
    case userPlaylists(PlaylistKind)
    case userPlaylist(PlaylistKind, UserPlaylist)
    case sleepAlarms
    case profile
    case preferences
    case about
}

/// The selected tab and each tab's navigation stack.
@Observable
final class Router {
    var tab = AppTab.home
    var home: [Route] = []
    var library: [Route] = []
    var settings: [Route] = []
    var showsPlayer = false
    /// Whether the mini player asked to confirm halting the player.
    var confirmsHalt = false
    /// A search another screen asked for, such as a genre on the home tab.
    var searchRequest: String?

    /// Shows [route] on the current tab, closing the player.
    func show(_ route: Route) {
        showsPlayer = false
        switch tab {
        case .home: home.append(route)
        case .library: library.append(route)
        case .settings: settings.append(route)
        }
    }

    /// Searches for [query] in the search bar at the top of home.
    func search(for query: String) {
        searchRequest = query
        tab = .home
        home = []
    }
}

struct RouteView: View {
    let route: Route

    var body: some View {
        switch route {
        case .album(let album): AlbumView(album: album)
        case .artist(let artist): ArtistView(artist: artist)
        case .playlist(let playlist): CatalogPlaylistView(playlist: playlist)
        case .genre(let genre): GenreView(genre: genre)
        case .favourites: FavouritesView()
        case .downloads: DownloadsView()
        case .userPlaylists(let kind): UserPlaylistsView(kind: kind)
        case .userPlaylist(let kind, let playlist): UserPlaylistView(kind: kind, playlist: playlist)
        case .sleepAlarms: SleepAlarmsView()
        case .profile: ProfileView()
        case .preferences: PreferencesView()
        case .about: AboutView()
        }
    }
}

struct RootView: View {
    @Environment(AppModel.self) private var model
    @State private var toasts = ToastWindow()

    var body: some View {
        let settings = model.settings.settings
        Group {
            if model.auth.isSignedIn || isDemo {
                MainTabView()
            } else {
                SignInView()
            }
        }
        .id(settings.locale)
        .environment(\.locale, Locale(identifier: settings.locale))
        .preferredColorScheme(settings.darkMode ? .dark : .light)
        .tint(.pongoTeal)
        .environment(\.usesLiquidGlass, settings.useLiquidGlass)
        // A tap on the live lyrics
        .onOpenURL { url in
            guard url == PongoLinks.lyrics, model.player.current != nil else { return }
            model.nowPlaying.lyricsOn = true
            model.router.showsPlayer = true
        }
        .onAppear {
            toasts.install(model: model)
            #if DEBUG
                if DemoMode.isOn { DemoMode.open(model) }
            #endif
        }
        .task(id: model.auth.isSignedIn) { await model.sessionChanged() }
        .onChange(of: model.settings.settings) { model.applyPreferences() }
        .onChange(of: model.sync.revision) { Task { await model.reloadLibraryIDs() } }
        .onChange(of: model.auth.disabledCount) {
            model.messages.show(L10n.accountdisabled, systemImage: "person.crop.circle.badge.xmark", isError: true)
        }
    }
}

private var isDemo: Bool {
    #if DEBUG
        DemoMode.isOn
    #else
        false
    #endif
}

struct MainTabView: View {
    @Environment(AppModel.self) private var model
    @Namespace private var playerTransition

    var body: some View {
        @Bindable var router = model.router
        TabView(selection: $router.tab) {
            Tab(L10n.home, systemImage: "house.fill", value: AppTab.home) {
                NavigationStack(path: $router.home) {
                    HomeView().navigationDestination(for: Route.self, destination: RouteView.init)
                }
                // Controls are white; teal marks what is on or selected
                .tint(.primary)
            }
            Tab(L10n.library, systemImage: "square.stack.fill", value: AppTab.library) {
                NavigationStack(path: $router.library) {
                    LibraryView().navigationDestination(for: Route.self, destination: RouteView.init)
                }
                // Controls are white; teal marks what is on or selected
                .tint(.primary)
            }
            Tab(L10n.settings, systemImage: "gearshape.fill", value: AppTab.settings) {
                NavigationStack(path: $router.settings) {
                    SettingsView().navigationDestination(for: Route.self, destination: RouteView.init)
                }
                // Controls are white; teal marks what is on or selected
                .tint(.primary)
            }
        }
        // Lists run behind the glass bars without being blurred under them
        .scrollEdgeEffectHidden(true, for: .all)
        .tabBarMinimizeBehavior(.onScrollDown)
        #if DEBUG
            .defaultScrollAnchor(DemoMode.scrolled ? .bottom : DemoMode.middle ? .center : nil)
        #endif
        .tabViewBottomAccessory(isEnabled: model.player.current != nil) {
            MiniPlayer()
                .matchedTransitionSource(id: "player", in: playerTransition)
        }
        .fullScreenCover(isPresented: $router.showsPlayer) {
            NowPlayingView()
                .navigationTransition(.zoom(sourceID: "player", in: playerTransition))
        }
        // The player shows the picker itself while it's open
        .sheet(
            item: Binding {
                router.showsPlayer ? nil : model.playlistRequest
            } set: { model.playlistRequest = $0 }
        ) { request in
            PlaylistPicker(request: request)
        }
        .alert(L10n.haltmusicplayer, isPresented: $router.confirmsHalt) {
            Button(L10n.cancel, role: .cancel) {}
            Button(L10n.halt, role: .destructive) { model.player.halt() }
        } message: {
            Text(L10n.haltmusicplayerbody)
        }
    }
}
