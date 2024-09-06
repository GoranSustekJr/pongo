import 'package:pongo/exports.dart';

Future<void> updateOnPlaylistOrder(DatabaseHelper dbHelper, int opid,
    int oldOrder, int newOrder, String trackId) async {
  Database db = await dbHelper.database;
  print("START;");
  print(await DatabaseHelper().queryOnlineTrackIdsForPlaylist(opid));

  await db.transaction((txn) async {
    print("OLD; $oldOrder, NEW; $newOrder");
    if (newOrder < oldOrder) {
      // Moving up
      await txn.rawUpdate(
        "UPDATE opid_track_id SET order_number = order_number + 1 WHERE opid = ? AND order_number >= ? AND order_number < ? AND track_id != ?",
        [opid, newOrder, oldOrder, trackId],
      );
    } else if (newOrder > oldOrder) {
      // Moving down
      await txn.rawUpdate(
        "UPDATE opid_track_id SET order_number = order_number - 1 WHERE opid = ? AND order_number > ? AND order_number <= ? AND track_id != ?",
        [opid, oldOrder, newOrder, trackId],
      );
    }

    // update the order number of the moved item
    await txn.rawUpdate(
      "UPDATE opid_track_id SET order_number = ? WHERE opid = ? AND order_number = ? AND track_id = ?",
      [newOrder, opid, oldOrder, trackId],
    );
  });
  print("END;");
  print(await DatabaseHelper().queryOnlineTrackIdsForPlaylist(opid));
}

Future<void> updateOnPlaylistName(
    DatabaseHelper dbHelper, int opid, String title) async {
  Database db = await dbHelper.database;
  await db.update(
    'online_playlist',
    {'title': title},
    where: 'opid = ?',
    whereArgs: [opid],
  );
}

Future<void> updateOnPlaylistCover(
    DatabaseHelper dbHelper, int opid, Uint8List cover) async {
  Database db = await dbHelper.database;
  await db.update(
    'online_playlist',
    {'cover': cover},
    where: 'opid = ?',
    whereArgs: [opid],
  );
}
