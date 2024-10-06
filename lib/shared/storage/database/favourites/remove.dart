import 'package:pongo/exports.dart';

// Track
Future<void> removeFavouriteTrck(DatabaseHelper dbHelper, String stid) async {
  Database db = await dbHelper.database;

  await db.delete(
    'favourites',
    where: 'stid = ?',
    whereArgs: [stid],
  );
}
