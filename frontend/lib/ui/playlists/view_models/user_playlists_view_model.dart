import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/repositories/playlists/playlist_repository.dart';
import '../../../domain/models/playlists/playlist_handler.dart';
import '../../../domain/models/playlists/user_playlist.dart';

/// The user's online or local playlists.
class UserPlaylistsViewModel extends ChangeNotifier {
  /// Creates a view model for the playlists of [type] and loads them.
  UserPlaylistsViewModel({required this.type, required this._playlists}) {
    unawaited(load());
  }

  /// Which playlists to show.
  final PlaylistHandlerType type;

  final PlaylistRepository _playlists;

  bool _showBody = false;
  int _playlistsLength = 0;
  List<UserPlaylist> _items = const [];

  bool get _online => type == PlaylistHandlerType.online;

  /// Whether the playlists are loaded.
  bool get showBody => _showBody;

  /// The number of playlists, known before they're loaded.
  int get playlistsLength => _playlistsLength;

  /// The playlists, newest first.
  List<UserPlaylist> get playlists => _items;

  /// Loads the playlists.
  Future<void> load() async {
    _playlistsLength = _online
        ? await _playlists.onlinePlaylistCount()
        : await _playlists.localPlaylistCount();
    notifyListeners();
    _items = _online
        ? await _playlists.onlinePlaylists()
        : await _playlists.localPlaylists();
    _showBody = true;
    notifyListeners();
  }

  /// Deletes the playlist at [index].
  Future<void> remove(int index) async {
    final playlist = _items[index];
    _online
        ? await _playlists.deleteOnlinePlaylist(playlist.id)
        : await _playlists.deleteLocalPlaylist(playlist.id);
    _playlistsLength--;
    _items = [..._items]..removeAt(index);
    notifyListeners();
  }

  /// Shows [cover] for the playlist at [index] until the next load.
  void updateCover(int index, Uint8List cover) {
    _items = [..._items];
    _items[index] = _items[index].copyWith(cover: cover);
    notifyListeners();
  }
}
