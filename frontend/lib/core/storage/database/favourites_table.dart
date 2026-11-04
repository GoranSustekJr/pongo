import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'package:pongo/core/storage/database/database_helper.dart';
import 'package:pongo/features/library/models/favourite.dart';

Future<void> insertFavouriteTrck(
  DatabaseHelper dbHelper,
  Favourite favourite,
) async {
  Database db = await dbHelper.database;

  bool alreadyExists =
      await favouriteTrckAlreadyExists(dbHelper, favourite.stid);

  if (!alreadyExists) {
    Map<String, dynamic> trackData = {
      'stid': favourite.stid,
      'title': favourite.title,
      'artists': jsonEncode(favourite.artistTrack),
      'image': favourite.image,
      'album': favourite.albumTrack != null
          ? jsonEncode({
              "id": favourite.albumTrack!.id,
              "name": favourite.albumTrack!.name,
              "images": favourite.albumTrack!.images
                  .map((albumImagesTrack) => {
                        "url": albumImagesTrack.url,
                        "height": albumImagesTrack.height,
                        "width": albumImagesTrack.width,
                      })
                  .toList(),
            })
          : null,
    };

    await db.insert('favourites', trackData);
  }
}

Future<List<Favourite>> queryAllFavouriteTrcks(DatabaseHelper dbHelper) async {
  Database db = await dbHelper.database;
  List<Map<String, dynamic>> result =
      await db.rawQuery('SELECT * FROM favourites ORDER BY id DESC');
  return result.map((res) => Favourite.fromMap(res)).toList();
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
