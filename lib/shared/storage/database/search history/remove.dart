import 'package:pongo/exports.dart';

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
