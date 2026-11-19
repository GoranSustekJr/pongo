import 'dart:typed_data';

import 'package:sqflite/sqflite.dart';

import 'database_service.dart';

/// The `local_playlist` and `lpid_track_id` tables.
class LocalPlaylistsTable {
  /// Creates a table backed by [_db].
  LocalPlaylistsTable(this._db);

  final Database _db;

  /// Creates a playlist and returns its ID.
  Future<int> insert(String title, Uint8List? cover) =>
      _db.insert('local_playlist', {'title': title, 'cover': cover});

  /// Appends the track with [stid] to playlist [lpid].
  ///
  /// Returns the new row ID, or `null` if the playlist already holds it.
  Future<int?> insertTrack(int lpid, String stid) async {
    final existing = await _db.query(
      'lpid_track_id',
      where: 'lpid = ? AND track_id = ?',
      whereArgs: [lpid, stid],
    );
    if (existing.isNotEmpty) return null;

    final result = await _db.rawQuery(
      'SELECT MAX(order_number) as max_order FROM lpid_track_id WHERE lpid = ?',
      [lpid],
    );
    final maxOrder = result.first['max_order'] as int? ?? -1;
    return _db.insert('lpid_track_id', {
      'lpid': lpid,
      'track_id': stid,
      'order_number': maxOrder + 1,
    });
  }

  /// All playlists, newest first.
  Future<List<Map<String, dynamic>>> queryAll() =>
      _db.query('local_playlist', orderBy: 'lpid DESC');

  /// The ID and title of every playlist.
  Future<List<Map<String, dynamic>>> queryTitles() =>
      _db.rawQuery('SELECT lpid, title FROM local_playlist');

  /// The downloaded tracks in playlist [lpid], in playlist order.
  Future<List<Map<String, dynamic>>> queryTracks(int lpid) => _db.rawQuery(
    '''
    SELECT ltid.track_id, ltid.order_number, ltid.hidden, dt.id, dt.stid,
      dt.audio, dt.artists, dt.title, dt.duration, dt.image
    FROM lpid_track_id ltid
    JOIN downloaded_tracks dt ON ltid.track_id = dt.stid
    WHERE ltid.lpid = ?
    ORDER BY ltid.order_number ASC
  ''',
    [lpid],
  );

  /// The number of playlists.
  Future<int> count() async =>
      Sqflite.firstIntValue(
        await _db.rawQuery('SELECT COUNT(*) FROM local_playlist'),
      ) ??
      0;

  /// The number of tracks in playlist [lpid].
  Future<int> countTracks(int lpid) async =>
      Sqflite.firstIntValue(
        await _db.rawQuery(
          'SELECT COUNT(*) FROM lpid_track_id WHERE lpid = ?',
          [lpid],
        ),
      ) ??
      0;

  /// Rewrites the order of playlist [lpid] to match [stids], keeping which
  /// tracks are hidden.
  Future<void> updateOrder(int lpid, List<String> stids) async {
    await _db.transaction((txn) async {
      final hidden = {
        for (final row in await txn.query(
          'lpid_track_id',
          columns: ['track_id', 'hidden'],
          where: 'lpid = ?',
          whereArgs: [lpid],
        ))
          row['track_id']: row['hidden'],
      };
      await txn.delete('lpid_track_id', where: 'lpid = ?', whereArgs: [lpid]);
      for (var i = 0; i < stids.length; i++) {
        await txn.insert('lpid_track_id', {
          'lpid': lpid,
          'track_id': stids[i],
          'order_number': i + 1,
          'hidden': hidden[stids[i]],
        });
      }
    });
  }

  /// Renames playlist [lpid].
  Future<void> updateTitle(int lpid, String title) => _db.update(
    'local_playlist',
    {'title': title},
    where: 'lpid = ?',
    whereArgs: [lpid],
  );

  /// Replaces the cover of playlist [lpid].
  Future<void> updateCover(int lpid, Uint8List cover) => _db.update(
    'local_playlist',
    {'cover': cover},
    where: 'lpid = ?',
    whereArgs: [lpid],
  );

  /// Shows or hides the tracks with [stids] in playlist [lpid].
  Future<void> updateHidden(
    int lpid,
    List<String> stids, {
    required bool hidden,
  }) => _db.rawUpdate(
    'UPDATE lpid_track_id SET hidden = ? '
    'WHERE lpid = ? AND track_id IN (${placeholders(stids.length)})',
    [if (hidden) 1 else 0, lpid, ...stids],
  );

  /// Removes the tracks with [stids] from playlist [lpid].
  Future<void> removeTracks(int lpid, List<String> stids) => _db.delete(
    'lpid_track_id',
    where: 'lpid = ? AND track_id IN (${placeholders(stids.length)})',
    whereArgs: [lpid, ...stids],
  );

  /// Deletes playlist [lpid] and its entries.
  Future<void> remove(int lpid) => _db.transaction((txn) async {
    await txn.delete('lpid_track_id', where: 'lpid = ?', whereArgs: [lpid]);
    await txn.delete('local_playlist', where: 'lpid = ?', whereArgs: [lpid]);
  });
}
