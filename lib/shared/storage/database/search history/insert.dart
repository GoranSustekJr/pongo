import 'package:pongo/exports.dart';

Future<void> insertSearchHistorySrch(
    DatabaseHelper dbHelper, String qry) async {
  Database db = await dbHelper.database;
  await dbHelper.removeSearchHistoryEntry(qry);
  await db.transaction((txn) async {
    print(1);
    await txn.insert(
      'search_history',
      {'query': qry},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    final count = Sqflite.firstIntValue(
      await txn.rawQuery('SELECT COUNT(*) FROM search_history'),
    );

    if (count != null && count > 500) {
      await txn.rawDelete('''
          DELETE FROM search_history
          WHERE id NOT IN (
            SELECT id
            FROM search_history
            ORDER BY id DESC
            LIMIT 500
          )
        ''');
    }
  });
}
