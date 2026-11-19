import 'dart:typed_data';

import '../../../domain/models/playlists/online_playlist_track.dart';
import '../../../domain/models/playlists/user_playlist.dart';

/// Source of truth for the playlists the user made.
///
/// Online playlists hold catalog tracks; local playlists hold downloaded
/// tracks.
abstract class PlaylistRepository {
  /// All online playlists, newest first.
  Future<List<UserPlaylist>> onlinePlaylists();

  /// The number of online playlists.
  Future<int> onlinePlaylistCount();

  /// Creates an online playlist and returns its ID.
  Future<int> createOnlinePlaylist(String title, Uint8List? cover);

  /// The tracks of online playlist [opid], in order.
  Future<List<OnlinePlaylistTrack>> onlineTracks(int opid);

  /// The number of tracks shown in online playlist [opid].
  Future<int> onlineTrackCount(int opid);

  /// Adds [track] to its online playlist unless it's already there.
  ///
  /// Returns whether it was added.
  Future<bool> addOnlineTrack(OnlinePlaylistTrack track);

  /// Saves [tracks] as the content of online playlist [opid], in order.
  Future<void> reorderOnlineTracks(int opid, List<OnlinePlaylistTrack> tracks);

  /// Removes the tracks with [stids] from online playlist [opid].
  Future<void> removeOnlineTracks(int opid, List<String> stids);

  /// Shows or hides the tracks with [stids] in online playlist [opid].
  Future<void> setOnlineTracksHidden(
    int opid,
    List<String> stids, {
    required bool hidden,
  });

  /// Renames online playlist [opid].
  Future<void> renameOnlinePlaylist(int opid, String title);

  /// Replaces the cover of online playlist [opid].
  Future<void> setOnlinePlaylistCover(int opid, Uint8List cover);

  /// Deletes online playlist [opid].
  Future<void> deleteOnlinePlaylist(int opid);

  /// All local playlists, newest first.
  Future<List<UserPlaylist>> localPlaylists();

  /// The number of local playlists.
  Future<int> localPlaylistCount();

  /// Creates a local playlist and returns its ID.
  Future<int> createLocalPlaylist(String title, Uint8List? cover);

  /// The downloaded tracks of local playlist [lpid], in order.
  Future<List<DownloadedTrack>> localTracks(int lpid);

  /// The number of tracks in local playlist [lpid].
  Future<int> localTrackCount(int lpid);

  /// Adds the downloaded track with [stid] to local playlist [lpid] unless
  /// it's already there.
  ///
  /// Returns whether it was added.
  Future<bool> addLocalTrack(int lpid, String stid);

  /// Saves [stids] as the order of local playlist [lpid].
  Future<void> reorderLocalTracks(int lpid, List<String> stids);

  /// Removes the tracks with [stids] from local playlist [lpid].
  Future<void> removeLocalTracks(int lpid, List<String> stids);

  /// Shows or hides the tracks with [stids] in local playlist [lpid].
  Future<void> setLocalTracksHidden(
    int lpid,
    List<String> stids, {
    required bool hidden,
  });

  /// Renames local playlist [lpid].
  Future<void> renameLocalPlaylist(int lpid, String title);

  /// Replaces the cover of local playlist [lpid].
  Future<void> setLocalPlaylistCover(int lpid, Uint8List cover);

  /// Deletes local playlist [lpid].
  Future<void> deleteLocalPlaylist(int lpid);
}
