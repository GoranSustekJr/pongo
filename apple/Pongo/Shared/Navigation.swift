import Observation
import PongoCore
import SwiftUI

/// The app's tabs; settings open from the profile picture on home.
enum AppTab: Hashable {
    case home, library, search
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
    /// Online and offline playlists together, and those followed from friends.
    case allPlaylists
    case userPlaylist(PlaylistKind, UserPlaylist)
    case sleepAlarms
    case stats
    case topSongs
    case profile
    case preferences
    case about
    case importPlaylists
    case friends
    case person(String)
    case sharedPlaylist(SharedPlaylistInfo)
    case followedPlaylists
}

/// The selected tab and each tab's navigation stack.
@Observable
final class Router {
    var tab = AppTab.home
    var home: [Route] = []
    var library: [Route] = []
    var searchPath: [Route] = []
    var settings: [Route] = []
    /// Whether settings show, over the tabs on iPhone.
    var showsSettings = false
    /// Whether the sleep alarms show in a sheet of their own.
    var showsSleepAlarms = false
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
        /// Goes up each time the menu asks for the cursor in the search field.
        var searchFocusRequests = 0
        /// The kind of playlist the menu asked to create, while its form shows.
        var newPlaylist: PlaylistKind?
    #endif

    /// Shows [route] on the current tab, closing the player.
    func show(_ route: Route) {
        showsPlayer = false
        #if os(macOS)
            path.append(route)
        #else
            if showsSettings {
                settings.append(route)
                return
            }
            switch tab {
            case .home: home.append(route)
            case .library: library.append(route)
            case .search: searchPath.append(route)
            }
        #endif
    }

    /// Searches for [query] in the search tab.
    func search(for query: String) {
        searchRequest = query
        #if os(macOS)
            showsPlayer = false
            section = .search
            path = []
        #else
            showsSettings = false
            tab = .search
            searchPath = []
        #endif
    }
}

#if os(macOS)
    /// The Mac window's sidebar.
    enum SidebarSection: Hashable {
        case home, search, favourites, downloads, sleepAlarms, stats, friends, allPlaylists
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
        case .allPlaylists: UserPlaylistsView(kind: nil)
        case .userPlaylist(let kind, let playlist): UserPlaylistView(kind: kind, playlist: playlist)
        case .sleepAlarms: SleepAlarmsView()
        case .stats: StatsView()
        case .topSongs: TopSongsView()
        case .profile: ProfileView()
        case .preferences: PreferencesView()
        case .about: AboutView()
        case .importPlaylists: ImportPlaylistsView()
        case .friends: FriendsView()
        case .person(let code): PersonView(code: code)
        case .sharedPlaylist(let info): SharedPlaylistView(info: info)
        case .followedPlaylists: FollowedPlaylistsView()
        }
    }
}
