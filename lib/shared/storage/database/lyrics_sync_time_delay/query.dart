import 'package:pongo/exports.dart';

Future<bool> syncTimeDelayAlreadyExists(
    DatabaseHelper dbHelper, String stid) async {
  Database db = await dbHelper.database;

  // Query the favourites table to check for the given stid
  final List<Map<String, dynamic>> result = await db.query(
    'lyrics_sync_time_delay',
    columns: ['stid'], // Only need the stid column for the check
    where: 'stid = ?',
    whereArgs: [stid],
  );

  // If result is not empty, the track exists
  return result.isNotEmpty;
}

Future<int?> querySyncTimeDlay(DatabaseHelper dbHelper, String stid) async {
  Database db = await dbHelper.database;
  final result = await db.query("lyrics_sync_time_delay",
      columns: ["sync_time_delay"], where: "stid = ?", whereArgs: [stid]);
  print("Result; $result");

  return result.isNotEmpty ? result[0]["sync_time_delay"] as int : null;
}
