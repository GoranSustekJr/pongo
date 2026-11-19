import 'dart:async';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:path_provider/path_provider.dart';

/// Appends what a sleep alarm does to `sleep_alarm.log` in the app's
/// documents directory.
///
/// Alarms run while the phone is locked, where no debugger can follow them,
/// so the log is the way to see why one didn't wake the user. It's cleared
/// when an alarm starts, so it only ever holds the latest one.
class SleepAlarmLog {
  File? _file;
  Future<void> _writes = Future.value();

  Future<File> _open() async => _file ??= File(
    '${(await getApplicationDocumentsDirectory()).path}/sleep_alarm.log',
  );

  /// Empties the log.
  void clear() => _queue((file) => file.writeAsString(''));

  /// Adds [message] with the current time.
  void add(String message) {
    final line = '${clock.now().toIso8601String()} $message\n';
    _queue((file) => file.writeAsString(line, mode: FileMode.append));
  }

  // Writes one at a time so lines keep their order.
  void _queue(Future<void> Function(File file) write) {
    _writes = _writes
        .then((_) async => write(await _open()))
        .catchError((Object _) {});
  }
}
