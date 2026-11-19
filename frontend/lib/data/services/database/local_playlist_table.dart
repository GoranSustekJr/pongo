import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import 'package:pongo/core/storage/database/database_helper.dart';

Future<int> insertLoclPlaylist(
    DatabaseHelper dbHelper, String title, Uint8List? cover) async {
  Database db = await dbHelper.database;

  Map<String, dynamic> row = {
    'title': title,
    'cover': cover,
  };
  return await db.insert('local_playlist', row);
}

Future<int?> insertLoclTrackId(
    DatabaseHelper dbHelper, int lpid, String stid) async {
  Database db = await dbHelper.database;
  // Get the current order count for the given lpid

  final List<Map<String, dynamic>> existingRows = await db.query(
    'lpid_track_id',
    where: 'lpid = ? AND track_id = ?',
    whereArgs: [lpid, stid],
  );

  if (existingRows.isNotEmpty) {
    return null;
  }

  int currentOrder = await queryOrderForLpid(dbHelper, lpid);

  Map<String, dynamic> row = {
    'lpid': lpid,
    'track_id': stid,
    'order_number': currentOrder + 1, // Increment order by 1
  };
  return await db.insert('lpid_track_id', row);
}

Future<int> queryOrderForLpid(DatabaseHelper dbHelper, int lpid) async {
  Database db = await dbHelper.database;

  // Query the max order for the given lpid
  List<Map<String, dynamic>> result = await db.rawQuery('''
    SELECT MAX(order_number) as max_order FROM lpid_track_id WHERE lpid = ?
  ''', [lpid]);

  int maxOrder = result.first['max_order'] ?? -1;
  return maxOrder;
}

Future<List<Map<String, dynamic>>> queryAllLoclPlaylists(
    DatabaseHelper dbHelper) async {
  Database db = await dbHelper.database;
  return await db.query('local_playlist', orderBy: 'lpid DESC');
}

Future<List<Map<String, dynamic>>> queryAllLoclPlaylistsTitles(
    DatabaseHelper dbHelper) async {
  Database db = await dbHelper.database;
  return await db.rawQuery("SELECT lpid, title FROM local_playlist");
}

Future<List<Map<String, dynamic>>> queryLoclTracksForPlaylist(
    DatabaseHelper dbHelper, int lpid) async {
  Database db = await dbHelper.database;

  final result = await db.rawQuery(
    '''
    SELECT ltid.track_id, ltid.order_number, ltid.hidden, dt.id, dt.stid, dt.audio, dt.artists, dt.title, dt.duration, dt.image
    FROM lpid_track_id ltid
    JOIN downloaded_tracks dt ON ltid.track_id = dt.stid
    WHERE ltid.lpid = ?
    ORDER BY ltid.order_number ASC
  ''',
    [lpid],
  );

  return result;
}

Future<int> queryLoclPlaylistsLength(DatabaseHelper dbHelper) async {
  Database db = await dbHelper.database;
  final result = await db.rawQuery('SELECT COUNT(*) FROM local_playlist');
  return Sqflite.firstIntValue(result) ?? 0;
}

Future<int> queryLoclTrackIdsForPlaylistLength(
    DatabaseHelper dbHelper, int lpid) async {
  Database db = await dbHelper.database;
  final result = await db
      .rawQuery('SELECT COUNT(*) FROM lpid_track_id WHERE lpid = $lpid');
  return Sqflite.firstIntValue(result) ?? 0;
}

Future<List<Map<String, dynamic>>> queryLoclTrackIdsForPlaylist(
    DatabaseHelper dbHelper, int lpid) async {
  Database db = await dbHelper.database;
  return await db.query('lpid_track_id',
      where: 'lpid = ?', whereArgs: [lpid], orderBy: 'order_number ASC');
}

Future<void> updateLoclPlaylistOrder(
    DatabaseHelper dbHelper, int lpid, List<String> newTrackOrder) async {
  Database db = await dbHelper.database;

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

Future<void> removeTrackFromLoclPlaylist(
    DatabaseHelper dbHelper, int lpid, String trackId, int ordNum) async {
  Database db = await dbHelper.database;

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

Future<void> removeTracksFromLoclPlaylist(
    DatabaseHelper dbHelper, int lpid, List<String> stids) async {
  Database db = await dbHelper.database;

  await db.delete(
    'lpid_track_id',
    where:
        'lpid = ? AND track_id IN (${List.filled(stids.length, '?').join(', ')})',
    whereArgs: [lpid, ...stids],
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
