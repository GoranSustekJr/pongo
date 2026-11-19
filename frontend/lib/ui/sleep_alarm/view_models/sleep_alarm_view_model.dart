import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/repositories/player/player_repository.dart';
import '../../../data/repositories/settings/settings_repository.dart';
import '../../../data/repositories/sleep_alarm/sleep_alarm_repository.dart';
import '../../../domain/models/sleep_alarm/sleep_alarm.dart';
import '../../core/messages/app_message.dart';
import '../../core/messages/message_center.dart';

/// The saved sleep alarms and the one running.
class SleepAlarmViewModel extends ChangeNotifier {
  /// Creates a view model and loads the alarms.
  SleepAlarmViewModel({
    required this._alarms,
    required this._player,
    required this._settings,
    required this._messages,
  }) {
    unawaited(load());
  }

  final SleepAlarmRepository _alarms;
  final PlayerRepository _player;
  final SettingsRepository _settings;
  final MessageCenter _messages;

  List<SleepAlarm> _sleepAlarms = [];
  bool _showBody = false;

  /// The saved alarms, newest first.
  List<SleepAlarm> get sleepAlarms => _sleepAlarms;

  /// Whether the alarms are loaded.
  bool get showBody => _showBody;

  /// The ID of the running alarm, or -1 if none is running.
  int get activeAlarm => _player.activeSleepAlarm;

  /// The highest device volume the alarm wakes up to.
  double get deviceVolume => _settings.settings.sleepAlarmDeviceVolume;

  /// Loads the alarms.
  Future<void> load() async {
    _showBody = true;
    notifyListeners();
    _sleepAlarms = await _alarms.alarms();
    notifyListeners();
  }

  /// Saves the new [alarm] and shows it first.
  Future<void> add(SleepAlarm alarm) async {
    _sleepAlarms = [await _alarms.add(alarm), ..._sleepAlarms];
    notifyListeners();
  }

  /// Saves the changes to [alarm].
  Future<void> update(SleepAlarm alarm) async {
    await _alarms.update(alarm);
    _sleepAlarms = [
      for (final saved in _sleepAlarms) saved.id == alarm.id ? alarm : saved,
    ];
    notifyListeners();
  }

  /// Starts the alarm at [index], or stops the running one when [index] is
  /// -1.
  Future<void> changeActiveSleepAlarm(int index) async {
    if (index == -1) {
      await _player.stopSleepAlarm();
    } else if (_player.queue.value.isEmpty) {
      _messages.show(
        ErrorMessage(
          title: (l10n) => l10n.cannotstartalarm,
          body: (l10n) => l10n.thequeuemustnotbeemptyinordertostartthealarm,
        ),
      );
    } else {
      await _player.startSleepAlarm(_sleepAlarms[index]);
    }
    notifyListeners();
  }

  /// Deletes the alarm at [index], stopping it first if it's running.
  Future<void> removeSleepAlarm(int index) async {
    final alarm = _sleepAlarms[index];
    if (_player.activeSleepAlarm == alarm.id) await _player.stopSleepAlarm();
    _sleepAlarms = [..._sleepAlarms]..removeAt(index);
    notifyListeners();
    await _alarms.remove(alarm.id);
  }

  /// Sets the highest device volume the alarm wakes up to.
  Future<void> updateSleepAlarmDeviceVolume(double volume) => _settings.update(
    (settings) => settings.copyWith(sleepAlarmDeviceVolume: volume),
  );
}
