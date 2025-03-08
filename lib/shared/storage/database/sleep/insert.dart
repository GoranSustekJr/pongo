// Insert sleep alarm
import 'package:pongo/exports.dart';

Future<void> insertAlarm(
  DatabaseHelper dbHelper, {
  bool sleep = true,
  int sleepDuration = 30,
  bool sleepLinear = true,
  bool alarmClock = false,
  TimeOfDay wakeTime = const TimeOfDay(hour: 7, minute: 30),
  int beforeEndTimeMin = 30,
  bool alarmClockLinear = true,
}) async {
  // init db
  Database db = await dbHelper.database;

  // Insert sleep alarm
  await db.transaction((txn) async {
    await txn.insert(
      'sleep',
      {
        'sleep': sleep,
        'sleep_duration': sleepDuration,
        'sleep_linear': sleepLinear,
        'alarm_clock': alarmClock,
        'wake_time': wakeTime.hour * 60 + wakeTime.minute,
        'before_end_time_min': beforeEndTimeMin,
        'linear_alarm_clock': alarmClockLinear,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    /*  final count = Sqflite.firstIntValue(
      await txn.rawQuery('SELECT COUNT(*) FROM sleep'),
    ); */

    /*  if (count != null && count > 500) {
      await txn.rawDelete('''
          DELETE FROM sleep
          WHERE id NOT IN (
            SELECT id
            FROM sleep
            ORDER BY id DESC
            LIMIT 500
          )
        ''');
    } */
  });
}
/* 

bool sleep = true,
    int sleepDuration = 30,
    bool sleepLinear = true,
    bool alarmClock = false,
    TimeOfDay wakeTime = const TimeOfDay(hour: 7, minute: 30),
    int beforeEndTimeMin = 30,
    bool alarmClockLinear = true,


 */
