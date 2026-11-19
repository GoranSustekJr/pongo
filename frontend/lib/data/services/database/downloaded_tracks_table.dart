import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'database_service.dart';

/// The `downloaded_tracks` table.
class DownloadedTracksTable {
  /// Creates a table backed by [_db].
  DownloadedTracksTable(this._db);

  final Database _db;

  /// Inserts a downloaded track unless one with [stid] already exists.
  Future<void> insert({
    required String stid,
    required String audioPath,
    required List<Map<String, dynamic>> artists,
    required String title,
    required int durationMilliseconds,
    required String? imagePath,
  }) async {
    if (await contains(stid)) return;
    await _db.insert('downloaded_tracks', {
      'stid': stid,
      'audio': audioPath,
      'artists': jsonEncode(artists),
      'title': title,
      'duration': durationMilliseconds,
      'image': imagePath,
    });
  }

  /// All downloaded tracks, sorted by title.
  Future<List<Map<String, dynamic>>> queryAll() =>
      _db.rawQuery('SELECT * FROM downloaded_tracks ORDER BY title ASC');

  /// The number of downloaded tracks.
  Future<int> count() async =>
      Sqflite.firstIntValue(
        await _db.rawQuery('SELECT COUNT(*) FROM downloaded_tracks'),
      ) ??
      0;

  /// Whether the track with [stid] is downloaded.
  Future<bool> contains(String stid) async {
    final rows = await _db.query(
      'downloaded_tracks',
      columns: ['stid'],
      where: 'stid = ?',
      whereArgs: [stid],
    );
    return rows.isNotEmpty;
  }

  /// The IDs in [stids] that aren't downloaded, in their original order.
  Future<List<String>> queryMissing(List<String> stids) async {
    final rows = await _db.rawQuery(
      'SELECT stid FROM downloaded_tracks '
      'WHERE stid IN (${placeholders(stids.length)})',
      stids,
    );
    final existing = {for (final row in rows) row['stid'] as String};
    return stids.where((stid) => !existing.contains(stid)).toList();
  }

  /// Removes the tracks with [stids] and their local playlist entries,
  /// renumbering the playlists that held them.
  Future<void> removeAll(List<String> stids) async {
    final inClause = placeholders(stids.length);
    await _db.delete(
      'downloaded_tracks',
      where: 'stid IN ($inClause)',
      whereArgs: stids,
    );

    final affected = await _db.query(
      'lpid_track_id',
      columns: ['lpid'],
      distinct: true,
      where: 'track_id IN ($inClause)',
      whereArgs: stids,
    );
    for (final row in affected) {
      final lpid = row['lpid'];
      await _db.delete(
        'lpid_track_id',
        where: 'lpid = ? AND track_id IN ($inClause)',
        whereArgs: [lpid, ...stids],
      );
      final remaining = await _db.query(
        'lpid_track_id',
        where: 'lpid = ?',
        whereArgs: [lpid],
        orderBy: 'order_number ASC',
      );
      var order = 1;
      for (final track in remaining) {
        await _db.update(
          'lpid_track_id',
          {'order_number': order++},
          where: 'lpid = ? AND track_id = ?',
          whereArgs: [lpid, track['track_id']],
        );
      }
    }
  }
}
