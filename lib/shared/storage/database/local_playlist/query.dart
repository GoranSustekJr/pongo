import 'package:pongo/exports.dart';

Future<List<Map<String, dynamic>>> queryAllLoclPlaylists(
    DatabaseHelper dbHelper) async {
  Database db = await dbHelper.database;
  return await db.query('local_playlist');
}

Future<List<Map<String, dynamic>>> queryAllLoclPlaylistsTitles(
    DatabaseHelper dbHelper) async {
  Database db = await dbHelper.database;
  return await db.rawQuery("SELECT lpid, title FROM local_playlist");
}

Future<List<Map<String, dynamic>>> queryLoclTracksForPlaylist(
    DatabaseHelper dbHelper, int lpid) async {
  Database db = await dbHelper.database;
  final check = await db.rawQuery("SELECT * FROM lpid_track_id");
  print(" CHECL; $check");
  final result = await db.rawQuery('''
    SELECT ltid.track_id, ltid.order_number, dt.id, dt.stid, dt.audio, dt.artists, dt.title, dt.duration, dt.blurhash, dt.image
    FROM lpid_track_id ltid
    JOIN downloaded_tracks dt ON ltid.track_id = dt.stid
    WHERE ltid.lpid = ?
    ORDER BY ltid.order_number ASC
  ''', [lpid]);

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
