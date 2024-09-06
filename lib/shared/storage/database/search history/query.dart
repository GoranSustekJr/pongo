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
