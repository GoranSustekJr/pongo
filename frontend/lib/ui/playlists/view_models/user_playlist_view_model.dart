import 'package:flutter/foundation.dart';

import '../../../data/repositories/player/player_repository.dart';
import '../../../data/repositories/playlists/playlist_repository.dart';
import '../../../data/services/media/blurhash_service.dart';
import '../../../domain/models/catalog/track.dart';
import '../../../domain/models/playlists/playlist_handler.dart';
import 'local_playlist_view_model.dart' show LocalPlaylistViewModel;
import 'online_playlist_view_model.dart' show OnlinePlaylistViewModel;

/// A playlist the user made, which they can edit, reorder and play.
///
/// [OnlinePlaylistViewModel] and [LocalPlaylistViewModel] fill in where the
/// tracks come from and how changes are saved.
abstract class UserPlaylistViewModel extends ChangeNotifier {
  /// Creates a view model for the playlist with [id].
  UserPlaylistViewModel({
    required this.id,
    required this._title,
    required this._cover,
    required this._blurhash,
    required this.playlists,
    required this.player,
    required this.blurhashService,
  });

  /// The playlist's ID.
  final int id;

  /// Where playlists are saved.
  @protected
  final PlaylistRepository playlists;

  /// Plays the tracks.
  @protected
  final PlayerRepository player;

  /// Encodes covers for the background.
  @protected
  final BlurhashService blurhashService;

  String _title;
  Uint8List? _cover;
  String _blurhash;
  bool _showBody = false;
  bool _edit = false;
  int _listLength = 0;

  /// The tracks, in playlist order.
  @protected
  List<Track> trackList = [];

  /// Whether each track is hidden, by ID.
  @protected
  Map<String, bool> hiddenTracks = {};

  final _selectedStids = <String>[];

  /// The ID that marks queue entries started from this playlist.
  String get collectionId;

  /// The title.
  String get title => _title;

  /// The cover bytes, if the user set one.
  Uint8List? get cover => _cover;

  /// The blurhash of the cover.
  String get blurhash => _blurhash;

  /// Whether the tracks are loaded.
  bool get showBody => _showBody;

  /// Whether the playlist is being edited.
  bool get edit => _edit;

  /// The number of tracks, known before they're loaded.
  int get listLength => _listLength;

  /// The tracks, in playlist order.
  List<Track> get tracks => trackList;

  /// Whether each track is hidden, by ID.
  Map<String, bool> get hidden => hiddenTracks;

  /// IDs of the selected tracks.
  List<String> get selectedStids => _selectedStids;

  /// The tracks that play, which are the ones not hidden.
  List<Track> get shownTracks => [
    for (final track in trackList)
      if (hiddenTracks[track.id] == false) track,
  ];

  /// Whether this playlist is playing.
  bool get isPlaying =>
      player.currentItem.value?.id.startsWith('$collectionId.') ?? false;

  /// Loads the number of tracks.
  @protected
  Future<int> countTracks();

  /// Loads the tracks into [trackList] and [hiddenTracks].
  @protected
  Future<void> loadTracks();

  /// Saves [title].
  @protected
  Future<void> saveTitle(String title);

  /// Saves [cover].
  @protected
  Future<void> saveCover(Uint8List cover);

  /// Saves whether the tracks with [stids] are hidden.
  @protected
  Future<void> saveHidden(List<String> stids, {required bool hidden});

  /// Saves the current order of [trackList].
  @protected
  Future<void> saveOrder();

  /// Deletes the tracks with [stids] from the playlist.
  @protected
  Future<void> deleteTracks(List<String> stids);

  /// The playlist editor for adding the selected tracks elsewhere.
  @protected
  PlaylistHandler handlerForSelected();

  /// Plays the shown tracks from [index].
  Future<void> play({int index = 0});

  /// Plays the shown tracks shuffled.
  Future<void> playShuffle();

  /// Loads the playlist.
  Future<void> load() async {
    _listLength = await countTracks();
    notifyListeners();
    await loadTracks();
    _showBody = true;
    notifyListeners();
  }

  /// Renames the playlist.
  Future<void> rename(String title) async {
    await saveTitle(title);
    _title = title;
    notifyListeners();
  }

  /// Replaces the cover with [bytes].
  Future<void> setCover(Uint8List bytes) async {
    if (bytes.isEmpty) return;
    await saveCover(bytes);
    _cover = bytes;
    _blurhash = await blurhashService.encodeBytes(bytes);
    notifyListeners();
  }

  /// Starts editing, stopping playback first if [haltPlayback].
  Future<void> startEdit({required bool haltPlayback}) async {
    if (haltPlayback) await player.halt();
    _edit = true;
    notifyListeners();
  }

  /// Stops editing and clears the selection.
  void stopEdit() {
    _edit = false;
    _selectedStids.clear();
    notifyListeners();
  }

  /// Selects or deselects the track with [stid].
  void select(String stid) {
    if (!_selectedStids.remove(stid)) _selectedStids.add(stid);
    notifyListeners();
  }

  /// Selects every track, or none if all are selected.
  void selectAll() {
    final all = _selectedStids.length == trackList.length;
    _selectedStids.clear();
    if (!all) _selectedStids.addAll(trackList.map((track) => track.id));
    notifyListeners();
  }

  /// Moves the track at [oldIndex] to [newIndex], counted before removal.
  Future<void> moveTrack(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) return;
    final track = trackList.removeAt(oldIndex);
    trackList.insert(oldIndex < newIndex ? newIndex - 1 : newIndex, track);
    notifyListeners();
    await saveOrder();
  }

  /// Shows the selected tracks again.
  Future<void> showSelected() => _setSelectedHidden(hidden: false);

  /// Hides the selected tracks.
  Future<void> hideSelected() => _setSelectedHidden(hidden: true);

  Future<void> _setSelectedHidden({required bool hidden}) async {
    if (_selectedStids.isEmpty) return;
    await saveHidden(_selectedStids, hidden: hidden);
    for (final stid in _selectedStids) {
      if (hiddenTracks.containsKey(stid)) hiddenTracks[stid] = hidden;
    }
    _selectedStids.clear();
    _edit = false;
    notifyListeners();
  }

  /// Removes the selected tracks from the playlist.
  Future<void> removeSelected() async {
    await deleteTracks(_selectedStids);
    trackList = [];
    hiddenTracks = {};
    _selectedStids.clear();
    _edit = false;
    await load();
  }

  /// The playlist editor for adding the selected tracks to a playlist, or
  /// `null` if none are selected.
  PlaylistHandler? addSelectedToPlaylist() =>
      _selectedStids.isEmpty ? null : handlerForSelected();
}
