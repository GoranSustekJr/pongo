import 'package:pongo/exports.dart';

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
