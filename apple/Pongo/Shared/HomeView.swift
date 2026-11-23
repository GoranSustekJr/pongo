import PongoCore
import SwiftUI

/// The first tab, as in the Flutter app: the search bar on top, and the
/// recommendations under it until the user searches.
struct HomeView: View {
    @Environment(AppModel.self) private var model
    @State private var query = ""
    @State private var searchActive = false

    var body: some View {
        let showsSearch = searchActive || !query.isEmpty
        RecommendationsView()
            .overlay {
                if showsSearch {
                    SearchView(query: $query).transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: showsSearch)
            #if os(iOS)
                .searchable(
                    text: $query, isPresented: $searchActive, placement: .navigationBarDrawer(displayMode: .always),
                    prompt: L10n.searchsongsartistsalbums
                )
            #endif
            .onSubmit(of: .search) { model.rememberSearch(query) }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(removing: .title)
            .onChange(of: model.router.searchRequest, initial: true) {
                guard let request = model.router.searchRequest else { return }
                model.router.searchRequest = nil
                query = request
                searchActive = true
                model.rememberSearch(request)
            }
    }
}

/// Recommendations from the play history and the charts: shortcuts under
/// the greeting, mixes, the recent tracks, new releases, the charts and the
/// genres. The last page shows at once while a fresh one loads.
struct RecommendationsView: View {
    @Environment(AppModel.self) private var model
    @State private var feed: HomeFeed?
    @State private var mixes: [HomeMix] = []
    @State private var moodMixes: [MoodMix] = []
    @State private var failed = false

    /// Tracks home plays, as the Flutter app names them.
    static let collectionID = "recommended.single"
    /// How many shortcuts the grid under the greeting shows.
    private let quickPickCount = 6

    var body: some View {
        let settings = model.settings.settings
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 30) {
                if !settings.enableHistory && !settings.enableCategories {
                    Text(L10n.recommendationsdisabled)
                        .font(.system(size: 17.5, weight: .semibold))
                        .multilineTextAlignment(.center)
                        .padding(30)
                        .frame(maxWidth: .infinity, minHeight: 400)
                } else if let feed {
                    content(feed)
                } else if failed {
                    VStack(spacing: 16) {
                        EmptyMessage(systemImage: "wifi.exclamationmark", title: L10n.error)
                        Button(L10n.continuee) { Task { await load() } }.buttonStyle(.glass)
                    }
                    .frame(minHeight: 400)
                } else {
                    ProgressView().controlSize(.large).frame(maxWidth: .infinity, minHeight: 400)
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 30)
        }
        .scrollIndicators(.hidden)
        .background { AppBackground() }
        .refreshable { await load() }
        .task {
            guard feed == nil else { return }
            if let saved = HomeCache.load() {
                feed = saved
                await makeMixes(saved)
            }
            await load()
        }
    }

