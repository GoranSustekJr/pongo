import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';

import '../catalog/track.dart';

part 'user_playlist.freezed.dart';

/// A playlist the user made, of catalog tracks or of downloaded tracks.
@freezed
abstract class UserPlaylist with _$UserPlaylist {
  /// Creates a playlist.
  const factory UserPlaylist({
    /// The playlist's ID in its table.
    required int id,
    required String title,

    /// The cover image bytes, if the user set one.
    Uint8List? cover,
  }) = _UserPlaylist;

  /// Creates a playlist from a row with an [idColumn] ID column.
  factory UserPlaylist.fromRow(Map<String, dynamic> row, String idColumn) =>
      UserPlaylist(
        id: row[idColumn] as int,
        title: row['title'] as String? ?? '',
        cover: row['cover'] as Uint8List?,
      );
}

/// A downloaded track as it's stored on the device.
@freezed
abstract class DownloadedTrack with _$DownloadedTrack {
  /// Creates a downloaded track.
  const factory DownloadedTrack({
    required Track track,

    /// The track's length in milliseconds.
    required int durationMilliseconds,

    /// The row ID, which grows with each download.
    required int rowId,

    /// Whether the track is hidden, when it's part of a playlist.
    @Default(false) bool hidden,
  }) = _DownloadedTrack;

  /// Creates a downloaded track from a row of the downloaded tracks table,
  /// optionally joined with a playlist entry.
  factory DownloadedTrack.fromRow(Map<String, dynamic> row) => DownloadedTrack(
    track: Track.fromLocalRow(row),
    durationMilliseconds: row['duration'] as int,
    rowId: row['id'] as int,
    hidden: row['hidden'] == 1,
  );
}
