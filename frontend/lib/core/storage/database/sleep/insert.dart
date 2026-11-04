// Insert sleep alarm
import 'package:pongo/exports.dart';

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
