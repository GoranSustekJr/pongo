import 'package:pongo/exports.dart';

Future<void> removeTrackFromOnPlaylist(
    DatabaseHelper dbHelper, int opid, String trackId, int ordNum) async {
  Database db = await dbHelper.database;

  print("ORDDD; $ordNum");

  await db.delete(
    'opid_track_id',
    where: 'opid = ? AND track_id = ? AND order_number = ?',
    whereArgs: [opid, trackId, ordNum],
  );

  await db.rawUpdate(
    'UPDATE opid_track_id SET order_number = order_number - 1 WHERE opid = ? AND order_number > ?',
    [opid, ordNum],
  );
}

Future<void> removeOnPlaylist(DatabaseHelper dbHelper, int opid) async {
  Database db = await dbHelper.database;

  // Begin a transaction
  await db.transaction((txn) async {
    // Remove all tracks associated with the playlist
    await txn.delete(
      'opid_track_id',
      where: 'opid = ?',
      whereArgs: [opid],
    );

    // Remove the playlist itself
    await txn.delete(
      'online_playlist',
      where: 'opid = ?',
      whereArgs: [opid],
    );
  });
}

//TODO: HAPTIC update!
