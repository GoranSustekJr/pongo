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

Future<List<String>> queryMssingStids(
    List<String> stids, DatabaseHelper dbHelper) async {
  String placeholders = List.generate(stids.length, (_) => '?').join(', ');

  Database db = await dbHelper.database;

  List<Map<String, dynamic>> results = await db.rawQuery(
    "SELECT stid FROM downloaded_tracks WHERE stid IN ($placeholders)",
    stids,
  );

  List<String> exsitingStids =
      results.map((row) => row['stid'] as String).toList();

  List<String> missingStids =
      stids.where((stid) => !exsitingStids.contains(stid)).toList();

  return missingStids;
}
