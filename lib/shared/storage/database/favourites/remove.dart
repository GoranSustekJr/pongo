import 'package:pongo/exports.dart';

// Track
Future<void> removeFavouriteTrck(
    DatabaseHelper dbHelper, String stid, int id) async {
  Database db = await dbHelper.database;

  await db.delete(
    'favourites',
    where: 'stid = ? AND id = ?',
    whereArgs: [stid, id],
  );
}
