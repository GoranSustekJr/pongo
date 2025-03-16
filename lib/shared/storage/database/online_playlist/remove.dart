import 'package:pongo/exports.dart';

Future<void> removeTrackFromOnPlaylist(
    DatabaseHelper dbHelper, OnlinePlaylistTrack onlinePlaylistTrack) async {
  Database db = await dbHelper.database;

  await db.delete(
    'opid_stid',
    where: 'opid = ? AND stid = ? AND order_number = ?',
    whereArgs: [
      onlinePlaylistTrack.opid,
      onlinePlaylistTrack.stid,
      onlinePlaylistTrack.orderNumber
    ],
  );

  await db.rawUpdate(
    'UPDATE opid_stid SET order_number = order_number - 1 WHERE opid = ? AND order_number > ?',
    [onlinePlaylistTrack.opid, onlinePlaylistTrack.orderNumber],
  );
}

Future<void> removeTracksFromOnPlaylist(
    DatabaseHelper dbHelper, int opid, List<String> stids) async {
  Database db = await dbHelper.database;

  await db.delete(
    'opid_stid',
    where:
        'opid = ? AND stid IN (${List.filled(stids.length, '?').join(', ')})',
    whereArgs: [opid, ...stids],
  );
}

Future<void> removeOnPlaylist(DatabaseHelper dbHelper, int opid) async {
  Database db = await dbHelper.database;

  // Begin a transaction
  await db.transaction((txn) async {
    // Remove all tracks associated with the playlist
    await txn.delete(
      'opid_stid',
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
