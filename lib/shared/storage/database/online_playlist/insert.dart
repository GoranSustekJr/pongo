import 'package:pongo/exports.dart';

Future<int> insertOnPlaylist(
    DatabaseHelper dbHelper, String title, Uint8List? cover) async {
  Database db = await dbHelper.database;
  Map<String, dynamic> row = {
    'title': title,
    'cover': cover,
  };
  print("INSERTED");
  return await db.insert('online_playlist', row);
}

Future<int?> insertOnTrackId(
    DatabaseHelper dbHelper, int opid, String stid) async {
  Database db = await dbHelper.database;

  // Check the current number of tracks in the playlist
  int trackCount = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM opid_track_id WHERE opid = ?',
        [opid],
      )) ??
      0;

  // Ensure the playlist has fewer than 150 tracks
  if (trackCount >= 150) {
    print("Playlist already has the maximum number of tracks.");
    Notifications().showWarningNotification(searchScreenContext.value!,
        "Playlist has exceeded the maximum number of tracks, 150");
    return null; // Or return a value indicating the insertion was skipped
  }

  final List<Map<String, dynamic>> existingRows = await db.query(
    'opid_track_id',
    where: 'opid = ? AND track_id = ?',
    whereArgs: [opid, stid],
  );

  // Ensure that the playlist does not contains this track
  if (existingRows.isNotEmpty) {
    Notifications().showWarningNotification(
        searchScreenContext.value!,
        AppLocalizations.of(mainContext.value!)!
            .playlistalreadycontainsthistrack);

    return null;
  }

  // Get the current order count for the given opid
  int currentOrder = await queryOrderForOpid(dbHelper, opid);

  Map<String, dynamic> row = {
    'opid': opid,
    'track_id': stid,
    'order_number': currentOrder + 1, // Increment order by 1
  };

  return await db.insert('opid_track_id', row);
}
