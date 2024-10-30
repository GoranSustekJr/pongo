import 'package:pongo/exports.dart';
import 'package:pongo/shared/storage/database/lyrics_sync_time_delay/query.dart';

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
    print("Schon exisitert");
    await db.update(
        "lyrics_sync_time_delay",
        {
          "sync_time_delay": syncTimeDelay,
        },
        where: "stid = ?",
        whereArgs: [stid]);
  }
}
