import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/repositories/library/downloads_repository.dart';
import '../../../data/repositories/player/player_repository.dart';
import '../../../data/repositories/settings/settings_repository.dart';
import '../../../domain/models/catalog/track.dart';
import '../../../domain/models/playlists/playlist_handler.dart';
import '../../../domain/models/settings/app_settings.dart';

/// The tracks downloaded to the device.
class LocalsViewModel extends ChangeNotifier {
  /// Creates a view model and loads the downloads.
  LocalsViewModel({
    required this._downloads,
    required this._settings,
    required this._player,
  }) {
    unawaited(load());
  }

  /// The ID that marks queue entries started from the downloads.
  static const collectionId = 'library.locals';

  final DownloadsRepository _downloads;
  final SettingsRepository _settings;
  final PlayerRepository _player;

  bool _showBody = false;
  int _numOfTracks = 0;
  List<Track> _tracks = const [];
  List<Track> _tracksBackup = const [];
  bool _edit = false;
  final _durations = <String, int>{};
  final _primaryKey = <String, int>{};
  final _selectedTracks = <String>[];

  /// Whether the downloads are loaded.
  bool get showBody => _showBody;

  /// The number of downloaded tracks.
  int get numOfTracks => _numOfTracks;

  /// The tracks shown, filtered by the search.
  List<Track> get tracks => _tracks;

  /// Every downloaded track.
  List<Track> get tracksBackup => _tracksBackup;

  /// Whether the list is being edited.
  bool get edit => _edit;

  /// IDs of the selected tracks.
  List<String> get selectedTracks => _selectedTracks;

  /// Whether the downloads are playing.
  bool get isPlaying =>
      _player.currentItem.value?.id.startsWith('$collectionId.') ?? false;

  /// Loads the downloads in the saved order.
  Future<void> load() async {
    _numOfTracks = await _downloads.count();
    _showBody = true;
    notifyListeners();

    final downloads = await _downloads.downloads();
    _durations.clear();
    _primaryKey.clear();
    for (final download in downloads) {
      _durations[download.track.id] = download.durationMilliseconds;
      _primaryKey[download.track.id] = download.rowId;
    }
    _tracks = [for (final download in downloads) download.track];
    _tracksBackup = _tracks;
    _sortTracks(_settings.settings.localsSort);
    notifyListeners();
  }

  void _sortTracks(LocalsSort sort) {
    switch (sort) {
      case LocalsSort.titleAscending:
        _tracks.sort((a, b) => a.name.compareTo(b.name));
      case LocalsSort.titleDescending:
        _tracks.sort((a, b) => b.name.compareTo(a.name));
      case LocalsSort.firstAdded:
        _tracks.sort(
          (a, b) => _primaryKey[a.id]!.compareTo(_primaryKey[b.id]!),
        );
      case LocalsSort.lastAdded:
        _tracks.sort(
          (a, b) => _primaryKey[b.id]!.compareTo(_primaryKey[a.id]!),
        );
    }
  }

  /// Sorts the tracks by [sort] and remembers the choice.
  Future<void> sort(LocalsSort sort) async {
    _sortTracks(sort);
    notifyListeners();
    await _settings.update((settings) => settings.copyWith(localsSort: sort));
  }

  /// Selects or deselects the track with [stid].
  void select(String stid) {
    if (!_selectedTracks.remove(stid)) _selectedTracks.add(stid);
    notifyListeners();
  }

  /// Selects every track, or none if all are selected.
  void selectAll() {
    final all = _selectedTracks.length == _tracks.length;
    _selectedTracks.clear();
    if (!all) _selectedTracks.addAll(_tracks.map((track) => track.id));
    notifyListeners();
  }

  /// Plays the downloads from [index].
  Future<void> play({int index = 0}) => _player.playOffline(
    collectionId,
    _tracks,
    durations: _durations,
    index: index,
  );

  /// Plays the downloads shuffled.
  Future<void> shuffle() => _player.playOffline(
    collectionId,
    _tracks,
    durations: _durations,
    shuffle: true,
  );

  /// Starts editing, stopping playback first if the downloads are playing.
  Future<void> startEdit({required bool haltPlayback}) async {
    if (haltPlayback) await _player.halt();
    _edit = true;
    notifyListeners();
  }

  /// Stops editing and clears the selection.
  void stopEdit() {
    _edit = false;
    _selectedTracks.clear();
    notifyListeners();
  }

  /// Deletes the selected tracks from the device.
  Future<void> removeSelected() async {
    await _downloads.remove(_selectedTracks);
    _tracks = const [];
    _selectedTracks.clear();
    _edit = false;
    await load();
  }

  /// The playlist editor for adding the selected tracks to a playlist, or
  /// `null` if none are selected.
  PlaylistHandler? addSelectedToPlaylist() {
    if (_selectedTracks.isEmpty) return null;
    return PlaylistHandler(
      type: PlaylistHandlerType.offline,
      function: PlaylistHandlerFunction.addToPlaylist,
      track: [
        for (final track in _tracks)
          if (_selectedTracks.contains(track.id))
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

  /// Shows the tracks whose title or artists contain [value].
  void onSearched(String value) {
    final query = value.toLowerCase();
    if (query.isEmpty) {
      _tracks = _tracksBackup;
    } else {
      final byName = _tracksBackup
          .where((track) => track.name.toLowerCase().contains(query))
          .toList();
      final byArtist = _tracksBackup.where(
        (track) =>
            !byName.contains(track) &&
            track.artistNames.toLowerCase().contains(query),
      );
      _tracks = [...byName, ...byArtist];
    }
    notifyListeners();
  }
}
