import PongoCore
import SwiftUI

/// The tracks of a catalog album or playlist, which plays them in order.
struct OnlineCollectionView: View {
    @Environment(AppModel.self) private var model
    let collectionID: String
    let title: String
    let subtitle: String
    let cover: String
    /// What Home lists under the greeting once it's played.
    var recent: RecentCollection?
    let load: () async throws -> TrackListing

    @State private var listing: TrackListing?
    @State private var failed = false

    var body: some View {
        CollectionScreen(title: title, subtitle: subtitle, coverURL: URL(string: cover), placeholder: "square.stack") {
            PlayShuffleBar(collectionID: collectionID, canShuffle: listing.map { missing($0).isEmpty } ?? false) {
                if let listing { await play(listing, index: 0, shuffle: false) }
            } shuffle: {
                if let listing { await play(listing, index: nil, shuffle: true) }
            }
        } content: {
            if let listing {
                TrackList(tracks: listing.tracks, collectionID: collectionID, missing: Set(missing(listing))) { index in
                    Task {
                        await model.player.playCollectionTrack(
                            collectionID: collectionID, stid: listing.tracks[index].id, index: index
                        ) { await play(listing, index: index, shuffle: false) }
                    }
                }
            } else if failed {
                EmptyMessage(systemImage: "wifi.exclamationmark", title: L10n.error).padding(.top, 30)
            } else {
                ProgressView().controlSize(.large).padding(.top, 40).frame(maxWidth: .infinity)
            }
        } actions: {
            if let listing { CollectionActions(tracks: listing.tracks) }
        }
        .task {
            guard listing == nil else { return }
            do { listing = try await load() } catch { failed = true }
        }
    }

    private func durations(_ listing: TrackListing) -> [String: Double] {
        listing.availability.durations.merging(model.player.fetchedDurations) { first, _ in first }
    }

    private func missing(_ listing: TrackListing) -> [String] {
        let known = durations(listing)
        return listing.tracks.map(\.id).filter { known[$0] == nil }
    }

    private func play(_ listing: TrackListing, index: Int?, shuffle: Bool) async {
        if let recent { model.recents.add(recent) }
        await model.player.playOnline(
            collectionID, listing.tracks, durations: durations(listing), index: index, shuffle: shuffle)
    }
}

/// The menu of a catalog collection: saving its tracks as a playlist, or
/// downloading its songs to the device, and removing them again.
struct CollectionActions: View {
    @Environment(AppModel.self) private var model
    let tracks: [Track]

    var body: some View {
        Button(L10n.addtoplaylist, systemImage: "music.note.list") {
            Task { await model.addToPlaylist(tracks, creating: true) }
        }
        if model.isDownloaded(tracks) {
            Button(L10n.removedownload, systemImage: "arrow.down.circle.dotted", role: .destructive) {
                Task { await model.removeDownloads(tracks.map(\.id)) }
            }
        } else {
            Button(L10n.download, systemImage: "arrow.down.circle") {
                Task { await model.downloadSongs(tracks) }
            }
        }
    }
}

struct AlbumView: View {
    @Environment(AppModel.self) private var model
    let album: Album

    var body: some View {
        OnlineCollectionView(
            collectionID: "online.album:\(album.id)", title: album.name,
            subtitle: album.artists.joined(separator: ", "), cover: album.image, recent: .album(album)
        ) { try await model.catalog.albumTracks(album) }
    }
}

struct CatalogPlaylistView: View {
    @Environment(AppModel.self) private var model
    let playlist: Playlist

    var body: some View {
        OnlineCollectionView(
            collectionID: "online.playlist:\(playlist.id)", title: playlist.name,
            subtitle: playlist.description ?? "", cover: playlist.image, recent: .playlist(playlist)
        ) { try await model.catalog.playlistTracks(playlist.id) }
    }
}

/// An artist's top tracks and releases.
struct ArtistView: View {
    @Environment(AppModel.self) private var model
    let artist: Artist

    @State private var details: ArtistDetails?
    @State private var availability = TrackAvailability()
    @State private var failed = false

    private var collectionID: String { "online.artist:\(artist.id)" }
    private var topTracks: [Track] { Array(details?.tracks.prefix(10) ?? []) }

    var body: some View {
        CollectionScreen(title: artist.name, coverURL: URL(string: artist.image), placeholder: "music.microphone") {
            PlayShuffleBar(collectionID: collectionID, canShuffle: !topTracks.isEmpty && missing.isEmpty) {
                await play(index: 0, shuffle: false)
            } shuffle: {
                await play(index: nil, shuffle: true)
            }
        } content: {
            if let details {
                VStack(alignment: .leading, spacing: 30) {
                    if !topTracks.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            SectionTitle(L10n.toptentracks)
                            TrackList(tracks: topTracks, collectionID: collectionID, missing: Set(missing)) { index in
                                Task {
                                    await model.player.playCollectionTrack(
                                        collectionID: collectionID, stid: topTracks[index].id, index: index
                                    ) { await play(index: index, shuffle: false) }
                                }
                            }
                        }
                    }
                    albumShelf(L10n.albums, details.albums)
                    albumShelf(L10n.singlesandcompilations, details.otherReleases)
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
            guard details == nil else { return }
            do {
                let found = try await model.catalog.artist(artist.id, market: model.settings.settings.market)
                details = found
                try? await model.database.addViewedArtist(artist.id)
                let ids = Array(found.tracks.prefix(10)).map(\.id)
                if !ids.isEmpty, let known = try? await model.catalog.availability(ids) { availability = known }
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
        await model.player.playOnline(collectionID, topTracks, durations: durations, index: index, shuffle: shuffle)
    }

    @ViewBuilder private func albumShelf(_ title: String, _ albums: [Album]) -> some View {
        if !albums.isEmpty {
            Shelf(title: title, items: albums) { album in
                NavigationLink(value: Route.album(album)) {
                    Tile(image: URL(string: album.image), title: album.name, subtitle: album.type.capitalized,
                         placeholder: "square.stack")
                }
            }
        }
    }
}
