import 'package:pongo/exports.dart';

// Track

Future<void> removeTrackHistoryEtry(
    DatabaseHelper dbHelper, String stid) async {
  Database db = await dbHelper.database;

  await db.delete(
    'lfh_tracks',
    where: 'stid = ?',
    whereArgs: [stid],
  );
}

Future<void> clearTrackHistry(DatabaseHelper dbHelper) async {
  Database db = await dbHelper.database;

  await db.delete('lfh_tracks');
}

// Artist
Future<void> removeArtistHistoryEtry(
    DatabaseHelper dbHelper, String said) async {
  Database db = await dbHelper.database;

  await db.delete(
    'lfh_artists',
    where: 'said = ?',
    whereArgs: [said],
  );
}

Future<void> clearArtistHistry(DatabaseHelper dbHelper) async {
  Database db = await dbHelper.database;

  await db.delete('lfh_artists');
}
