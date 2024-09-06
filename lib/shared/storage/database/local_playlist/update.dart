import 'package:pongo/exports.dart';

Future<void> updateLoclPlaylistOrder(DatabaseHelper dbHelper, int lpid,
    int oldOrder, int newOrder, String trackId) async {
  Database db = await dbHelper.database;
  print("START;");
  print(await DatabaseHelper().queryLocalTracksForPlaylist(lpid));

  await db.transaction((txn) async {
    print("OLD; $oldOrder, NEW; $newOrder");
    if (newOrder < oldOrder) {
      // Moving up
      await txn.rawUpdate(
        "UPDATE lpid_track_id SET order_number = order_number + 1 WHERE lpid = ? AND order_number >= ? AND order_number < ? AND track_id != ?",
        [lpid, newOrder, oldOrder, trackId],
      );
    } else if (newOrder > oldOrder) {
      // Moving Locl
      await txn.rawUpdate(
        "UPDATE lpid_track_id SET order_number = order_number - 1 WHERE lpid = ? AND order_number > ? AND order_number <= ? AND track_id != ?",
        [lpid, oldOrder, newOrder, trackId],
      );
    }

    // update the order number of the moved item
    await txn.rawUpdate(
      "UPDATE lpid_track_id SET order_number = ? WHERE lpid = ? AND order_number = ? AND track_id = ?",
      [newOrder, lpid, oldOrder, trackId],
    );
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
