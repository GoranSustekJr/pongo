import 'package:sqflite/sqflite.dart';

/// The `lyrics_sync_time_delay` table of manual lyrics offsets.
class LyricsSyncDelaysTable {
  /// Creates a table backed by [_db].
  LyricsSyncDelaysTable(this._db);

  final Database _db;

  /// Stores [milliseconds] as the offset of the track with [stid].
  Future<void> upsert(String stid, int milliseconds) async {
    final updated = await _db.update(
      'lyrics_sync_time_delay',
      {'sync_time_delay': milliseconds},
      where: 'stid = ?',
      whereArgs: [stid],
    );
    if (updated == 0) {
      await _db.insert('lyrics_sync_time_delay', {
        'stid': stid,
        'sync_time_delay': milliseconds,
      });
    }
  }

  /// The offset in milliseconds of the track with [stid], if one was saved.
  Future<int?> query(String stid) async {
    final rows = await _db.query(
      'lyrics_sync_time_delay',
      columns: ['sync_time_delay'],
      where: 'stid = ?',
      whereArgs: [stid],
    );
    return rows.isEmpty ? null : rows.first['sync_time_delay'] as int?;
  }
}
