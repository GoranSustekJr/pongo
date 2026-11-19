import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/repositories/catalog/catalog_repository.dart';
import '../../../data/repositories/library/downloads_repository.dart';
import '../../../data/repositories/library/favourites_repository.dart';
import '../../../data/repositories/player/player_repository.dart';
import '../../../domain/models/catalog/track.dart';
import '../../../domain/models/playlists/playlist_handler.dart';
import '../../../utils/image_resolution.dart';
import '../../../utils/result.dart';

/// The user's favourite tracks.
class FavouritesViewModel extends ChangeNotifier {
  /// Creates a view model and loads the favourites, and loads them again
  /// whenever `libraryChanges` notifies.
  FavouritesViewModel({
    required this._favourites,
    required this._downloads,
    required this._catalog,
    required this._player,
    this._libraryChanges,
  }) {
    _player.fetchingTracks.addListener(notifyListeners);
    _libraryChanges?.addListener(_reload);
    _fetched = _player.onTrackFetched.listen(_onTrackFetched);
    unawaited(load());
  }

  /// The ID that marks queue entries started from the favourites.
  static const collectionId = 'library.favourites';

  final FavouritesRepository _favourites;
  final DownloadsRepository _downloads;
  final CatalogRepository _catalog;
  final PlayerRepository _player;
  final Listenable? _libraryChanges;
  late final StreamSubscription<FetchedTrack> _fetched;

  bool _showBody = false;
  int _lengthOfFavourites = 0;
  List<Track> _tracks = const [];
  bool _edit = false;
  final _selectedTracks = <String>[];
  final _missingTracks = <String>[];
  final _existingTracks = <String, double>{};

  /// Whether the favourites are loaded.
  bool get showBody => _showBody;

  /// The number of favourites.
  int get lengthOfFavourites => _lengthOfFavourites;

  /// The favourites as tracks.
  List<Track> get favourites => _tracks;

  /// Whether the list is being edited.
  bool get edit => _edit;

  /// IDs of the selected tracks while editing.
  List<String> get selectedTracks => _selectedTracks;

  /// IDs of tracks the server still has to fetch.
  List<String> get missingTracks => _missingTracks;

  /// Lengths in seconds of the tracks the server has.
  Map<String, double> get existingTracks => _existingTracks;

  /// IDs of tracks being fetched right now.
  List<String> get loading => _player.fetchingTracks.value.toList();

  /// Whether shuffling is being prepared, which it never is.
  bool get loadingShuffle => false;

  /// Whether the favourites are playing.
  bool get isPlaying =>
      _player.currentItem.value?.id.startsWith('$collectionId.') ?? false;

  /// Loads the favourites and which of them the server has.
  Future<void> load() async {
    _lengthOfFavourites = await _favourites.count();
    _showBody = true;
    final favourites = await _favourites.favourites();
    _tracks = [for (final favourite in favourites) favourite.toTrack()];

    if (_lengthOfFavourites > 0) {
      final result = await _catalog.availability([
        for (final track in _tracks) track.id,
      ]);
      if (result case Ok(:final value)) {
        _existingTracks.addAll(value.durations);
        _missingTracks
          ..clear()
          ..addAll(value.missing);
      }
    }
    notifyListeners();
  }

  void _onTrackFetched(FetchedTrack fetched) {
    final duration = fetched.duration;
    if (duration == null || !_missingTracks.remove(fetched.stid)) return;
    _existingTracks[fetched.stid] = duration;
    notifyListeners();
  }

  /// The playlist editor for downloading the selected tracks, or `null` if
  /// none are selected.
  Future<PlaylistHandler?> downloadSelected() async {
    if (_selectedTracks.isEmpty) return null;
    return PlaylistHandler(
      toDownload: await _downloads.missing(_selectedTracks),
      type: PlaylistHandlerType.offline,
      function: PlaylistHandlerFunction.addToPlaylist,
      track: [
        for (final track in _tracks)
          if (_selectedTracks.contains(track.id))
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

  /// The playlist editor for adding the selected tracks to a playlist, or
  /// `null` if none are selected.
  PlaylistHandler? addSelectedToPlaylist() {
    if (_selectedTracks.isEmpty) return null;
    return PlaylistHandler(
      type: PlaylistHandlerType.online,
      function: PlaylistHandlerFunction.addToPlaylist,
      track: [
        for (final stid in _selectedTracks)
          onlineHandlerTrack(_tracks.firstWhere((track) => track.id == stid)),
      ],
    );
  }

  /// Plays the favourites from [index].
  Future<void> play({int? index}) async {
    if (_edit) return;
    await _player.playOnline(
      collectionId,
      _tracks,
      durations: _existingTracks,
      index: index,
    );
    notifyListeners();
  }

  /// Plays the favourites shuffled, once every track is available.
  Future<void> playShuffle() async {
    if (_missingTracks.isNotEmpty || _edit) return;
    await _player.playOnline(
      collectionId,
      _tracks,
      durations: _existingTracks,
      shuffle: true,
    );
    notifyListeners();
  }

  /// Stops playback if the favourites are playing, before they're edited.
  Future<void> haltIfPlaying() async {
    if (isPlaying) await _player.halt();
  }

  /// Starts or stops editing.
  void changeEdit({required bool editing}) {
    _edit = editing;
    notifyListeners();
  }

  /// Clears the selection.
  void clearSelectedTrack() {
    _selectedTracks.clear();
    notifyListeners();
  }

  /// Selects or deselects the track with [stid].
  void select(String stid) {
    if (!_selectedTracks.remove(stid)) _selectedTracks.add(stid);
    notifyListeners();
  }

  /// Unlikes the selected tracks.
  Future<void> removeSelected() async {
    await _favourites.remove(_selectedTracks);
    _tracks = const [];
    _selectedTracks.clear();
    await load();
  }

  void _reload() => unawaited(load());

  @override
  void dispose() {
    _player.fetchingTracks.removeListener(notifyListeners);
    _libraryChanges?.removeListener(_reload);
    unawaited(_fetched.cancel());
    super.dispose();
  }
}
