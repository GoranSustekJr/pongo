import 'package:pongo/exports.dart';

Future<void> updateLoclPlaylistOrder(
    DatabaseHelper dbHelper, int lpid, List<String> newTrackOrder) async {
  Database db = await dbHelper.database;
  print("START;");
  print(await DatabaseHelper().queryLocalTracksForPlaylist(lpid));

  // Start a transaction to ensure atomicity
  await db.transaction((txn) async {
    // Delete all existing order numbers for the given lpid
    await txn.rawDelete(
      "DELETE FROM lpid_track_id WHERE lpid = ?",
      [lpid],
    );

    // Insert the tracks with the new order
    for (int i = 0; i < newTrackOrder.length; i++) {
      await txn.rawInsert(
        "INSERT INTO lpid_track_id (lpid, track_id, order_number) VALUES (?, ?, ?)",
        [
          lpid,
          newTrackOrder[i],
          i + 1
        ], // `i + 1` to set the order starting from 1
      );
    }
  });
  print("END;");
  print(await DatabaseHelper().queryLocalTracksForPlaylist(lpid));
}

Future<void> updateLoclPlaylistName(
    DatabaseHelper dbHelper, int lpid, String title) async {
  Database db = await dbHelper.database;
  await db.update(
    'local_playlist',
    {'title': title},
    where: 'lpid = ?',
    whereArgs: [lpid],
  );
}

Future<void> updateLoclPlaylistCover(
    DatabaseHelper dbHelper, int lpid, Uint8List cover) async {
  Database db = await dbHelper.database;
  await db.update(
    'local_playlist',
    {'cover': cover},
    where: 'lpid = ?',
    whereArgs: [lpid],
  );
}

Future<void> updateLoclPlaylistShow(
    DatabaseHelper dHelper, int lpid, List<String> stids) async {
  Database db = await dHelper.database;
  final placeholders = List.filled(stids.length, '?').join(', ');

  await db.rawUpdate(
    'UPDATE lpid_track_id SET hidden = ? WHERE lpid = ? AND track_id IN ($placeholders)',
    [false, lpid, ...stids],
  );
}

Future<void> updateLoclPlaylistHide(
    DatabaseHelper dHelper, int lpid, List<String> stids) async {
  Database db = await dHelper.database;
  final placeholders = List.filled(stids.length, '?').join(', ');

  await db.rawUpdate(
      'UPDATE lpid_track_id SET hidden = ? WHERE lpid = ? AND track_id IN ($placeholders)',
      [true, lpid, ...stids]);
}
