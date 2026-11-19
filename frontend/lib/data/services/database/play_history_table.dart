import 'package:sqflite/sqflite.dart';

/// The `lfh_tracks` and `lfh_artists` tables of recently played tracks and
/// artists, each capped at 500 entries.
///
/// `played_at` is when the entry was last played, in milliseconds since the
/// epoch, so histories synced from other devices merge in order.
class PlayHistoryTable {
  /// Creates a table backed by [_db].
  PlayHistoryTable(this._db);

  final Database _db;

  /// Moves the track with [stid] to the top of the history.
  Future<void> insertTrack(String stid) => _insert('lfh_tracks', 'stid', stid);

  /// Moves the artist with [said] to the top of the history.
  Future<void> insertArtist(String said) =>
      _insert('lfh_artists', 'said', said);

  /// The latest played track IDs, at most [limit] of them.
  Future<List<String>> queryTracks({int? limit}) =>
      _query('lfh_tracks', 'stid', limit: limit);

  /// The latest played artist IDs, at most [limit] of them.
  Future<List<String>> queryArtists({int? limit}) =>
      _query('lfh_artists', 'said', limit: limit);

  /// Removes the track with [stid] from the history.
  Future<void> removeTrack(String stid) =>
      _db.delete('lfh_tracks', where: 'stid = ?', whereArgs: [stid]);

  /// Removes the artist with [said] from the history.
  Future<void> removeArtist(String said) =>
      _db.delete('lfh_artists', where: 'said = ?', whereArgs: [said]);

  Future<void> _insert(String table, String column, String id) async {
    await _db.delete(table, where: '$column = ?', whereArgs: [id]);
    await _db.transaction((txn) async {
      await txn.insert(table, {
        column: id,
        'played_at': DateTime.now().millisecondsSinceEpoch,
      });
      await txn.rawDelete('''
        DELETE FROM $table WHERE id NOT IN (
          SELECT id FROM $table ORDER BY played_at DESC, id DESC LIMIT 500
        )
      ''');
    });
  }

  Future<List<String>> _query(String table, String column, {int? limit}) async {
    final rows = await _db.query(
      table,
      columns: [column],
      orderBy: 'played_at DESC, id DESC',
      limit: limit,
    );
    return [for (final row in rows) row[column] as String];
  }
}
