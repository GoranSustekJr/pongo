import Observation
import PongoCore
import SwiftUI

// MARK: - Recently played collections

/// An album, playlist or genre the user played, for the shortcuts on Home.
enum RecentCollection: Codable, Hashable, Identifiable {
    case album(Album)
    case playlist(Playlist)
    case genre(BrowseCategory)

    var id: String {
        switch self {
        case .album(let album): "album:\(album.id)"
        case .playlist(let playlist): "playlist:\(playlist.id)"
        case .genre(let genre): "genre:\(genre.id)"
        }
    }

    var title: String {
        switch self {
        case .album(let album): album.name
        case .playlist(let playlist): playlist.name
        case .genre(let genre): genre.name
        }
    }

    var image: URL? {
        switch self {
        case .album(let album): URL(string: album.image)
        case .playlist(let playlist): URL(string: playlist.image)
        case .genre(let genre): URL(string: genre.iconURL)
        }
    }

    var route: Route {
        switch self {
        case .album(let album): .album(album)
        case .playlist(let playlist): .playlist(playlist)
        case .genre(let genre): .genre(genre)
        }
    }
}

/// The collections played last, newest first, kept on the device.
@Observable
final class RecentCollections {
    private(set) var items: [RecentCollection] = []
    private let key = "pongo.recentCollections"
    private let limit = 8

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
            let saved = try? JSONDecoder().decode([RecentCollection].self, from: data)
        {
            items = saved
        }
    }

    func add(_ collection: RecentCollection) {
        items.removeAll { $0.id == collection.id }
        items.insert(collection, at: 0)
        items = Array(items.prefix(limit))
        if let data = try? JSONEncoder().encode(items) { UserDefaults.standard.set(data, forKey: key) }
    }
}

// MARK: - The saved home page

/// The last home page, kept so Home shows at once, also offline, while a
/// fresh one loads.
enum HomeCache {
    private static let url = URL.cachesDirectory.appending(path: "home-feed.json")

    static func load() -> HomeFeed? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(HomeFeed.self, from: data)
    }

    static func save(_ feed: HomeFeed) {
        guard let data = try? JSONEncoder().encode(feed) else { return }
        try? data.write(to: url, options: .atomic)
    }
}

// MARK: - Quick picks

/// A shortcut in the grid under the greeting: a cover or icon and a title.
struct QuickTile<Artwork: View>: View {
    let title: String
    @ViewBuilder var artwork: Artwork

    var body: some View {
        HStack(spacing: 10) {
            artwork.frame(width: 56, height: 56).clipped()
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.trailing, 6)
        .frame(height: 56)
        .background(.white.opacity(0.08))
        .coverShape(12)
        .contentShape(.rect)
    }
}

/// An icon on a gradient, for the favourites and downloads shortcuts.
struct GradientIcon: View {
    let systemImage: String
    let colors: [Color]

    var body: some View {
        LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
            .overlay {
                Image(systemName: systemImage)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
            }
    }
}

// MARK: - Mixes

/// A mix made from what the user plays: songs to start from, which the
/// player follows with similar ones.
struct HomeMix: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let seeds: [Track]
    /// Up to four covers for the card.
    let covers: [URL]

    var collectionID: String { "mix.\(id)" }

    /// A mix for each artist the user played most lately, and one of their
    /// favourites.
    static func make(history: [Track], favourites: [Track]) -> [HomeMix] {
        var mixes: [HomeMix] = []
        if favourites.count >= 3 {
            let seeds = Array(favourites.shuffled().prefix(5))
            mixes.append(
                HomeMix(
                    id: "favourites", title: L10n.favouritesmix, subtitle: L10n.favouritesmixdescription,
                    seeds: seeds, covers: covers(seeds)))
        }
        // Artists by how many of the recent tracks are theirs, the most recent first on ties
        var counts: [String: (count: Int, order: Int, name: String)] = [:]
        for (order, track) in history.enumerated() {
            guard let artist = track.artists.first, let name = artist.name else { continue }
            let known = counts[artist.id]
            counts[artist.id] = ((known?.count ?? 0) + 1, known?.order ?? order, name)
        }
        let artists = counts.sorted { ($0.value.count, -$0.value.order) > ($1.value.count, -$1.value.order) }
        for (number, artist) in artists.prefix(3).enumerated() {
            let seeds = Array(history.filter { $0.artists.first?.id == artist.key }.prefix(4))
            mixes.append(
                HomeMix(
                    id: "daily:\(artist.key)", title: "\(L10n.dailymix) \(number + 1)",
                    subtitle: "\(artist.value.name) \(L10n.andsimilarartists)", seeds: seeds, covers: covers(seeds)))
        }
        return mixes
    }

    private static func covers(_ tracks: [Track]) -> [URL] {
        var seen = Set<URL>()
        return tracks.compactMap { $0.coverURL(size: 300) }.filter { seen.insert($0).inserted }.prefix(4).map { $0 }
    }
}

