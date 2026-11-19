import '../../../domain/models/sleep_alarm/sleep_alarm.dart';
import '../../services/database/database_service.dart';
import 'sleep_alarm_repository.dart';

/// A [SleepAlarmRepository] kept in the device database.
class SleepAlarmRepositoryLocal implements SleepAlarmRepository {
  /// Creates a repository backed by [_database].
  SleepAlarmRepositoryLocal({required this._database});

  final DatabaseService _database;

  @override
  Future<List<SleepAlarm>> alarms() => _database.sleepAlarms.queryAll();

  @override
  Future<int> count() => _database.sleepAlarms.count();

  @override
  Future<SleepAlarm> add(SleepAlarm alarm) async =>
      alarm.copyWith(id: await _database.sleepAlarms.insert(alarm));

  @override
  Future<void> update(SleepAlarm alarm) => _database.sleepAlarms.update(alarm);

  @override
  Future<void> remove(int id) => _database.sleepAlarms.remove(id);
}
