import 'package:pongo/exports.dart';

Future<void> removeSearchHistoryEtry(
    DatabaseHelper dbHelper, String qry) async {
  Database db = await dbHelper.database;

  await db.delete(
    'search_history',
    where: 'query = ?',
    whereArgs: [qry],
  );
}

Future<void> clearSearchHistry(DatabaseHelper dbHelper) async {
  Database db = await dbHelper.database;

  await db.delete('search_history');
}
