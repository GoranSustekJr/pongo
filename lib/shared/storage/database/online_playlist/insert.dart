import 'package:pongo/exports.dart';

Future<int> insertOnPlaylist(
    DatabaseHelper dbHelper, String title, Uint8List? cover) async {
  Database db = await dbHelper.database;
  Map<String, dynamic> row = {
    'title': title,
    'cover': cover,
  };
  print("INSERTED");
  return await db.insert('online_playlist', row);
}

Future<int> insertOnTrackId(
    DatabaseHelper dbHelper, int opid, String stid) async {
  Database db = await dbHelper.database;
  // Get the current order count for the given opid
  int currentOrder = await queryOrderForOpid(dbHelper, opid);

  Map<String, dynamic> row = {
    'opid': opid,
    'track_id': stid,
    'order_number': currentOrder + 1, // Increment order by 1
  };
  return await db.insert('opid_track_id', row);
}
