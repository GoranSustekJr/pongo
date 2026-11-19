import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/repositories/library/downloads_repository.dart';
import '../../../data/repositories/playlists/playlist_repository.dart';
import '../../../data/services/media/image_bytes_service.dart';
import '../../../domain/models/catalog/track.dart';
import '../../../domain/models/playlists/online_playlist_track.dart';
import '../../../domain/models/playlists/playlist_handler.dart';
import '../../../domain/models/playlists/user_playlist.dart';
import '../../../utils/result.dart';
import '../../core/app_icons.dart';
import '../../core/messages/app_message.dart';
import '../../core/messages/message_center.dart';

/// Creates playlists and adds tracks to them for a [PlaylistHandler].
class PlaylistHandlerViewModel extends ChangeNotifier {
  /// Creates a view model for [handler] and loads the playlists it can
  /// add to.
  PlaylistHandlerViewModel({
    required this.handler,
    required this._playlists,
    required this._downloads,
    required this._images,
    required this._messages,
  }) {
    if (handler.function != PlaylistHandlerFunction.createPlaylist) {
      unawaited(_loadPlaylists());
    }
  }

  /// What the editor was opened to do.
  final PlaylistHandler handler;

  final PlaylistRepository _playlists;
  final DownloadsRepository _downloads;
  final ImageBytesService _images;
  final MessageCenter _messages;

  bool _working = false;
  List<UserPlaylist> _currentPlaylists = const [];
  Map<int, Set<String>> _playlistTracks = const {};
  final _selectedPlaylists = <int>[];

  bool get _online => handler.type == PlaylistHandlerType.online;

  List<PlaylistHandlerTrack> get _tracks => handler.track ?? const [];

  /// Whether a change is being saved.
  bool get working => _working;

  /// The playlists the tracks can be added to.
  List<UserPlaylist> get currentPlaylists => _currentPlaylists;

  /// The track IDs in each playlist, by playlist ID.
  Map<int, Set<String>> get playlistTracks => _playlistTracks;

  /// IDs of the playlists chosen to add the tracks to.
  List<int> get selectedPlaylists => _selectedPlaylists;

  /// The cover suggested for a new playlist, which is the first track's.
  String? get suggestedCover => _tracks.isEmpty ? null : _tracks.first.cover;

  Future<void> _loadPlaylists() async {
    final playlists = _online
        ? await _playlists.onlinePlaylists()
        : await _playlists.localPlaylists();
    final tracks = <int, Set<String>>{};
    for (final playlist in playlists) {
      tracks[playlist.id] = _online
          ? {
              for (final track in await _playlists.onlineTracks(playlist.id))
                track.stid,
            }
          : {
              for (final track in await _playlists.localTracks(playlist.id))
                track.track.id,
            };
    }
    _currentPlaylists = playlists;
    _playlistTracks = tracks;
    notifyListeners();
  }

  /// Chooses or unchooses the playlist with [id].
  void selectPlaylist(int id) {
    if (!_selectedPlaylists.remove(id)) _selectedPlaylists.add(id);
    notifyListeners();
  }

  /// Creates a playlist named [title] with the cover at [cover], a URL or
  /// path, and adds the tracks to it.
  ///
  /// Returns whether the editor is done and can close.
  Future<bool> createPlaylist(String title, {String? cover}) async {
    final name = title.trim();
    if (_working || name.isEmpty) return false;
    _setWorking(true);

    final existing = _online
        ? await _playlists.onlinePlaylists()
        : await _playlists.localPlaylists();
    if (existing.any((playlist) => playlist.title == name)) {
      _messages.show(WarningMessage((l10n) => l10n.playlistnamealreadyexists));
      _setWorking(false);
      return false;
    }

    Uint8List? bytes;
    if (cover != null) {
      try {
        bytes = await _images.read(cover);
      } on Exception {
        bytes = null;
      }
    }

    if (_online) {
      final opid = await _playlists.createOnlinePlaylist(name, bytes);
      await _addOnline([opid]);
    } else if (handler.toDownload.isEmpty) {
      final lpid = await _playlists.createLocalPlaylist(name, bytes);
      await _addLocal([lpid]);
    } else if (await _downloadMissing()) {
      final lpid = await _playlists.createLocalPlaylist(name, bytes);
      await _addLocal([lpid]);
    }
    return true;
  }

  /// Adds the tracks to the chosen playlists.
  ///
  /// Returns whether the editor is done and can close.
  Future<bool> addToSelectedPlaylists() async {
    if (_working || _selectedPlaylists.isEmpty) return false;
    _setWorking(true);
    if (_online) {
      await _addOnline(_selectedPlaylists);
    } else if (handler.toDownload.isEmpty || await _downloadMissing()) {
      await _addLocal(_selectedPlaylists);
    }
    return true;
  }

  Future<void> _addOnline(List<int> opids) async {
    for (final opid in opids) {
      for (final track in _tracks) {
        await _playlists.addOnlineTrack(
          OnlinePlaylistTrack(
            opid: opid,
            stid: track.id,
            title: track.name,
            artistTrack: track.artist,
            albumTrack: switch (track) {
              PlaylistHandlerOnlineTrack(:final albumTrack) => albumTrack,
              PlaylistHandlerOfflineTrack() => null,
            },
            image: track.cover,
            orderNumber: -1,
            hidden: false,
          ),
        );
      }
    }
  }

  Future<void> _addLocal(List<int> lpids) async {
    for (final lpid in lpids) {
      for (final track in _tracks) {
        await _playlists.addLocalTrack(lpid, track.id);
      }
    }
  }

  /// Downloads the tracks in [PlaylistHandler.toDownload] and reports how it
  /// went. Returns whether any track was saved.
  Future<bool> _downloadMissing() async {
    _messages.show(
      InfoMessage(
        title: (l10n) => l10n.downloading,
        body: (l10n) => l10n.downloadhasstarted,
        icon: AppIcons.download,
      ),
    );
    final result = await _downloads.downloadAll([
      for (final track in _tracks)
        if (handler.toDownload.contains(track.id))
          (
            track: Track(
              id: track.id,
              name: track.name,
              artists: track.artist,
              album: switch (track) {
                PlaylistHandlerOnlineTrack(:final albumTrack) => albumTrack,
                PlaylistHandlerOfflineTrack() => null,
              },
            ),
            cover: track.cover,
          ),
    ]);
    switch (result) {
      case Ok(value: true):
        _messages.show(
          InfoMessage(
            title: (l10n) => l10n.successful,
            body: (l10n) => l10n.downloadsucceeded,
            icon: AppIcons.download,
          ),
        );
        return true;
      case Ok(value: false):
        return false;
      case Error():
        _messages.show(
          InfoMessage(
            title: (l10n) => l10n.error,
            body: (l10n) => l10n.downloadfailed,
            icon: AppIcons.warning,
          ),
        );
        return false;
    }
  }

  void _setWorking(bool working) {
    _working = working;
    notifyListeners();
  }
}
