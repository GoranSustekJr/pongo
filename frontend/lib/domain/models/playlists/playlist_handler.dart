import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../utils/image_resolution.dart';
import '../catalog/track.dart';

part 'playlist_handler.freezed.dart';

/// Which kind of playlist the playlist handler works with.
enum PlaylistHandlerType { online, offline }

/// What the playlist handler was opened to do.
enum PlaylistHandlerFunction { addToPlaylist, createPlaylist }

/// Whether a track's cover is a URL or a file on the device.
enum PlaylistHandlerCoverType { url, bytes }

/// A request to add tracks to a playlist, shown by the playlist handler.
@freezed
abstract class PlaylistHandler with _$PlaylistHandler {
  /// Creates a request.
  const factory PlaylistHandler({
    required PlaylistHandlerType type,
    required PlaylistHandlerFunction function,
    required List<PlaylistHandlerTrack>? track,

    /// Track IDs that have to be downloaded before an offline playlist can
    /// hold them.
    @Default(<String>[]) List<String> toDownload,
  }) = _PlaylistHandler;
}

/// A track offered to the playlist handler.
@freezed
sealed class PlaylistHandlerTrack with _$PlaylistHandlerTrack {
  /// A catalog track.
  const factory PlaylistHandlerTrack.online({
    required String id,
    required String name,
    required List<ArtistTrack> artist,
    required String cover,
    required AlbumTrack? albumTrack,
    required PlaylistHandlerCoverType playlistHandlerCoverType,
  }) = PlaylistHandlerOnlineTrack;

  /// A downloaded track.
  const factory PlaylistHandlerTrack.offline({
    required String id,
    required String name,
    required List<ArtistTrack> artist,
    required String cover,
    required PlaylistHandlerCoverType playlistHandlerCoverType,
    required String filePath,
  }) = PlaylistHandlerOfflineTrack;
}

/// The playlist editor entry for the catalog [track], with a 150 px cover.
PlaylistHandlerOnlineTrack onlineHandlerTrack(Track track) =>
    PlaylistHandlerOnlineTrack(
      id: track.id,
      name: track.name,
      artist: track.artists,
      cover: imageUrlForSize(track.album?.images ?? const [], 150, 150),
      albumTrack: track.album,
      playlistHandlerCoverType: PlaylistHandlerCoverType.url,
    );
