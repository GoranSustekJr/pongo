import 'package:pongo/exports.dart';

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