/// A mix as a card: a collage of its covers with its name on it.
struct MixCard: View {
    @Environment(AppModel.self) private var model
    let mix: HomeMix

    var body: some View {
        let playing = model.player.current?.collectionID == mix.collectionID
        Button {
            if playing {
                model.player.togglePlayback()
            } else {
                Haptics.tap()
                Task { await model.player.playMix(mix.collectionID, seeds: mix.seeds) }
            }
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                collage
                    .frame(width: 160, height: 160)
                    .overlay {
                        LinearGradient(colors: [.clear, .black.opacity(0.65)], startPoint: .center, endPoint: .bottom)
                    }
                    .overlay(alignment: .bottomLeading) {
                        Text(mix.title)
                            .font(.system(size: 17, weight: .heavy))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                            .padding(10)
                    }
                    .overlay(alignment: .topTrailing) {
                        Image(systemName: playing && model.player.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.black)
                            .frame(width: 32, height: 32)
                            .background(.white, in: .circle)
                            .contentTransition(.symbolEffect(.replace))
                            .padding(8)
                    }
                    .coverShape(14)
                Text(mix.subtitle)
                    .font(.system(size: 12))
                    .opacity(0.69)
                    .lineLimit(2)
                    .frame(width: 160, alignment: .leading)
            }
            .contentShape(.rect)
        }
    }

    @ViewBuilder private var collage: some View {
        let covers = mix.covers
        if covers.count >= 4 {
            Grid(horizontalSpacing: 0, verticalSpacing: 0) {
                GridRow {
                    CoverImage(url: covers[0])
                    CoverImage(url: covers[1])
                }
                GridRow {
                    CoverImage(url: covers[2])
                    CoverImage(url: covers[3])
                }
            }
        } else {
            CoverImage(url: covers.first, placeholder: "sparkles")
        }
    }
}

// MARK: - Charts

/// The top tracks as numbered rows, four to a column, the columns side by
/// side, with a button that plays them all.
struct ChartSection: View {
    @Environment(AppModel.self) private var model
    let tracks: [Track]

    static let collectionID = "online.charts"

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                SectionTitle(L10n.toptracks)
                Button {
                    Haptics.tap()
                    Task { await playAll() }
                } label: {
                    Label(L10n.play, systemImage: "play.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .padding(.horizontal, 14)
                        .frame(height: 32)
                        .background(.white.opacity(0.12), in: .capsule)
                }
                .buttonStyle(.press)
                .padding(.trailing, 20)
            }
            ScrollView(.horizontal) {
                LazyHStack(alignment: .top, spacing: 12) {
                    ForEach(Array(stride(from: 0, to: tracks.count, by: 4)), id: \.self) { start in
                        VStack(spacing: 6) {
                            ForEach(start..<min(start + 4, tracks.count), id: \.self) { index in
                                row(index)
                            }
                        }
                        .containerRelativeFrame(.horizontal) { width, _ in width - 60 }
                    }
                }
                .scrollTargetLayout()
                .padding(.horizontal, 17.5)
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned)
        }
    }

    private func row(_ index: Int) -> some View {
        let track = tracks[index]
        let isCurrent = model.player.current?.stid == track.id && model.player.current?.collectionID == Self.collectionID
        return Button {
            Task { await model.player.playSingle(track, collectionID: Self.collectionID) }
        } label: {
            HStack(spacing: 12) {
                Text("\(index + 1)")
                    .font(.system(size: 17, weight: .heavy))
                    .monospacedDigit()
                    .frame(width: 26)
                CoverImage(url: track.coverURL(size: 150)).frame(width: 50, height: 50).coverShape(8)
                VStack(alignment: .leading, spacing: 2) {
                    Text(track.name).font(.system(size: 15, weight: .medium)).lineLimit(1)
                    Text(track.artistNames).font(.system(size: 13)).opacity(0.69).lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                TrackStatus(stid: track.id, isCurrent: isCurrent)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.press)
        .contextMenu { TrackMenu(track: track, collectionID: Self.collectionID) }
    }

    private func playAll() async {
        let known = (try? await model.catalog.availability(tracks.map(\.id)))?.durations ?? [:]
        await model.player.playOnline(Self.collectionID, tracks, durations: known)
    }
}

// MARK: - New releases

/// A big album card whose caption is tinted with the cover's colors.
struct ReleaseCard: View {
    let album: Album
    @State private var tint: PlatformImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CoverImage(album.image, placeholder: "square.stack").frame(width: 190, height: 190)
            VStack(alignment: .leading, spacing: 2) {
                Text(album.name).font(.system(size: 15, weight: .semibold)).lineLimit(1)
                Text(album.artists.joined(separator: ", ")).font(.system(size: 12)).opacity(0.75).lineLimit(1)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .frame(width: 190, height: 58, alignment: .leading)
            .background {
                // The caption's frame, which the blurred cover fills without spilling over
                Color(white: 0.18)
                    .overlay {
                        if let tint {
                            Image(platformImage: tint).resizable().scaledToFill().transition(.opacity)
                        }
                    }
                    .overlay { Color.black.opacity(0.25) }
                    .clipped()
            }
        }
        .coverShape(16)
        .animation(.easeInOut(duration: 0.4), value: tint)
        .contentShape(.rect)
        .task(id: album.image) {
            if let url = URL(string: album.image) { tint = await ImagePipeline.shared.blurred(for: url) }
        }
    }
}

