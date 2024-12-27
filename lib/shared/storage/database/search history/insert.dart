import 'package:pongo/exports.dart';

Future<void> insertSearchHistorySrch(
    DatabaseHelper dbHelper, String qry) async {
  Database db = await dbHelper.database;
  await dbHelper.removeSearchHistoryEntry(qry);
  await db.transaction((txn) async {
    print(1);
    await txn.insert(
      'search_history',
      {'query': qry},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    final count = Sqflite.firstIntValue(
      await txn.rawQuery('SELECT COUNT(*) FROM search_history'),
    );

    if (count != null && count > 500) {
      await txn.rawDelete('''
          DELETE FROM search_history
          WHERE id NOT IN (
            SELECT id
            FROM search_history
            ORDER BY id DESC
            LIMIT 500
          )
        ''');
    }
  });
}

Future<void> insertLFHArtsts(DatabaseHelper dbHelper, String said) async {
  Database db = await dbHelper.database;
  await dbHelper.removeLFHArtists(said);
  await db.transaction((txn) async {
    print(1);
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

Future<void> insertLFHTrcks(DatabaseHelper dbHelper, String stid) async {
  Database db = await dbHelper.database;
  await dbHelper.removeLFHTracks(stid);
  print("object; $stid");
  await db.transaction((txn) async {
    print(1);
    await txn.insert(
      'lfh_tracks',
      {'stid': stid},
      conflictAlgorithm: ConflictAlgorithm.ignore,
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
