import 'package:pongo/exports.dart';

Future<List<Map<String, dynamic>>> queryAllFavouriteTrcks(
    DatabaseHelper dbHelper) async {
  Database db = await dbHelper.database;
  return await db.rawQuery('SELECT * FROM favourites');
}

Future<int> queryAllFavouriteTrcksLength(DatabaseHelper dbHelper) async {
  Database db = await dbHelper.database;
  final result = await db.rawQuery('SELECT COUNT(*) FROM favourites');
  return Sqflite.firstIntValue(result) ?? 0;
}

// Query length
Future<int> queryFvouritesLength(DatabaseHelper dbHelper) async {
  Database db = await dbHelper.database;
  final result = await db.rawQuery('SELECT COUNT(*) FROM favourites');
  return Sqflite.firstIntValue(result) ?? 0;
}

Future<bool> favouriteTrckAlreadyExists(
    DatabaseHelper dbHelper, String stid) async {
  Database db = await dbHelper.database;

  // Query the favourites table to check for the given stid
  final List<Map<String, dynamic>> result = await db.query(
    'favourites',
    columns: ['stid'], // Only need the stid column for the check
    where: 'stid = ?',
    whereArgs: [stid],
  );

  // If result is not empty, the track exists
  return result.isNotEmpty;
}
