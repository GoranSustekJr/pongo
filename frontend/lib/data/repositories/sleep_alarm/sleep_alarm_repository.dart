import '../../../domain/models/sleep_alarm/sleep_alarm.dart';

/// Source of truth for the user's sleep alarms.
abstract class SleepAlarmRepository {
  /// All alarms, newest first.
  Future<List<SleepAlarm>> alarms();

  /// The number of alarms.
  Future<int> count();

  /// Saves a new alarm like [alarm] and returns it with its ID.
  Future<SleepAlarm> add(SleepAlarm alarm);

  /// Saves the changes to [alarm].
  Future<void> update(SleepAlarm alarm);

  /// Deletes the alarm with [id].
  Future<void> remove(int id);
}
