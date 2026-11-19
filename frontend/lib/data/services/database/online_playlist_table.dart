import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import 'package:pongo/core/storage/database/database_helper.dart';
import 'package:pongo/features/playlists/models/online_playlist_track.dart';

Future<int> insertOnPlaylist(
    DatabaseHelper dbHelper, String title, Uint8List? cover) async {
  Database db = await dbHelper.database;
  Map<String, dynamic> row = {
    'title': title,
    'cover': cover,
  };
  return await db.insert('online_playlist', row);
}

Future<int?> insertOnTrackId(
    DatabaseHelper dbHelper, OnlinePlaylistTrack onlinePlaylistTrack) async {
  Database db = await dbHelper.database;

  // Check the current number of tracks in the playlist
  /* int trackCount = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM opid_track_id WHERE opid = ?',
        [opid],
      )) ??
      0;

  // Ensure the playlist has fewer than 150 tracks
   if (trackCount >= 150) {
    Notifications().showWarningNotification(searchScreenContext.value!,
        "Playlist has exceeded the maximum number of tracks, 150");
    return null; // Or return a value indicating the insertion was skipped
  } */

  final List<Map<String, dynamic>> existingRows = await db.query(
    'opid_stid',
    where: 'opid = ? AND stid = ?',
    whereArgs: [onlinePlaylistTrack.opid, onlinePlaylistTrack.stid],
  );

  // Ensure that the playlist does not contains this track
  if (existingRows.isNotEmpty) {
    return null;
  }

  // Get the current order count for the given opid
  int currentOrder =
      await queryOrderForOpid(dbHelper, onlinePlaylistTrack.opid);

  Map<String, dynamic> row = {
    'opid': onlinePlaylistTrack.opid,
    'stid': onlinePlaylistTrack.stid,
    'title': onlinePlaylistTrack.title,
    'artists': jsonEncode(onlinePlaylistTrack.artistTrack),
    'image': onlinePlaylistTrack.image,
    'album': onlinePlaylistTrack.albumTrack != null
        ? jsonEncode({
            "id": onlinePlaylistTrack.albumTrack!.id,
            "name": onlinePlaylistTrack.albumTrack!.name,
            "images": onlinePlaylistTrack.albumTrack!.images
                .map((albumImagesTrack) => {
                      "url": albumImagesTrack.url,
                      "height": albumImagesTrack.height,
                      "width": albumImagesTrack.width,
                    })
                .toList(),
          })
        : null,
    'order_number': currentOrder + 1, // Increment order by 1
  };

  return await db.insert('opid_stid', row);
}

Future<List<Map<String, dynamic>>> queryAllOnPlaylists(
    DatabaseHelper dbHelper) async {
  Database db = await dbHelper.database;
  return await db.query('online_playlist', orderBy: 'opid DESC');
}

Future<List<Map<String, dynamic>>> queryAllOnPlaylistsTitles(
    DatabaseHelper dbHelper) async {
  Database db = await dbHelper.database;
  return await db
      .rawQuery("SELECT opid, title FROM online_playlist ORDER BY opid DESC");
}

Future<List<OnlinePlaylistTrack>> queryOnTracksForPlaylist(
    DatabaseHelper dbHelper, int opid) async {
  Database db = await dbHelper.database;
  List<Map<String, dynamic>> result = await db.query('opid_stid',
      where: 'opid = ?', whereArgs: [opid], orderBy: 'order_number ASC');
  return result.map((res) => OnlinePlaylistTrack.fromMap(res)).toList();
}

Future<int> queryOnPlaylistsLength(DatabaseHelper dbHelper) async {
  Database db = await dbHelper.database;
  final result = await db.rawQuery('SELECT COUNT(*) FROM online_playlist');
  return Sqflite.firstIntValue(result) ?? 0;
}

Future<int> queryOnTracksForPlaylistLength(
    DatabaseHelper dbHelper, int opid) async {
  Database db = await dbHelper.database;
  final result = await db.rawQuery(
      'SELECT COUNT(*) FROM opid_stid WHERE opid = $opid AND hidden = ${false}');
  return Sqflite.firstIntValue(result) ?? 0;
}

Future<int> queryOrderForOpid(DatabaseHelper dbHelper, int opid) async {
  Database db = await dbHelper.database;
  // Query the max order for the given opid
  List<Map<String, dynamic>> result = await db.rawQuery('''
    SELECT MAX(order_number) as max_order FROM opid_stid WHERE opid = ?
  ''', [opid]);

  int maxOrder = result.first['max_order'] ?? -1;
  return maxOrder;
}

Future<void> updateOnPlaylistOrder(DatabaseHelper dbHelper, int opid,
    List<OnlinePlaylistTrack> newTrackOrder) async {
  Database db = await dbHelper.database;

  // Start a transaction to ensure atomicity
  await db.transaction((txn) async {
    // Delete all existing order numbers for the given opid
    await txn.rawDelete(
      "DELETE FROM opid_stid WHERE opid = ?",
      [opid],
    );

    // Insert the tracks with the new order
    for (int i = 0; i < newTrackOrder.length; i++) {
      await txn.rawInsert(
        "INSERT INTO opid_stid (opid, stid, title, artists, image, album, order_number) VALUES (?, ?, ?, ?, ?, ?, ?)",
        [
          opid,
          newTrackOrder[i].stid,
          newTrackOrder[i].title,
          jsonEncode(newTrackOrder[i].artistTrack),
          newTrackOrder[i].image,
          newTrackOrder[i].albumTrack != null
              ? jsonEncode({
                  "id": newTrackOrder[i].albumTrack!.id,
                  "name": newTrackOrder[i].albumTrack!.name,
                  "images": newTrackOrder[i]
                      .albumTrack!
                      .images
                      .map((albumImagesTrack) => {
                            "url": albumImagesTrack.url,
                            "height": albumImagesTrack.height,
                            "width": albumImagesTrack.width,
                          })
                      .toList(),
                })
              : null,
          i + 1
        ], // `i + 1` to set the order starting from 1
      );
    }
  });

/*  
  print(await DatabaseHelper().queryOnlineTrackIdsForPlaylist(opid)); */
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

Future<void> updateOnPlaylistShow(
    DatabaseHelper dHelper, int opid, List<String> stids) async {
  Database db = await dHelper.database;
  final placeholders = List.filled(stids.length, '?').join(', ');

  await db.rawUpdate(
    'UPDATE opid_stid SET hidden = ? WHERE opid = ? AND stid IN ($placeholders)',
    [false, opid, ...stids],
  );
}

Future<void> updateOnPlaylistHide(
    DatabaseHelper dHelper, int opid, List<String> stids) async {
  Database db = await dHelper.database;
  final placeholders = List.filled(stids.length, '?').join(', ');

  await db.rawUpdate(
      'UPDATE opid_stid SET hidden = ? WHERE opid = ? AND stid IN ($placeholders)',
      [true, opid, ...stids]);
}

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
