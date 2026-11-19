import 'dart:async';
import 'dart:typed_data';

import '../../../data/repositories/catalog/catalog_repository.dart';
import '../../../data/repositories/library/downloads_repository.dart';
import '../../../data/repositories/player/player_repository.dart';
import '../../../domain/models/playlists/online_playlist_track.dart';
import '../../../domain/models/playlists/playlist_handler.dart';
import '../../../utils/image_resolution.dart';
import '../../../utils/result.dart';
import 'user_playlist_view_model.dart';

/// A playlist of catalog tracks.
class OnlinePlaylistViewModel extends UserPlaylistViewModel {
  /// Creates a view model and loads the playlist.
  OnlinePlaylistViewModel({
    required super.id,
    required super.title,
    required super.cover,
    required super.blurhash,
    required super.playlists,
    required super.player,
    required super.blurhashService,
    required this._catalog,
    required this._downloads,
  }) {
    player.fetchingTracks.addListener(notifyListeners);
    _fetched = player.onTrackFetched.listen(_onTrackFetched);
    unawaited(load());
  }

  final CatalogRepository _catalog;
  final DownloadsRepository _downloads;
  late final StreamSubscription<FetchedTrack> _fetched;
  List<OnlinePlaylistTrack> _entries = const [];
  final _missingTracks = <String>[];
  final _existingTracks = <String, double>{};

  @override
  String get collectionId => 'online.playlist:$id';

  /// IDs of tracks the server still has to fetch.
  List<String> get missingTracks => _missingTracks;

  /// Lengths in seconds of the tracks the server has.
  Map<String, double> get existingTracks => _existingTracks;

  /// IDs of tracks being fetched right now.
  List<String> get loading => player.fetchingTracks.value.toList();

  /// Whether shuffling is being prepared, which it never is.
  bool get loadingShuffle => false;

  @override
  Future<int> countTracks() => playlists.onlineTrackCount(id);

  @override
  Future<void> loadTracks() async {
    _entries = await playlists.onlineTracks(id);
    hiddenTracks = {for (final entry in _entries) entry.stid: entry.hidden};
    trackList = [for (final entry in _entries) entry.toTrack()];
    if (trackList.isEmpty) return;
    final result = await _catalog.availability([
      for (final track in trackList) track.id,
    ]);
    if (result case Ok(:final value)) {
      _existingTracks
        ..clear()
        ..addAll(value.durations);
      _missingTracks
        ..clear()
        ..addAll(value.missing);
    }
  }

  void _onTrackFetched(FetchedTrack fetched) {
    final duration = fetched.duration;
    if (duration == null || !_missingTracks.remove(fetched.stid)) return;
    _existingTracks[fetched.stid] = duration;
    notifyListeners();
  }

  @override
  Future<void> play({int index = 0}) => player.playOnline(
    collectionId,
    shownTracks,
    durations: _existingTracks,
    index: index,
  );

  @override
  Future<void> playShuffle() async {
    if (_missingTracks.isNotEmpty) return;
    await player.playOnline(
      collectionId,
      shownTracks,
      durations: _existingTracks,
      shuffle: true,
    );
  }

  @override
  Future<void> saveTitle(String title) =>
      playlists.renameOnlinePlaylist(id, title);

  @override
  Future<void> saveCover(Uint8List cover) =>
      playlists.setOnlinePlaylistCover(id, cover);

  @override
  Future<void> saveHidden(List<String> stids, {required bool hidden}) =>
      playlists.setOnlineTracksHidden(id, stids, hidden: hidden);

  @override
  Future<void> saveOrder() => playlists.reorderOnlineTracks(id, [
    for (final track in trackList)
      OnlinePlaylistTrack(
        opid: id,
        stid: track.id,
        title: track.name,
        artistTrack: track.artists,
        albumTrack: track.album,
        image: imageUrlForSize(track.album?.images ?? const [], 150, 150),
        orderNumber: -1,
        hidden: hiddenTracks[track.id] ?? false,
      ),
  ]);

  @override
  Future<void> deleteTracks(List<String> stids) =>
      playlists.removeOnlineTracks(id, stids);

  @override
  PlaylistHandler handlerForSelected() => PlaylistHandler(
    type: PlaylistHandlerType.online,
    function: PlaylistHandlerFunction.addToPlaylist,
    track: [
      for (final stid in selectedStids)
        onlineHandlerTrack(trackList.firstWhere((track) => track.id == stid)),
    ],
  );

  /// The playlist editor for downloading the selected tracks, or `null` if
  /// none are selected.
  Future<PlaylistHandler?> downloadSelected() async {
    if (selectedStids.isEmpty) return null;
    return PlaylistHandler(
      toDownload: await _downloads.missing(selectedStids),
      type: PlaylistHandlerType.offline,
      function: PlaylistHandlerFunction.addToPlaylist,
      track: [
        for (final track in trackList)
          if (selectedStids.contains(track.id))
            PlaylistHandlerOnlineTrack(
              id: track.id,
              name: track.name,
              artist: track.artists,
              cover: bestImageUrl(track.album?.images ?? const []),
              albumTrack: track.album,
              playlistHandlerCoverType: PlaylistHandlerCoverType.url,
            ),
      ],
    );
  }

  @override
  void dispose() {
    player.fetchingTracks.removeListener(notifyListeners);
    unawaited(_fetched.cancel());
    super.dispose();
  }
}
