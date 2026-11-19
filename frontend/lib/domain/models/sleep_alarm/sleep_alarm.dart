import 'package:freezed_annotation/freezed_annotation.dart';

part 'sleep_alarm.freezed.dart';

/// A sleep timer that fades the music out, optionally followed by an alarm
/// that fades it back in.
@freezed
abstract class SleepAlarm with _$SleepAlarm {
  /// Creates a sleep alarm.
  const factory SleepAlarm({
    required int id,

    /// Whether the music fades out.
    @Default(true) bool sleep,

    /// Minutes the fade out takes.
    @Default(30) int sleepDuration,
    @Default(true) bool sleepLinear,

    /// Whether the music fades back in at [wakeTime].
    @Default(false) bool alarmClock,

    /// Minutes after midnight the fade in ends. Defaults to 7:30 am.
    @Default(450) int wakeTime,

    /// Minutes the fade in takes.
    @Default(30) int beforeEndTimeMin,
    @Default(true) bool alarmClockLinear,
  }) = _SleepAlarm;

  /// Creates an alarm from a row of the sleep table.
  factory SleepAlarm.fromMap(Map<String, dynamic> map) => SleepAlarm(
    id: map['id'] as int,
    sleep: map['sleep'] == 1,
    sleepDuration: map['sleep_duration'] as int,
    sleepLinear: map['sleep_linear'] == 1,
    alarmClock: map['alarm_clock'] == 1,
    wakeTime: map['wake_time'] as int,
    beforeEndTimeMin: map['before_end_time_min'] as int,
    alarmClockLinear: map['alarm_clock_linear'] == 1,
  );
}
