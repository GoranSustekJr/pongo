import PongoCore
import SwiftUI

/// Downloading whole playlists and albums: their songs are saved on the
/// device, and the playlist stays the same one, marked as downloaded,
/// rather than a copy made as an offline playlist.
extension AppModel {
    /// Keeps the online [playlist] downloaded: saves the [tracks] it holds
    /// and, from now on, those added to it.
    func downloadPlaylist(_ playlist: UserPlaylist, tracks: [Track]) async {
        // Downloaded right here, so opening it needn't check for missing songs
        healedPlaylists.insert(playlist.id)
        downloadedPlaylists.insert(playlist.id)
        libraryChanged()
        await downloadSongs(tracks)
    }

    /// Stops keeping the online [playlist] downloaded, deleting the songs
    /// only it needed.
    func removeDownload(of playlist: UserPlaylist, tracks: [Track]) async {
        downloadedPlaylists.remove(playlist.id)
        await removeDownloads(tracks.map(\.id))
    }

    /// Whether every one of [tracks] that can be downloaded is on the device.
    func isDownloaded(_ tracks: [Track]) -> Bool {
        let catalog = tracks.filter { $0.id.allSatisfy(\.isNumber) }
        return !catalog.isEmpty && catalog.allSatisfy { downloadedIDs.contains($0.id) }
    }

    /// Saves those of [tracks] not on the device yet, showing how it goes
    /// unless [quietly].
    func downloadSongs(_ tracks: [Track], quietly: Bool = false) async {
        // Files from the device have nothing to download
        let catalog = tracks.filter { $0.id.allSatisfy(\.isNumber) && !downloadingIDs.contains($0.id) }
        let missing = Set((try? await database.missingDownloads(catalog.map(\.id))) ?? catalog.map(\.id))
        let toGet = catalog.filter { missing.contains($0.id) }
        guard !toGet.isEmpty else {
            if !quietly { messages.show(L10n.downloadsucceeded, systemImage: "arrow.down.circle") }
            return
        }
        if !quietly { messages.show(L10n.downloadhasstarted, systemImage: "arrow.down.circle") }
        _ = try? await downloadAll(toGet)
        let failed = (try? await database.missingDownloads(toGet.map(\.id))) ?? []
        libraryChanged()
        if !failed.isEmpty {
            messages.show(
                L10n.downloadfailed, detail: "\(failed.count)/\(toGet.count)",
                systemImage: "exclamationmark.triangle", isError: true)
        } else if !quietly {
            messages.show(L10n.downloadsucceeded, systemImage: "arrow.down.circle")
        }
    }

    /// Downloads what's missing of a downloaded [playlist], such as songs
    /// another device added; once per playlist while the app runs, so songs
    /// that can't be downloaded aren't tried over and over.
    func keepDownloaded(_ playlist: UserPlaylist, tracks: [Track]) async {
        guard downloadedPlaylists.contains(playlist.id), !healedPlaylists.contains(playlist.id) else { return }
        healedPlaylists.insert(playlist.id)
        await downloadSongs(tracks, quietly: true)
    }

    /// Deletes the downloads of [stids], except those an offline playlist or
    /// a downloaded playlist still holds.
    func removeDownloads(_ stids: [String]) async {
        var kept = Set<String>()
        for local in (try? await database.localPlaylists()) ?? [] {
            kept.formUnion(((try? await database.localTracks(local.id)) ?? []).map(\.track.id))
        }
        for opid in downloadedPlaylists {
            kept.formUnion(((try? await database.onlineTracks(opid)) ?? []).map(\.stid))
        }
        let removed = stids.filter { !kept.contains($0) && downloadedIDs.contains($0) }
        try? await downloads.remove(removed)
        libraryChanged()
        messages.show(L10n.downloadremoved, systemImage: "arrow.down.circle")
    }
}
