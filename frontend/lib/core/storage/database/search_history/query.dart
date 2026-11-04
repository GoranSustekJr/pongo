import 'package:pongo/exports.dart';

Future<List<String>> querySearchHistorySrch(DatabaseHelper dbHelper) async {
  Database db = await dbHelper.database;
  // Query the max order for the given opid
  final List<Map<String, dynamic>> maps =
      await db.query('search_history', columns: ['query'], orderBy: 'id DESC');

  // Convert the results to a list of strings
  return List.generate(maps.length, (i) {
    return maps[i]['query'] as String;
  });
}

Future<List<String>> queryLFHArtstsBy50(DatabaseHelper dbHelper) async {
  Database db = await dbHelper.database;
  // Query the max order for the given opid
  final List<Map<String, dynamic>> maps = await db.query('lfh_artists',
      columns: ['said'], orderBy: 'id DESC', limit: 50);

  // Convert the results to a list of strings
  return List.generate(maps.length, (i) {
    return maps[i]['said'] as String;
  });
}

Future<List<String>> queryLFHArtstsBy5(DatabaseHelper dbHelper) async {
  Database db = await dbHelper.database;
  // Query the max order for the given opid
  final List<Map<String, dynamic>> maps = await db.query('lfh_artists',
      columns: ['said'], orderBy: 'id DESC', limit: 5);

  // Convert the results to a list of strings
  return List.generate(maps.length, (i) {
    return maps[i]['said'] as String;
  });
}

Future<List<String>> queryLFHTrcksBy50(DatabaseHelper dbHelper) async {
  Database db = await dbHelper.database;
  // Query the max order for the given opid
  final List<Map<String, dynamic>> maps = await db.query('lfh_tracks',
      columns: ['stid'], orderBy: 'id DESC', limit: 50);

  // Convert the results to a list of strings
  return List.generate(maps.length, (i) {
    return maps[i]['stid'] as String;
  });
}

Future<List<String>> queryLFHTrcksBy5(DatabaseHelper dbHelper) async {
  Database db = await dbHelper.database;
  // Query the max order for the given opid
  final List<Map<String, dynamic>> maps = await db.query('lfh_tracks',
      columns: ['stid'], orderBy: 'RANDOM()', limit: 5);

  // Convert the results to a list of strings
  return List.generate(maps.length, (i) {
    return maps[i]['stid'] as String;
  });
}
