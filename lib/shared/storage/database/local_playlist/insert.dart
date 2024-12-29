import 'package:pongo/exports.dart';

Future<int> insertLoclPlaylist(
    DatabaseHelper dbHelper, String title, Uint8List? cover) async {
  Database db = await dbHelper.database;

  Map<String, dynamic> row = {
    'title': title,
    'cover': cover,
  };
  print("INSERTED");
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
