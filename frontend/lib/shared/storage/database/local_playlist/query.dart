import 'package:pongo/exports.dart';

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
