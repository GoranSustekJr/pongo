import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart' as syspaths;
import 'package:sqflite/sqflite.dart';

import 'package:pongo/core/storage/database/database_helper.dart';

Future<void> insertDownloadedTrck(
  DatabaseHelper dbHelper,
  String stid,
  String audio,
  List<Map<String, dynamic>> artists,
  String title,
  int duration,
  String? image,
) async {
  Database db = await dbHelper.database;

  bool alreadyExists = await downloadedTrckAlreadyExists(dbHelper, stid);

  if (!alreadyExists) {
    Map<String, dynamic> trackData = {
      'stid': stid,
      'audio': audio,
      'artists': jsonEncode(artists),
      'title': title,
      'duration': duration,
      'image': image,
    };

    await db.insert('downloaded_tracks', trackData);
  }
}

Future<List<Map<String, dynamic>>> queryAllDownloadedTrcks(
    DatabaseHelper dbHelper) async {
  Database db = await dbHelper.database;
  return await db
      .rawQuery('SELECT * FROM downloaded_tracks ORDER BY title ASC');
}

Future<int> queryAllDownloadedTrcksLength(DatabaseHelper dbHelper) async {
  Database db = await dbHelper.database;
  final result = await db.rawQuery('SELECT COUNT(*) FROM downloaded_tracks');
  return Sqflite.firstIntValue(result) ?? 0;
}

Future<bool> downloadedTrckAlreadyExists(
    DatabaseHelper dbHelper, String stid) async {
  Database db = await dbHelper.database;

  // Query the downloaded_tracks table to check for the given stid
  final List<Map<String, dynamic>> result = await db.query(
    'downloaded_tracks',
    columns: ['stid'], // Only need the stid column for the check
    where: 'stid = ?',
    whereArgs: [stid],
  );

  // If result is not empty, the track exists
  return result.isNotEmpty;
}

Future<List<String>> queryMssingStids(
    List<String> stids, DatabaseHelper dbHelper) async {
  String placeholders = List.generate(stids.length, (_) => '?').join(', ');

  Database db = await dbHelper.database;

  List<Map<String, dynamic>> results = await db.rawQuery(
    "SELECT stid FROM downloaded_tracks WHERE stid IN ($placeholders)",
    stids,
  );

  List<String> exsitingStids =
      results.map((row) => row['stid'] as String).toList();

  List<String> missingStids =
      stids.where((stid) => !exsitingStids.contains(stid)).toList();

  return missingStids;
}

// Track
Future<void> removeDownloadedTrck(
    DatabaseHelper dbHelper, String stid, int id) async {
  Database db = await dbHelper.database;

  await db.delete(
    'downloaded_tracks',
    where: 'stid = ? AND id = ?',
    whereArgs: [stid, id],
  );

  List<Map<String, dynamic>> playlists = await db.query(
    'lpid_track_id',
    columns: ['lpid', 'order_number'],
    where: 'track_id = ?',
    whereArgs: [stid],
  );

  // Prepare a map to store the results
  Map<String, List<Map<String, dynamic>>> playlistTracksMap = {};

  for (var playlist in playlists) {
    String lpid = playlist['lpid'].toString();

    // Query tracks in the current playlist ordered by order_number
    List<Map<String, dynamic>> tracksInPlaylist = await db.query(
      'lpid_track_id',
      where: 'lpid = ?',
      whereArgs: [lpid],
      orderBy: 'order_number ASC',
    );

    // Store the tracks in the map
    playlistTracksMap[lpid] = tracksInPlaylist;
  }
/*   List<Map<String, dynamic>> playlists = await db.query(
    'lpid_track_id',
    columns: ['lpid', 'order_number'],
    where: 'track_id = ?',
    whereArgs: [stid],
  );
 */

  for (var entry in playlistTracksMap.entries) {
    String lpid = entry.key;
    List<Map<String, dynamic>> tracks = entry.value;

    // Remove the track from the playlist
    for (var track in tracks) {
      if (track['track_id'] == stid) {
        await db.delete(
          'lpid_track_id',
          where: 'lpid = ? AND track_id = ? AND order_number = ?',
          whereArgs: [lpid, stid, track['order_number']],
        );
      }
    }

    // Step 2: Reorder remaining tracks
    int order = 1;
    for (var track in tracks) {
      if (track['track_id'] != stid) {
        await db.update(
          'lpid_track_id',
          {'order_number': order},
          where: 'lpid = ? AND track_id = ? AND order_number = ?',
          whereArgs: [lpid, track['track_id'], track['order_number']],
        );
        order++;
      }
    }
  }
}

Future<void> removeDownloadedTrcks(
    DatabaseHelper dbHelper, List<String> stids) async {
  Database db = await dbHelper.database;

  // Step 1: Delete tracks from 'downloaded_tracks' table
  await db.delete(
    'downloaded_tracks',
    where: 'stid IN (${List.generate(stids.length, (_) => '?').join(', ')})',
    whereArgs: stids,
  );

  // Step 2: Query playlists affected by the removed tracks
  List<Map<String, dynamic>> playlists = await db.query(
    'lpid_track_id',
    columns: ['lpid', 'track_id'],
    where:
        'track_id IN (${List.generate(stids.length, (_) => '?').join(', ')})',
    whereArgs: stids,
  );

  // Prepare a map to group playlists by lpid
  Map<String, List<Map<String, dynamic>>> playlistTracksMap = {};

  for (var playlist in playlists) {
    String lpid = playlist['lpid'].toString();

    // Query tracks in the current playlist
    List<Map<String, dynamic>> tracksInPlaylist = await db.query(
      'lpid_track_id',
      where: 'lpid = ?',
      whereArgs: [lpid],
      orderBy: 'order_number ASC', // Ensure tracks are ordered by order_number
    );

    playlistTracksMap[lpid] = tracksInPlaylist;
  }

  final appDir = await syspaths.getApplicationDocumentsDirectory();

  // Step 3: Remove tracks from each playlist and reorder remaining ones
  for (var entry in playlistTracksMap.entries) {
    String lpid = entry.key;
    List<Map<String, dynamic>> tracks = entry.value;

    // Remove the tracks by track_id
    for (var track in tracks.toList()) {
      if (stids.contains(track['track_id'])) {
        await db.delete(
          'lpid_track_id',
          where: 'lpid = ? AND track_id = ?',
          whereArgs: [lpid, track['track_id']],
        );

        // Remove from app data folder
        try {
          final audioFile = File('${appDir.path}/${track['track_id']}.m4a');
          await audioFile.delete();
        } catch (e) {
          //  print(e);
        }
        // Remove the track from the list to avoid reprocessing
        tracks.remove(track);
      }
    }

    // Step 4: Reorder remaining tracks in the playlist
    int order = 1;
    for (var track in tracks) {
      await db.update(
        'lpid_track_id',
        {'order_number': order},
        where: 'lpid = ? AND track_id = ?',
        whereArgs: [lpid, track['track_id']],
      );
      order++;
    }
  }
}
