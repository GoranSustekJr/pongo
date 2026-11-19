import 'package:sqflite/sqflite.dart';

import 'database_service.dart';

/// The `track_gain` table: decibels each track is played at so tracks sound
/// about equally loud, as the server measured them.
class TrackGainsTable {
  /// Creates a table backed by [_db].
  TrackGainsTable(this._db);

  final Database _db;

  /// Creates the table.
  static Future<void> create(Database db) => db.execute('''
    CREATE TABLE IF NOT EXISTS track_gain (
      stid TEXT PRIMARY KEY,
      gain REAL NOT NULL
    )
  ''');

  /// The stored gains of the tracks with [stids].
  Future<Map<String, double>> query(List<String> stids) async {
    if (stids.isEmpty) return {};
    final rows = await _db.query(
      'track_gain',
      where: 'stid IN (${placeholders(stids.length)})',
      whereArgs: stids,
    );
    return {
      for (final row in rows)
        row['stid']! as String: (row['gain']! as num).toDouble(),
    };
  }

  /// Stores [gains], replacing earlier values.
  Future<void> upsert(Map<String, double> gains) async {
    final batch = _db.batch();
    for (final MapEntry(:key, :value) in gains.entries) {
      batch.insert('track_gain', {
        'stid': key,
        'gain': value,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }
}
