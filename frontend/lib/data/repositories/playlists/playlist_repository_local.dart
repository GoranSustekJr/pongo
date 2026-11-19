import 'dart:typed_data';

import '../../../domain/models/playlists/online_playlist_track.dart';
import '../../../domain/models/playlists/user_playlist.dart';
import '../../services/database/database_service.dart';
import 'playlist_repository.dart';

/// A [PlaylistRepository] kept in the device database.
class PlaylistRepositoryLocal implements PlaylistRepository {
  /// Creates a repository backed by [_database].
  PlaylistRepositoryLocal({required this._database});

  final DatabaseService _database;

  @override
  Future<List<UserPlaylist>> onlinePlaylists() async => [
    for (final row in await _database.onlinePlaylists.queryAll())
      UserPlaylist.fromRow(row, 'opid'),
  ];

  @override
  Future<int> onlinePlaylistCount() => _database.onlinePlaylists.count();

  @override
  Future<int> createOnlinePlaylist(String title, Uint8List? cover) =>
      _database.onlinePlaylists.insert(title, cover);

  @override
  Future<List<OnlinePlaylistTrack>> onlineTracks(int opid) =>
      _database.onlinePlaylists.queryTracks(opid);

  @override
  Future<int> onlineTrackCount(int opid) =>
      _database.onlinePlaylists.countShownTracks(opid);

  @override
  Future<bool> addOnlineTrack(OnlinePlaylistTrack track) async =>
      await _database.onlinePlaylists.insertTrack(track) != null;

  @override
  Future<void> reorderOnlineTracks(
    int opid,
    List<OnlinePlaylistTrack> tracks,
  ) => _database.onlinePlaylists.updateOrder(opid, tracks);

  @override
  Future<void> removeOnlineTracks(int opid, List<String> stids) =>
      _database.onlinePlaylists.removeTracks(opid, stids);

  @override
  Future<void> setOnlineTracksHidden(
    int opid,
    List<String> stids, {
    required bool hidden,
  }) => _database.onlinePlaylists.updateHidden(opid, stids, hidden: hidden);

  @override
  Future<void> renameOnlinePlaylist(int opid, String title) =>
      _database.onlinePlaylists.updateTitle(opid, title);

  @override
  Future<void> setOnlinePlaylistCover(int opid, Uint8List cover) =>
      _database.onlinePlaylists.updateCover(opid, cover);

  @override
  Future<void> deleteOnlinePlaylist(int opid) =>
      _database.onlinePlaylists.remove(opid);

  @override
  Future<List<UserPlaylist>> localPlaylists() async => [
    for (final row in await _database.localPlaylists.queryAll())
      UserPlaylist.fromRow(row, 'lpid'),
  ];

  @override
  Future<int> localPlaylistCount() => _database.localPlaylists.count();

  @override
  Future<int> createLocalPlaylist(String title, Uint8List? cover) =>
      _database.localPlaylists.insert(title, cover);

  @override
  Future<List<DownloadedTrack>> localTracks(int lpid) async => [
    for (final row in await _database.localPlaylists.queryTracks(lpid))
      DownloadedTrack.fromRow(row),
  ];

  @override
  Future<int> localTrackCount(int lpid) =>
      _database.localPlaylists.countTracks(lpid);

  @override
  Future<bool> addLocalTrack(int lpid, String stid) async =>
      await _database.localPlaylists.insertTrack(lpid, stid) != null;

  @override
  Future<void> reorderLocalTracks(int lpid, List<String> stids) =>
      _database.localPlaylists.updateOrder(lpid, stids);

  @override
  Future<void> removeLocalTracks(int lpid, List<String> stids) =>
      _database.localPlaylists.removeTracks(lpid, stids);

  @override
  Future<void> setLocalTracksHidden(
    int lpid,
    List<String> stids, {
    required bool hidden,
  }) => _database.localPlaylists.updateHidden(lpid, stids, hidden: hidden);

  @override
  Future<void> renameLocalPlaylist(int lpid, String title) =>
      _database.localPlaylists.updateTitle(lpid, title);

  @override
  Future<void> setLocalPlaylistCover(int lpid, Uint8List cover) =>
      _database.localPlaylists.updateCover(lpid, cover);

  @override
  Future<void> deleteLocalPlaylist(int lpid) =>
      _database.localPlaylists.remove(lpid);
}
