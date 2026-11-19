import PongoCore
import SwiftUI

/// What the search bar on home shows: recent searches until the user types,
/// then artists, albums, tracks and playlists, as in the Flutter app.
struct SearchView: View {
    @Environment(AppModel.self) private var model
    @Binding var query: String
    @State private var results: SearchResults?
    @State private var searching = false
    @State private var history: [String] = []

    /// Tracks search plays, as the Flutter app names them.
    static let collectionID = "search.single"

    var body: some View {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                if trimmed.isEmpty {
                    historyList
                } else if let results {
                    resultList(results)
                } else if searching {
                    ProgressView().controlSize(.large).padding(.top, 80).frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 40)
            .buttonStyle(.row)
        }
        .scrollDismissesKeyboard(.immediately)
        .scrollIndicators(.hidden)
        .background { AppBackground() }
        .task(id: trimmed) { await search(trimmed) }
        .task(id: model.libraryRevision) { history = (try? await model.database.searches()) ?? [] }
    }

    // MARK: - History

    @ViewBuilder private var historyList: some View {
        if !history.isEmpty {
            HStack {
                Text(L10n.recentsearches).font(.system(size: 20, weight: .bold))
                Spacer()
                Button(L10n.clear) {
                    withAnimation { history = [] }
                    Task {
                        try? await model.database.clearSearches()
                        model.libraryChanged()
                    }
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.pongoTeal)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            ForEach(history, id: \.self) { item in
                HStack(spacing: 12) {
                    Button {
                        query = item
                        model.rememberSearch(item)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "clock.arrow.circlepath").foregroundStyle(Color.pongoIcon)
                            Text(item).font(.system(size: 18)).lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(height: 48)
                        .contentShape(.rect)
                    }
                    .buttonStyle(.row)
                    Button {
                        withAnimation { history.removeAll { $0 == item } }
                        Task {
                            try? await model.database.removeSearch(item)
                            model.libraryChanged()
                        }
                    } label: {
                        Image(systemName: "xmark").font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.pongoIcon)
                            .frame(width: 36, height: 36)
                            .contentShape(.rect)
                    }
                    .buttonStyle(.press)
                }
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Results

    @ViewBuilder private func resultList(_ results: SearchResults) -> some View {
        let settings = model.settings.settings
        let artists = Array(results.artists.prefix(settings.searchArtistCount))
        let albums = Array(results.albums.prefix(settings.searchAlbumCount))
        let tracks = Array(results.tracks.prefix(settings.searchTrackCount))
        let playlists = Array(results.playlists.prefix(settings.searchPlaylistCount))
        if artists.isEmpty && albums.isEmpty && tracks.isEmpty && playlists.isEmpty {
            EmptyMessage(systemImage: "magnifyingglass", title: L10n.noresults).padding(.top, 60)
        }
        if !artists.isEmpty {
            header(L10n.artists)
            ForEach(artists) { artist in
                NavigationLink(value: Route.artist(artist)) {
                    ResultRow(image: URL(string: artist.image), title: artist.name, circle: true,
                              placeholder: "music.microphone")
                }
                .simultaneousGesture(TapGesture().onEnded { model.rememberSearch(query) })
            }
        }
        if !albums.isEmpty {
            header(L10n.albums)
            ForEach(albums) { album in
                NavigationLink(value: Route.album(album)) {
                    ResultRow(image: URL(string: album.image), title: album.name,
                              subtitle: album.artists.joined(separator: ", "), placeholder: "square.stack")
                }
                .simultaneousGesture(TapGesture().onEnded { model.rememberSearch(query) })
            }
        }
        if !tracks.isEmpty {
            header(L10n.tracks)
            ForEach(tracks) { track in
                let current = model.player.current
                HStack(spacing: 0) {
                    Button {
                        model.rememberSearch(query)
                        Task { await model.player.playSingle(track, collectionID: Self.collectionID) }
                    } label: {
                        ResultRow(image: track.coverURL(size: 150), title: track.name, subtitle: track.artistNames) {
                            TrackStatus(
                                stid: track.id,
                                isCurrent: current?.stid == track.id && current?.collectionID == Self.collectionID)
                        }
                    }
                    .contextMenu { TrackMenu(track: track, collectionID: Self.collectionID) }
                    Menu {
                        TrackMenu(track: track, collectionID: Self.collectionID)
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 17, weight: .semibold))
                            .frame(width: 40, height: 60)
                            .contentShape(.rect)
                    }
                    .padding(.trailing, 10)
                    .padding(.leading, -12)
                }
            }
        }
        if !playlists.isEmpty {
            header(L10n.playlists)
            ForEach(playlists) { playlist in
                NavigationLink(value: Route.playlist(playlist)) {
                    ResultRow(image: URL(string: playlist.image), title: playlist.name, placeholder: "music.note.list")
                }
                .simultaneousGesture(TapGesture().onEnded { model.rememberSearch(query) })
            }
        }
    }

    private func header(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 20, weight: .bold))
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 2)
    }

    private func search(_ query: String) async {
        guard !query.isEmpty else {
            results = nil
            return
        }
        // Waits for the user to stop typing
        try? await Task.sleep(for: .milliseconds(350))
        guard !Task.isCancelled else { return }
        searching = true
        defer { searching = false }
        if let found = try? await model.catalog.search(query, market: model.settings.settings.market),
            !Task.isCancelled
        {
            withAnimation(.easeOut(duration: 0.2)) { results = found }
        }
    }
}

/// A search result: a big cover, title and subtitle, and something at its
/// end.
private struct ResultRow<Trailing: View>: View {
    var image: URL?
    var title: String
    var subtitle = ""
    var circle = false
    var placeholder = "music.note"
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(spacing: 12.5) {
            CoverImage(url: image, placeholder: placeholder)
                .frame(width: 65, height: 65)
                .clipShape(circle ? AnyShape(Circle()) : AnyShape(RoundedRectangle(cornerRadius: 7.5, style: .continuous)))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 18.5, weight: .semibold))
                if !subtitle.isEmpty { Text(subtitle).font(.system(size: 14)).opacity(0.78) }
            }
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
            trailing
        }
        .frame(height: 85)
        .padding(.horizontal, 20)
        .contentShape(.rect)
        .foregroundStyle(.primary)
    }
}

extension ResultRow where Trailing == EmptyView {
    init(image: URL?, title: String, subtitle: String = "", circle: Bool = false, placeholder: String = "music.note") {
        self.init(image: image, title: title, subtitle: subtitle, circle: circle, placeholder: placeholder) {
            EmptyView()
        }
    }
}
