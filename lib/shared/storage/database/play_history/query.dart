import 'package:pongo/exports.dart';

// Tracks
Future<List<String>> queryTrackHist(DatabaseHelper dbHelper) async {
  Database db = await dbHelper.database;
  // Query the max order for the given opid
  final List<Map<String, dynamic>> maps =
      await db.query('lfh_tracks', columns: ['stid'], orderBy: 'id DESC');

  // Convert the results to a list of strings
  return List.generate(maps.length, (i) {
    return maps[i]['stid'] as String;
  });
}

// Artists
Future<List<String>> queryArtistHist(DatabaseHelper dbHelper) async {
  Database db = await dbHelper.database;
  // Query the max order for the given opid
  final List<Map<String, dynamic>> maps =
      await db.query('lfh_artists', columns: ['said'], orderBy: 'id DESC');

  // Convert the results to a list of strings
  return List.generate(maps.length, (i) {
    return maps[i]['said'] as String;
  });
}
