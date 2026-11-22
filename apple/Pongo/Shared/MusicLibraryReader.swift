import Foundation
import PongoCore

#if os(iOS)
    import MediaPlayer
#else
    import iTunesLibrary
#endif

/// Reads the playlists of the Music app's library on this device: those the
/// user made or added from Apple Music, private ones included.
enum MusicLibraryReader {
    enum Failure: Error {
        /// The user didn't allow Pongo to read the library.
        case denied
        case unreadable
    }

    /// The library's playlists that hold songs, folders and automatic lists
    /// left out.
    static func playlists() async throws -> [ImportPlaylist] {
        #if os(iOS)
            let status = await withCheckedContinuation { continuation in
                MPMediaLibrary.requestAuthorization { continuation.resume(returning: $0) }
            }
            guard status == .authorized else { throw Failure.denied }
            return await Task.detached(priority: .userInitiated) { readMediaLibrary() }.value
        #else
            return try await Task.detached(priority: .userInitiated) { try readITunesLibrary() }.value
        #endif
    }

    #if os(iOS)
        nonisolated private static func readMediaLibrary() -> [ImportPlaylist] {
            let collections = MPMediaQuery.playlists().collections ?? []
            return collections.compactMap { collection in
                guard let playlist = collection as? MPMediaPlaylist,
                    !playlist.playlistAttributes.contains(.genius),
                    (playlist.value(forProperty: "isFolder") as? Bool) != true
                else { return nil }
                let songs = playlist.items.compactMap { item -> ImportSong? in
                    guard let title = item.title, !title.isEmpty else { return nil }
                    return ImportSong(
                        title: title, artists: [item.artist].compactMap { $0 }, album: item.albumTitle,
                        durationMs: Int(item.playbackDuration * 1000))
                }
                guard !songs.isEmpty else { return nil }
                return ImportPlaylist(
                    id: "apple-library:\(playlist.persistentID)", name: playlist.name ?? "", source: .appleMusic,
                    songs: songs)
            }
        }
    #else
        nonisolated private static func readITunesLibrary() throws -> [ImportPlaylist] {
            let library: ITLibrary
            do {
                library = try ITLibrary(apiVersion: "1.1")
            } catch {
                throw Failure.denied
            }
            return library.allPlaylists.compactMap { playlist in
                // The whole library, Purchased and the like are automatic
                guard !playlist.isPrimary, playlist.isVisible, playlist.kind != .folder, playlist.kind != .genius,
                    playlist.distinguishedKind == .kindNone || playlist.distinguishedKind == .kindLovedSongs
                else { return nil }
                let songs = playlist.items.compactMap { item -> ImportSong? in
                    guard item.mediaKind == .kindSong || item.mediaKind == .kindMusicVideo, !item.title.isEmpty
                    else { return nil }
                    return ImportSong(
                        title: item.title, artists: [item.artist?.name].compactMap { $0 }, album: item.album.title,
                        durationMs: item.totalTime)
                }
                guard !songs.isEmpty else { return nil }
                return ImportPlaylist(
                    id: "apple-library:\(playlist.persistentID)", name: playlist.name, source: .appleMusic,
                    songs: songs)
            }
        }
    #endif
}