    @ViewBuilder private func content(_ feed: HomeFeed) -> some View {
        let history = feed.history
        // The favourites and downloads only when there are any
        let hasFavourites = !model.favouriteIDs.isEmpty
        let hasDownloads = !model.downloadedIDs.isEmpty
        let shortcuts = (hasFavourites ? 1 : 0) + (hasDownloads ? 1 : 0)
        let collections = Array(model.recents.items.prefix(quickPickCount - shortcuts))
        // Recent tracks fill the grid when few collections were played
        let quickTracks = Array(history.prefix(quickPickCount - shortcuts - collections.count))
        let lastListened = Array(history.dropFirst(quickTracks.count))
        VStack(alignment: .leading, spacing: 14) {
            Text(L10n.greeting)
                .font(.system(size: 32, weight: .heavy))
                .tracking(-0.8)
                .padding(.horizontal, 20)
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                if hasFavourites {
                    NavigationLink(value: Route.favourites) {
                        QuickTile(title: L10n.favouritesongs) {
                            GradientIcon(systemImage: "heart.fill", colors: [Color.pongoTeal, .indigo])
                        }
                    }
                }
                if hasDownloads {
                    NavigationLink(value: Route.downloads) {
                        QuickTile(title: L10n.offlinesongs) {
                            GradientIcon(systemImage: "arrow.down.circle.fill", colors: [.orange, .pink])
                        }
                    }
                }
                ForEach(collections) { collection in
                    NavigationLink(value: collection.route) {
                        QuickTile(title: collection.title) { CoverImage(url: collection.image) }
                    }
                }
                ForEach(quickTracks) { track in QuickPick(track: track) }
            }
            .buttonStyle(.press)
            .padding(.horizontal, 15)
        }
        if !mixes.isEmpty {
            Shelf(title: L10n.madeforyou, items: mixes) { mix in MixCard(mix: mix) }
        }
        if !moodMixes.isEmpty {
            Shelf(title: L10n.yourmoods, items: moodMixes) { mix in MoodCard(mix: mix) }
        }
        if !lastListened.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                SectionTitle(L10n.lastlistenedto)
                trackRow(Array(lastListened.prefix(25)))
                if lastListened.count > 25 { trackRow(Array(lastListened.dropFirst(25))) }
            }
        }
        if !feed.newReleases.isEmpty {
            Shelf(title: L10n.newreleases, items: feed.newReleases) { album in
                NavigationLink(value: Route.album(album)) { ReleaseCard(album: album) }
            }
        }
        if !feed.topTracks.isEmpty { ChartSection(tracks: Array(feed.topTracks.prefix(25))) }
        if !feed.topArtists.isEmpty {
            Shelf(title: L10n.popularartists, items: feed.topArtists) { artist in
                NavigationLink(value: Route.artist(artist)) {
                    Tile(image: URL(string: artist.image), title: artist.name, circle: true, placeholder: "music.microphone")
                }
            }
        }
        if !feed.topPlaylists.isEmpty {
            Shelf(title: L10n.featuredplaylists, items: feed.topPlaylists) { playlist in
                NavigationLink(value: Route.playlist(playlist)) {
                    Tile(image: URL(string: playlist.image), title: playlist.name, placeholder: "music.note.list")
                }
            }
        }
        if !feed.categories.isEmpty { genres(feed.categories) }
    }

    /// A sideways row of track tiles; a tap plays one and holding shows its
    /// menu.
    private func trackRow(_ tracks: [Track]) -> some View {
        ScrollView(.horizontal) {
            LazyHStack(alignment: .top, spacing: 15) {
                ForEach(tracks) { track in
                    Button {
                        Task { await model.player.playSingle(track, collectionID: Self.collectionID) }
                    } label: {
                        Tile(image: track.coverURL(size: 300), title: track.name, subtitle: track.artistNames)
                            .overlay(alignment: .topTrailing) {
                                TrackStatus(stid: track.id, isCurrent: isCurrent(track))
                                    .foregroundStyle(.white)
                                    .shadow(radius: 4)
                                    .padding(8)
                            }
                    }
                    .contextMenu { TrackMenu(track: track, collectionID: Self.collectionID) }
                }
            }
            .scrollTargetLayout()
            .padding(.horizontal, 17.5)
        }
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(.viewAligned)
        .buttonStyle(.press)
    }

    private func isCurrent(_ track: Track) -> Bool {
        model.player.current?.stid == track.id && model.player.current?.collectionID == Self.collectionID
    }

    private func genres(_ categories: [BrowseCategory]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(L10n.genres)
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(categories) { category in
                    NavigationLink(value: Route.genre(category)) {
                        Color.clear
                            .aspectRatio(1.5, contentMode: .fit)
                            .overlay { CoverImage(category.iconURL, placeholder: "music.quarternote.3") }
                            .overlay {
                                LinearGradient(
                                    colors: [.clear, .black.opacity(0.6)], startPoint: .center, endPoint: .bottom)
                            }
                            .overlay(alignment: .bottomLeading) {
                                Text(category.name)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .lineLimit(2)
                                    .padding(10)
                            }
                            .coverShape(14)
                    }
                    .buttonStyle(.press)
                }
            }
            .padding(.horizontal, 15)
        }
    }

    private func load() async {
        let settings = model.settings.settings
        guard settings.enableHistory || settings.enableCategories else { return }
        do {
            let fresh = try await model.catalog.homeFeed(
                history: (try? await model.database.playedTracks(limit: 50)) ?? [], market: settings.market,
                locale: settings.locale, categoryCount: settings.categoryCount,
                includeHistory: settings.enableHistory, includeCategories: settings.enableCategories)
            withAnimation(.easeInOut(duration: 0.3)) { feed = fresh }
            failed = false
            HomeCache.save(fresh)
            await makeMixes(fresh)
        } catch {
            failed = feed == nil
        }
    }

    /// Mixes from the recent tracks and the favourites, which stay as they
    /// are once made, so they don't change under the user's finger.
    private func makeMixes(_ feed: HomeFeed) async {
        guard mixes.isEmpty, model.settings.settings.enableHistory else { return }
        let favourites = ((try? await model.database.favourites()) ?? []).map { favourite in
            var track = favourite.track
            // Some favourites keep their cover apart from the album
            if track.album?.images.isEmpty ?? true, let image = favourite.image, !image.isEmpty {
                track.album = AlbumRef(
                    id: track.album?.id ?? "", name: track.album?.name ?? "", images: [ImageRef(url: image)])
            }
            return track
        }
        mixes = HomeMix.make(history: feed.history, favourites: favourites)
        await makeMoodMixes(feed.history + favourites)
    }

    /// Mixes of the moods of the user's songs, as the server heard them, then
    /// named by the on-device model where it can.
    private func makeMoodMixes(_ tracks: [Track]) async {
        let stids = Array(Set(tracks.map(\.id)))
        var moods = (try? await model.catalog.moods(stids)) ?? [:]
        #if DEBUG
            if DemoMode.isOn { moods = DemoMode.moods(for: tracks) }
        #endif
        let artists = Array(Set(tracks.compactMap { $0.artists.first?.id }.filter { !$0.isEmpty }))
        let scenes = try? await model.catalog.artistGroups(artists)
        let made = MoodMix.make(tracks: tracks, moods: moods, scenes: scenes)
        withAnimation(.easeInOut(duration: 0.3)) { moodMixes = made }
        let names = await MoodNamer.names(for: made, locale: model.settings.settings.locale)
        guard !names.isEmpty else { return }
        for index in moodMixes.indices {
            moodMixes[index].name = names[moodMixes[index].id]
        }
    }
}

/// A recent track as a shortcut under the greeting.
private struct QuickPick: View {
    @Environment(AppModel.self) private var model
    let track: Track

    var body: some View {
        let collectionID = RecommendationsView.collectionID
        let isCurrent = model.player.current?.stid == track.id && model.player.current?.collectionID == collectionID
        Button {
            Task { await model.player.playSingle(track, collectionID: collectionID) }
        } label: {
            QuickTile(title: track.name) { CoverImage(url: track.coverURL(size: 150)) }
                .overlay(alignment: .trailing) {
                    TrackStatus(stid: track.id, isCurrent: isCurrent).padding(.trailing, 8)
                }
        }
        .buttonStyle(.press)
        .contextMenu { TrackMenu(track: track, collectionID: collectionID) }
    }
}