// MARK: - Genre page

/// A genre's own page: its top tracks, albums, artists and playlists.
struct GenreView: View {
    @Environment(AppModel.self) private var model
    let genre: BrowseCategory

    @State private var page: GenrePage?
    @State private var availability = TrackAvailability()
    @State private var failed = false

    private var collectionID: String { "online.genre:\(genre.id)" }
    private var topTracks: [Track] { page?.tracks ?? [] }

    var body: some View {
        CollectionScreen(title: genre.name, coverURL: URL(string: genre.iconURL), placeholder: "music.quarternote.3") {
            PlayShuffleBar(collectionID: collectionID, canShuffle: !topTracks.isEmpty && missing.isEmpty) {
                await play(index: 0, shuffle: false)
            } shuffle: {
                await play(index: nil, shuffle: true)
            }
        } content: {
            if let page {
                VStack(alignment: .leading, spacing: 30) {
                    if !page.tracks.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            SectionTitle(L10n.toptracks)
                            TrackList(tracks: Array(page.tracks.prefix(10)), collectionID: collectionID, missing: Set(missing)) {
                                index in
                                Task {
                                    await model.player.playCollectionTrack(
                                        collectionID: collectionID, stid: topTracks[index].id, index: index
                                    ) { await play(index: index, shuffle: false) }
                                }
                            }
                        }
                    }
                    if !page.albums.isEmpty {
                        Shelf(title: L10n.albums, items: page.albums) { album in
                            NavigationLink(value: Route.album(album)) { ReleaseCard(album: album) }
                        }
                    }
                    if !page.artists.isEmpty {
                        Shelf(title: L10n.popularartists, items: page.artists) { artist in
                            NavigationLink(value: Route.artist(artist)) {
                                Tile(image: URL(string: artist.image), title: artist.name, circle: true,
                                     placeholder: "music.microphone")
                            }
                        }
                    }
                    if !page.playlists.isEmpty {
                        Shelf(title: L10n.featuredplaylists, items: page.playlists) { playlist in
                            NavigationLink(value: Route.playlist(playlist)) {
                                Tile(image: URL(string: playlist.image), title: playlist.name, placeholder: "music.note.list")
                            }
                        }
                    }
                }
            } else if failed {
                EmptyMessage(systemImage: "wifi.exclamationmark", title: L10n.error).padding(.top, 30)
            } else {
                ProgressView().controlSize(.large).padding(.top, 40).frame(maxWidth: .infinity)
            }
        } actions: {
            if !topTracks.isEmpty { CollectionActions(tracks: topTracks) }
        }
        .task {
            guard page == nil else { return }
            do {
                let found = try await model.catalog.genre(genre.id)
                page = found
                if !found.tracks.isEmpty, let known = try? await model.catalog.availability(found.tracks.map(\.id)) {
                    availability = known
                }
            } catch {
                failed = true
            }
        }
    }

    private var durations: [String: Double] {
        availability.durations.merging(model.player.fetchedDurations) { first, _ in first }
    }

    private var missing: [String] { topTracks.map(\.id).filter { durations[$0] == nil } }

    private func play(index: Int?, shuffle: Bool) async {
        model.recents.add(.genre(page?.genre ?? genre))
        await model.player.playOnline(collectionID, topTracks, durations: durations, index: index, shuffle: shuffle)
    }
}
