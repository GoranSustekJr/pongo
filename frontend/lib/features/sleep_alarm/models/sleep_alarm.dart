class SleepAlarm {
  final int id;
  final bool sleep;
  final int sleepDuration;
  final bool sleepLinear;
  final bool alarmClock;
  final int wakeTime;
  final int beforeEndTimeMin;
  final bool alarmClockLinear;

  SleepAlarm({
    required this.id,
    this.sleep = true,
    this.sleepDuration = 30,
    this.sleepLinear = true,
    this.alarmClock = false,
    this.wakeTime = 450, // 7:30 am
    this.beforeEndTimeMin = 30,
    this.alarmClockLinear = true,
  });

  factory SleepAlarm.fromMap(Map<String, dynamic> map) {
    return SleepAlarm(
      id: map['id'],
      sleep: map['sleep'] == 1,
      sleepDuration: map['sleep_duration'],
      sleepLinear: map['sleep_linear'] == 1,
      alarmClock: map['alarm_clock'] == 1,
      wakeTime: map['wake_time'],
      beforeEndTimeMin: map['before_end_time_min'],
      alarmClockLinear: map['alarm_clock_linear'] == 1,
    );
  }
}
