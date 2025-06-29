import 'package:pongo/exports.dart';

// Track
Future<void> removeFavouriteTrck(
    DatabaseHelper dbHelper, Favourite favourite) async {
  Database db = await dbHelper.database;

  await db.delete(
    'favourites',
    where: 'stid = ?',
    whereArgs: [favourite.stid],
  );
}

Future<void> removeFavouriteTrcks(
    DatabaseHelper dbHelper, List<String> stids) async {
  Database db = await dbHelper.database;

  await db.delete(
    'favourites',
    where: 'stid IN (${List.filled(stids.length, '?').join(', ')})',
    whereArgs: stids,
  );
}
