import 'dart:async';
import 'dart:typed_data';

import '../../../domain/models/playlists/playlist_handler.dart';
import 'user_playlist_view_model.dart';

/// A playlist of downloaded tracks.
class LocalPlaylistViewModel extends UserPlaylistViewModel {
  /// Creates a view model and loads the playlist.
  LocalPlaylistViewModel({
    required super.id,
    required super.title,
    required super.cover,
    required super.blurhash,
    required super.playlists,
    required super.player,
    required super.blurhashService,
  }) {
    unawaited(load());
  }

  final _durations = <String, int>{};

  @override
  String get collectionId => 'local.playlist:$id';

  @override
  Future<int> countTracks() => playlists.localTrackCount(id);

  @override
  Future<void> loadTracks() async {
    final downloads = await playlists.localTracks(id);
    hiddenTracks = {
      for (final download in downloads) download.track.id: download.hidden,
    };
    _durations
      ..clear()
      ..addEntries(
        downloads.map(
          (download) =>
              MapEntry(download.track.id, download.durationMilliseconds),
        ),
      );
    trackList = [for (final download in downloads) download.track];
  }

  @override
  Future<void> play({int index = 0}) => player.playOffline(
    collectionId,
    shownTracks,
    durations: _durations,
    index: index,
  );

  @override
  Future<void> playShuffle() => player.playOffline(
    collectionId,
    shownTracks,
    durations: _durations,
    shuffle: true,
  );

  @override
  Future<void> saveTitle(String title) =>
      playlists.renameLocalPlaylist(id, title);

  @override
  Future<void> saveCover(Uint8List cover) =>
      playlists.setLocalPlaylistCover(id, cover);

  @override
  Future<void> saveHidden(List<String> stids, {required bool hidden}) =>
      playlists.setLocalTracksHidden(id, stids, hidden: hidden);

  @override
  Future<void> saveOrder() => playlists.reorderLocalTracks(id, [
    for (final track in trackList) track.id,
  ]);

  @override
  Future<void> deleteTracks(List<String> stids) =>
      playlists.removeLocalTracks(id, stids);

  @override
  PlaylistHandler handlerForSelected() => PlaylistHandler(
    type: PlaylistHandlerType.offline,
    function: PlaylistHandlerFunction.addToPlaylist,
    track: [
      for (final track in trackList)
        if (selectedStids.contains(track.id))
          PlaylistHandlerOfflineTrack(
            id: track.id,
            name: track.name,
            artist: track.artists,
            cover: track.image?.path ?? '',
            playlistHandlerCoverType: PlaylistHandlerCoverType.bytes,
            filePath: track.image?.path ?? '',
          ),
    ],
  );
}
