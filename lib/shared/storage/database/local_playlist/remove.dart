import 'package:pongo/exports.dart';

Future<void> removeTrackFromLoclPlaylist(
    DatabaseHelper dbHelper, int lpid, String trackId, int ordNum) async {
  Database db = await dbHelper.database;

  print("ORDDD; $ordNum");

  await db.delete(
    'lpid_track_id',
    where: 'lpid = ? AND track_id = ? AND order_number = ?',
    whereArgs: [lpid, trackId, ordNum],
  );

  await db.rawUpdate(
    'UPDATE lpid_track_id SET order_number = order_number - 1 WHERE lpid = ? AND order_number > ?',
    [lpid, ordNum],
  );
}

Future<void> removeLoclPlaylist(DatabaseHelper dbHelper, int lpid) async {
  Database db = await dbHelper.database;

  // Begin a transaction
  await db.transaction((txn) async {
    // Remove all tracks associated with the playlist
    await txn.delete(
      'lpid_track_id',
      where: 'lpid = ?',
      whereArgs: [lpid],
    );

    // Remove the playlist itself
    await txn.delete(
      'local_playlist',
      where: 'lpid = ?',
      whereArgs: [lpid],
    );
  });
}
