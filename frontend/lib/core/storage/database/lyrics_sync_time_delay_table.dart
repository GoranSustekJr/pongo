import 'package:sqflite/sqflite.dart';

import 'package:pongo/core/storage/database/database_helper.dart';

Future<void> insertSyncTimeDlay(
  DatabaseHelper dbHelper,
  String stid,
  int syncTimeDelay,
) async {
  Database db = await dbHelper.database;

  bool alreadyExists = await syncTimeDelayAlreadyExists(dbHelper, stid);

  if (!alreadyExists) {
    Map<String, dynamic> trackData = {
      'stid': stid,
      'sync_time_delay': syncTimeDelay,
    };

    await db.insert('lyrics_sync_time_delay', trackData);
  } else {
    await db.update(
        "lyrics_sync_time_delay",
        {
          "sync_time_delay": syncTimeDelay,
        },
        where: "stid = ?",
        whereArgs: [stid]);
  }
}

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

  return result.isNotEmpty ? result[0]["sync_time_delay"] as int : null;
}
