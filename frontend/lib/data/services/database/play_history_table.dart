import 'package:sqflite/sqflite.dart';

import 'package:pongo/core/storage/database/database_helper.dart';

// tracks
Future<void> insertTrackPlayHist(DatabaseHelper dbHelper, String qry) async {
  Database db = await dbHelper.database;
  await dbHelper.removeTrackHistoryEntry(qry);
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
  await dbHelper.removeArtistHistoryEntry(said);
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

// Tracks
Future<List<String>> queryTrackHist(DatabaseHelper dbHelper) async {
  Database db = await dbHelper.database;
  // Query the max order for the given opid
  final List<Map<String, dynamic>> maps =
      await db.query('lfh_tracks', columns: ['stid'], orderBy: 'id DESC');

  // Convert the results to a list of strings
  return List.generate(maps.length, (i) {
    return maps[i]['stid'] as String;
  });
}

// Artists
Future<List<String>> queryArtistHist(DatabaseHelper dbHelper) async {
  Database db = await dbHelper.database;
  // Query the max order for the given opid
  final List<Map<String, dynamic>> maps =
      await db.query('lfh_artists', columns: ['said'], orderBy: 'id DESC');

  // Convert the results to a list of strings
  return List.generate(maps.length, (i) {
    return maps[i]['said'] as String;
  });
}

// Num of racks
Future<List<String>> queryTrackHistNum(DatabaseHelper dbHelper, int num) async {
  Database db = await dbHelper.database;

  // Query the max order for the given opid
  final List<Map<String, dynamic>> maps =
      await db.query('lfh_tracks', columns: ['stid'], orderBy: 'id DESC');

  // Convert the results to a list of strings
  return List.generate(maps.length < num ? maps.length : num, (i) {
    return maps[i]['stid'] as String;
  });
}

// Artists
Future<List<String>> queryArtistHistNum(
    DatabaseHelper dbHelper, int num) async {
  Database db = await dbHelper.database;

  // Query the max order for the given opid
  final List<Map<String, dynamic>> maps =
      await db.query('lfh_artists', columns: ['said'], orderBy: 'id DESC');

  // Convert the results to a list of strings
  return List.generate(maps.length < num ? maps.length : num, (i) {
    return maps[i]['said'] as String;
  });
}

// Track

Future<void> removeTrackHistoryEtry(
    DatabaseHelper dbHelper, String stid) async {
  Database db = await dbHelper.database;

  await db.delete(
    'lfh_tracks',
    where: 'stid = ?',
    whereArgs: [stid],
  );
}

Future<void> clearTrackHistry(DatabaseHelper dbHelper) async {
  Database db = await dbHelper.database;

  await db.delete('lfh_tracks');
}

// Artist
Future<void> removeArtistHistoryEtry(
    DatabaseHelper dbHelper, String said) async {
  Database db = await dbHelper.database;

  await db.delete(
    'lfh_artists',
    where: 'said = ?',
    whereArgs: [said],
  );
}

Future<void> clearArtistHistry(DatabaseHelper dbHelper) async {
  Database db = await dbHelper.database;

  await db.delete('lfh_artists');
}
