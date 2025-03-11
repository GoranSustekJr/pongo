import 'package:pongo/exports.dart';

Future<void> updateSleepAlrm(
    DatabaseHelper dbHelper, SleepAlarm sleepAlarm) async {
  Database db = await dbHelper.database;
  await db.update(
    'sleep',
    {
      'id': sleepAlarm.id, //
      'sleep': sleepAlarm.sleep,
      'sleep_duration': sleepAlarm.sleepDuration,
      'sleep_linear': sleepAlarm.sleepLinear,
      'alarm_clock': sleepAlarm.alarmClock,
      'wake_time': sleepAlarm.wakeTime,
      'before_end_time_min': sleepAlarm.beforeEndTimeMin,
      'alarm_clock_linear': sleepAlarm.alarmClockLinear,
    },
    where: 'id = ?',
    whereArgs: [sleepAlarm.id],
  );
}
