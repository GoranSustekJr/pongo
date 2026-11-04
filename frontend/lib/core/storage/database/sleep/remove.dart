import 'package:sqflite/sqflite.dart';

import 'package:pongo/core/storage/database/database_helper.dart';

Future<void> removeSleepAlarmEtry(DatabaseHelper dbHelper, int id) async {
  Database db = await dbHelper.database;

  await db.delete(
    'sleep',
    where: 'id = ?',
    whereArgs: [id],
  );
}
