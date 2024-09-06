import 'package:pongo/exports.dart';

Future<List<Map<String, dynamic>>> queryAllDownloadedTrcks(
    DatabaseHelper dbHelper) async {
  Database db = await dbHelper.database;
  return await db
      .rawQuery('SELECT * FROM downloaded_tracks ORDER BY title ASC');
}

Future<int> queryAllDownloadedTrcksLength(DatabaseHelper dbHelper) async {
  Database db = await dbHelper.database;
  final result = await db.rawQuery('SELECT COUNT(*) FROM downloaded_tracks');
  return Sqflite.firstIntValue(result) ?? 0;
}

Future<bool> downloadedTrckAlreadyExists(
    DatabaseHelper dbHelper, String stid) async {
  Database db = await dbHelper.database;

  // Query the downloaded_tracks table to check for the given stid
  final List<Map<String, dynamic>> result = await db.query(
    'downloaded_tracks',
    columns: ['stid'], // Only need the stid column for the check
    where: 'stid = ?',
    whereArgs: [stid],
  );

  // If result is not empty, the track exists
  return result.isNotEmpty;
}
