import 'package:pongo/exports.dart';

// tracks
Future<void> insertTrackPlayHist(DatabaseHelper dbHelper, String qry) async {
  Database db = await dbHelper.database;
  await dbHelper.removeSearchHistoryEntry(qry);
  await db.transaction((txn) async {
    await txn.insert(
      'lfh_tracks',
      {'stid': qry},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    final count = Sqflite.firstIntValue(
      await txn.rawQuery('SELECT COUNT(*) FROM lfh_tracks'),
    );

    if (count != null && count > 500) {
      await txn.rawDelete('''
          DELETE FROM lfh_tracks
          WHERE id NOT IN (
            SELECT id
            FROM lfh_tracks
            ORDER BY id DESC
            LIMIT 500
          )
        ''');
    }
  });
}

// Artists
Future<void> insertArtistPlayHist(DatabaseHelper dbHelper, String said) async {
  Database db = await dbHelper.database;
  await dbHelper.removeSearchHistoryEntry(said);
  await db.transaction((txn) async {
    await txn.insert(
      'lfh_artists',
      {'said': said},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    final count = Sqflite.firstIntValue(
      await txn.rawQuery('SELECT COUNT(*) FROM lfh_artists'),
    );

    if (count != null && count > 500) {
      await txn.rawDelete('''
          DELETE FROM lfh_artists
          WHERE id NOT IN (
            SELECT id
            FROM lfh_artists
            ORDER BY id DESC
            LIMIT 500
          )
        ''');
    }
  });
}
