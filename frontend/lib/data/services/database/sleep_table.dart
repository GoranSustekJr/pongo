import 'package:sqflite/sqflite.dart';

import 'package:pongo/core/storage/database/database_helper.dart';
import 'package:pongo/features/sleep_alarm/models/sleep_alarm.dart';

// Insert sleep alarm

Future<int> insertSleepAlrm(
    DatabaseHelper dbHelper, SleepAlarm sleepAlarm) async {
  // init db
  Database db = await dbHelper.database;

  // Insert sleep alarm
  return await db.transaction((txn) async {
    int id = await txn.insert(
      'sleep',
      {
        'sleep': sleepAlarm.sleep ? 1 : 0,
        'sleep_duration': sleepAlarm.sleepDuration,
        'sleep_linear': sleepAlarm.sleepLinear ? 1 : 0,
        'alarm_clock': sleepAlarm.alarmClock ? 1 : 0,
        'wake_time': sleepAlarm.wakeTime,
        'before_end_time_min': sleepAlarm.beforeEndTimeMin,
        'alarm_clock_linear': sleepAlarm.alarmClockLinear ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return id;
  });
}

// Artists

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

Future<void> updateSleepAlrm(
    DatabaseHelper dbHelper, SleepAlarm sleepAlarm) async {
  Database db = await dbHelper.database;
  await db.update(
    'sleep',
    {
      'id': sleepAlarm.id, //
      'sleep': sleepAlarm.sleep ? 1 : 0,
      'sleep_duration': sleepAlarm.sleepDuration,
      'sleep_linear': sleepAlarm.sleepLinear ? 1 : 0,
      'alarm_clock': sleepAlarm.alarmClock ? 1 : 0,
      'wake_time': sleepAlarm.wakeTime,
      'before_end_time_min': sleepAlarm.beforeEndTimeMin,
      'alarm_clock_linear': sleepAlarm.alarmClockLinear ? 1 : 0,
    },
    where: 'id = ?',
    whereArgs: [sleepAlarm.id],
  );
}

Future<void> removeSleepAlarmEtry(DatabaseHelper dbHelper, int id) async {
  Database db = await dbHelper.database;

  await db.delete(
    'sleep',
    where: 'id = ?',
    whereArgs: [id],
  );
}
