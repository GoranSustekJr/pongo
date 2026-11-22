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
    case stats
    case topSongs
    case profile
    case preferences
    case about
    case importPlaylists
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

    #if os(macOS)
        /// The section picked in the sidebar.
        var section: SidebarSection? = .home
        /// The screens opened in the section, on top of it.
        var path: [Route] = []
        /// What the panel beside the content shows, if it's open.
        var inspector: InspectorPane?
    #endif

    /// Shows [route] on the current tab, closing the player.
    func show(_ route: Route) {
        showsPlayer = false
        #if os(macOS)
            path.append(route)
        #else
            switch tab {
            case .home: home.append(route)
            case .library: library.append(route)
            case .settings: settings.append(route)
            }
        #endif
    }

    /// Searches for [query] in the search bar at the top of home.
    func search(for query: String) {
        searchRequest = query
        #if os(macOS)
            showsPlayer = false
            section = .search
            path = []
        #else
            tab = .home
            home = []
        #endif
    }
}

#if os(macOS)
    /// The Mac window's sidebar.
    enum SidebarSection: Hashable {
        case home, search, favourites, downloads, sleepAlarms, stats, topSongs, importPlaylists
        case playlists(PlaylistKind)
        case playlist(PlaylistKind, UserPlaylist)
    }

    /// The panel at the window's side.
    enum InspectorPane: Hashable {
        case lyrics, queue
    }
#endif

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
        case .stats: StatsView()
        case .topSongs: TopSongsView()
        case .profile: ProfileView()
        case .preferences: PreferencesView()
        case .about: AboutView()
        case .importPlaylists: ImportPlaylistsView()
        }
    }
}
