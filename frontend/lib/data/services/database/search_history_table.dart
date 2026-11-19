import 'package:sqflite/sqflite.dart';

import 'package:pongo/core/storage/database/database_helper.dart';

Future<void> insertSearchHistorySrch(
    DatabaseHelper dbHelper, String qry) async {
  Database db = await dbHelper.database;
  await dbHelper.removeSearchHistoryEntry(qry);
  await db.transaction((txn) async {
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
  await db.transaction((txn) async {
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

Future<List<String>> querySearchHistorySrch(DatabaseHelper dbHelper) async {
  Database db = await dbHelper.database;
  // Query the max order for the given opid
  final List<Map<String, dynamic>> maps =
      await db.query('search_history', columns: ['query'], orderBy: 'id DESC');

  // Convert the results to a list of strings
  return List.generate(maps.length, (i) {
    return maps[i]['query'] as String;
  });
}

Future<List<String>> queryLFHArtstsBy50(DatabaseHelper dbHelper) async {
  Database db = await dbHelper.database;
  // Query the max order for the given opid
  final List<Map<String, dynamic>> maps = await db.query('lfh_artists',
      columns: ['said'], orderBy: 'id DESC', limit: 50);

  // Convert the results to a list of strings
  return List.generate(maps.length, (i) {
    return maps[i]['said'] as String;
  });
}

Future<List<String>> queryLFHArtstsBy5(DatabaseHelper dbHelper) async {
  Database db = await dbHelper.database;
  // Query the max order for the given opid
  final List<Map<String, dynamic>> maps = await db.query('lfh_artists',
      columns: ['said'], orderBy: 'id DESC', limit: 5);

  // Convert the results to a list of strings
  return List.generate(maps.length, (i) {
    return maps[i]['said'] as String;
  });
}

Future<List<String>> queryLFHTrcksBy50(DatabaseHelper dbHelper) async {
  Database db = await dbHelper.database;
  // Query the max order for the given opid
  final List<Map<String, dynamic>> maps = await db.query('lfh_tracks',
      columns: ['stid'], orderBy: 'id DESC', limit: 50);

  // Convert the results to a list of strings
  return List.generate(maps.length, (i) {
    return maps[i]['stid'] as String;
  });
}

Future<List<String>> queryLFHTrcksBy5(DatabaseHelper dbHelper) async {
  Database db = await dbHelper.database;
  // Query the max order for the given opid
  final List<Map<String, dynamic>> maps = await db.query('lfh_tracks',
      columns: ['stid'], orderBy: 'RANDOM()', limit: 5);

  // Convert the results to a list of strings
  return List.generate(maps.length, (i) {
    return maps[i]['stid'] as String;
  });
}

Future<void> removeSearchHistoryEtry(
    DatabaseHelper dbHelper, String qry) async {
  Database db = await dbHelper.database;

  await db.delete(
    'search_history',
    where: 'query = ?',
    whereArgs: [qry],
  );
}

Future<void> clearSearchHistry(DatabaseHelper dbHelper) async {
  Database db = await dbHelper.database;

  await db.delete('search_history');
}

Future<void> removeLFHArtsts(DatabaseHelper dbHelper, String said) async {
  Database db = await dbHelper.database;

  await db.delete(
    'lfh_artists',
    where: 'said = ?',
    whereArgs: [said],
  );
}

Future<void> clearLFHArtsts(DatabaseHelper dbHelper) async {
  Database db = await dbHelper.database;

  await db.delete('lfh_artists');
}

Future<void> removeLFHTrcks(DatabaseHelper dbHelper, String stid) async {
  Database db = await dbHelper.database;

  await db.rawDelete(
    'DELETE FROM lfh_tracks WHERE stid = ?',
    [stid],
  );
}

Future<void> clearLFHTrcks(DatabaseHelper dbHelper) async {
  Database db = await dbHelper.database;

  await db.delete('lfh_tracks');
}
