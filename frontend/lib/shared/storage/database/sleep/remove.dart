import 'package:pongo/exports.dart';

Future<void> removeSleepAlarmEtry(DatabaseHelper dbHelper, int id) async {
  Database db = await dbHelper.database;

  await db.delete(
    'sleep',
    where: 'id = ?',
    whereArgs: [id],
  );
}
