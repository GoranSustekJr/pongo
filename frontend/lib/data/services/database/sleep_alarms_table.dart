import 'package:sqflite/sqflite.dart';

import '../../../domain/models/sleep_alarm/sleep_alarm.dart';

/// The `sleep` table of sleep alarms.
class SleepAlarmsTable {
  /// Creates a table backed by [_db].
  SleepAlarmsTable(this._db);

  final Database _db;

  /// Inserts [alarm], ignoring its ID, and returns the new ID.
  Future<int> insert(SleepAlarm alarm) => _db.insert('sleep', _row(alarm));

  /// All alarms, newest first.
  Future<List<SleepAlarm>> queryAll() async {
    final rows = await _db.query('sleep', orderBy: 'id DESC');
    return rows.map(SleepAlarm.fromMap).toList();
  }

  /// The number of alarms.
  Future<int> count() async =>
      Sqflite.firstIntValue(await _db.rawQuery('SELECT COUNT(*) FROM sleep')) ??
      0;

  /// Saves the changes to [alarm].
  Future<void> update(SleepAlarm alarm) =>
      _db.update('sleep', _row(alarm), where: 'id = ?', whereArgs: [alarm.id]);

  /// Deletes the alarm with [id].
  Future<void> remove(int id) =>
      _db.delete('sleep', where: 'id = ?', whereArgs: [id]);

  Map<String, dynamic> _row(SleepAlarm alarm) => {
    'sleep': alarm.sleep ? 1 : 0,
    'sleep_duration': alarm.sleepDuration,
    'sleep_linear': alarm.sleepLinear ? 1 : 0,
    'alarm_clock': alarm.alarmClock ? 1 : 0,
    'wake_time': alarm.wakeTime,
    'before_end_time_min': alarm.beforeEndTimeMin,
    'alarm_clock_linear': alarm.alarmClockLinear ? 1 : 0,
  };
}
