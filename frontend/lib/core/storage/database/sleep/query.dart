// Artists

import 'package:sqflite/sqflite.dart';

import 'package:pongo/core/storage/database/database_helper.dart';
import 'package:pongo/features/sleep_alarm/models/sleep_alarm.dart';

Future<List<SleepAlarm>> querySleepAlrms(DatabaseHelper dbHelper) async {
  Database db = await dbHelper.database;

  // Query the max order for the given opid
  final List<Map<String, dynamic>> results = await db.query(
    'sleep',
    orderBy: 'id DESC', // Order by id in descending order
  );

  // Convert the results to a list of strings
  return results.map((e) => SleepAlarm.fromMap(e)).toList();
}

Future<int> querySleepAlrmsLength(DatabaseHelper dbHelper) async {
  Database db = await dbHelper.database;
  final result = await db.rawQuery('SELECT COUNT(*) FROM sleep');
  return Sqflite.firstIntValue(result) ?? 0;
}
