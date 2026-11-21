import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_desktop_context_menu/flutter_desktop_context_menu.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:provider/provider.dart';

import '../../../../domain/models/sleep_alarm/sleep_alarm.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../app/view_models/app_settings_view_model.dart';
import '../../../core/app_icons.dart';
import '../../../core/themes/colors.dart';
import '../../../core/ui/desktop/track_list_macos.dart';
import '../../view_models/sleep_alarm_view_model.dart';

/// The sleep alarms: music that fades out to sleep and back in to wake up,
/// in the content area of the Mac window.
class SleepAlarmMacos extends StatefulWidget {
  /// Creates the sleep alarm page.
  const SleepAlarmMacos({super.key});

  @override
  State<SleepAlarmMacos> createState() => _SleepAlarmMacosState();
}

class _SleepAlarmMacosState extends State<SleepAlarmMacos> {
  late final SleepAlarmViewModel viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = SleepAlarmViewModel(
      alarms: context.read(),
      player: context.read(),
      settings: context.read(),
      messages: context.read(),
    );
  }

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  Future<void> _edit([SleepAlarm? alarm]) async {
    final saved = await showMacosSheet<SleepAlarm>(
      context: context,
      builder: (_) => _SleepAlarmSheet(alarm: alarm),
    );
    if (saved == null) return;
    await (alarm == null ? viewModel.add(saved) : viewModel.update(saved));
  }

  Future<void> _remove(int index) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await confirmMacos(
      context,
      title: l10n.sleep,
      message: l10n.areyousure,
      confirm: l10n.delete,
    );
    if (confirmed) await viewModel.removeSleepAlarm(index);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = MacosTheme.of(context);
    return MacosScaffold(
      backgroundColor: Col.transp,
      toolBar: ToolBar(
        title: Text(l10n.sleepandalarmclock),
        titleWidth: 300,
        decoration: const BoxDecoration(color: Col.transp),
        enableBlur: true,
        automaticallyImplyLeading: false,
        actions: [
          ToolBarIconButton(
            label: l10n.createnewsleepalarm,
            tooltipMessage: l10n.createnewsleepalarm,
            icon: const MacosIcon(CupertinoIcons.add),
            showLabel: false,
            onPressed: _edit,
          ),
        ],
      ),
      children: [
        ContentArea(
          builder: (context, scrollController) => ListenableBuilder(
            listenable: viewModel,
            builder: (context, _) {
              final alarms = viewModel.sleepAlarms;
              return ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                children: [
                  _VolumeRow(viewModel: viewModel),
                  const SizedBox(height: 24),
                  if (alarms.isEmpty)
                    EmptyStateMacos(
                      icon: AppIcons.sleep,
                      title: l10n.createnewsleepalarm,
                      action: PushButton(
                        controlSize: ControlSize.large,
                        onPressed: _edit,
                        child: Text(l10n.create),
                      ),
                    ),
                  for (final (index, alarm) in alarms.indexed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _AlarmCard(
                        alarm: alarm,
                        active: viewModel.activeAlarm == alarm.id,
                        onActive: (active) => viewModel.changeActiveSleepAlarm(
                          active ? index : -1,
                        ),
                        onEdit: () => _edit(alarm),
                        onMenu: () => popUpContextMenu(
                          Menu(
                            items: [
                              MenuItem(
                                label: l10n.edit,
                                onClick: (_) => _edit(alarm),
                              ),
                              MenuItem(
                                label: l10n.delete,
                                onClick: (_) => _remove(index),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (alarms.isNotEmpty)
                    Text(
                      l10n.donotterminatetheapp,
                      style: theme.typography.caption1.copyWith(
                        color: secondaryTextMacos,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

String _time(int minutesAfterMidnight) {
  final hours = (minutesAfterMidnight ~/ 60).toString().padLeft(2, '0');
  final minutes = (minutesAfterMidnight % 60).toString().padLeft(2, '0');
  return '$hours:$minutes';
}

class _VolumeRow extends StatelessWidget {
  const _VolumeRow({required this.viewModel});

  final SleepAlarmViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = MacosTheme.of(context);
    return Row(
      children: [
        const MacosIcon(CupertinoIcons.speaker_1_fill, size: 16),
        const SizedBox(width: 10),
        Text(l10n.maximumvolumeofthealarm, style: theme.typography.body),
        const SizedBox(width: 16),
        SizedBox(
          width: 220,
          child: MacosSlider(
            value: viewModel.deviceVolume,
            onChanged: viewModel.updateSleepAlarmDeviceVolume,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '${(viewModel.deviceVolume * 100).round()} %',
          style: theme.typography.subheadline.copyWith(
            color: secondaryTextMacos,
          ),
        ),
      ],
    );
  }
}

class _AlarmCard extends StatelessWidget {
  const _AlarmCard({
    required this.alarm,
    required this.active,
    required this.onActive,
    required this.onEdit,
    required this.onMenu,
  });

  final SleepAlarm alarm;
  final bool active;
  final ValueChanged<bool> onActive;
  final VoidCallback onEdit;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = MacosTheme.of(context);
    final minutes = l10n.minutesshort;
    final secondary = theme.typography.subheadline.copyWith(
      color: secondaryTextMacos,
    );
    return GestureDetector(
      onDoubleTap: onEdit,
      onSecondaryTap: onMenu,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: MacosColors.systemGrayColor.withAlpha(active ? 60 : 30),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active
                ? theme.primaryColor
                : MacosColors.systemGrayColor.withAlpha(40),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (alarm.alarmClock)
                    Text(
                      _time(alarm.wakeTime),
                      style: theme.typography.largeTitle.copyWith(
                        fontWeight: FontWeight.w300,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  if (alarm.sleep)
                    Text(
                      '${l10n.sleepin}: ${alarm.sleepDuration} $minutes',
                      style: alarm.alarmClock
                          ? secondary
                          : theme.typography.title2,
                    ),
                  if (alarm.alarmClock)
                    Text(
                      '${l10n.alarm}: ${alarm.beforeEndTimeMin} $minutes '
                      '${l10n.beforeyouneedtowakeupat} '
                      '${_time(alarm.wakeTime)}',
                      style: secondary,
                    ),
                ],
              ),
            ),
            MacosIconButton(
              icon: const MacosIcon(CupertinoIcons.pencil),
              onPressed: onEdit,
            ),
            const SizedBox(width: 8),
            MacosSwitch(value: active, onChanged: onActive),
          ],
        ),
      ),
    );
  }
}

/// Makes a new alarm, or changes [alarm], and closes with the result.
class _SleepAlarmSheet extends StatefulWidget {
  const _SleepAlarmSheet({this.alarm});

  final SleepAlarm? alarm;

  @override
  State<_SleepAlarmSheet> createState() => _SleepAlarmSheetState();
}

class _SleepAlarmSheetState extends State<_SleepAlarmSheet> {
  static const _durations = [5, 10, 15, 20, 30, 45, 60, 90, 120, 180];

  late SleepAlarm alarm =
      widget.alarm ??
      SleepAlarm(
        id: -1,
        sleepLinear: context.readSettings.linearSleepIn,
        alarmClockLinear: context.readSettings.linearWakeUp,
      );

  List<int> _choices(int current) =>
      ({..._durations, current}.toList()..sort());

  Widget _minutes(int value, ValueChanged<int> onChanged) {
    final l10n = AppLocalizations.of(context);
    return MacosPopupButton<int>(
      value: value,
      items: [
        for (final minutes in _choices(value))
          MacosPopupMenuItem(
            value: minutes,
            child: Text('$minutes ${l10n.minutesshort}'),
          ),
      ],
      onChanged: (minutes) {
        if (minutes != null) onChanged(minutes);
      },
    );
  }

  Widget _row(String label, Widget control) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        SizedBox(
          width: 200,
          child: Text(label, style: MacosTheme.of(context).typography.body),
        ),
        control,
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = MacosTheme.of(context);
    final size = MediaQuery.sizeOf(context);
    final canSave = alarm.sleep || alarm.alarmClock;
    return MacosSheet(
      insetPadding: EdgeInsets.symmetric(
        horizontal: (size.width - 520).clamp(0, double.infinity) / 2,
        vertical: (size.height - 470).clamp(0, double.infinity) / 2,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.createnewsleepalarm, style: theme.typography.headline),
            const SizedBox(height: 12),
            _row(
              l10n.sleepin,
              MacosSwitch(
                value: alarm.sleep,
                onChanged: (sleep) =>
                    setState(() => alarm = alarm.copyWith(sleep: sleep)),
              ),
            ),
            if (alarm.sleep) ...[
              _row(
                l10n.pongowillgraduallylowerthevolumefor,
                _minutes(
                  alarm.sleepDuration,
                  (minutes) => setState(
                    () => alarm = alarm.copyWith(sleepDuration: minutes),
                  ),
                ),
              ),
              _row(
                l10n.linearsleepin,
                MacosCheckbox(
                  value: alarm.sleepLinear,
                  onChanged: (linear) => setState(
                    () => alarm = alarm.copyWith(sleepLinear: linear),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            _row(
              l10n.alarm,
              MacosSwitch(
                value: alarm.alarmClock,
                onChanged: (on) =>
                    setState(() => alarm = alarm.copyWith(alarmClock: on)),
              ),
            ),
            if (alarm.alarmClock) ...[
              _row(
                l10n.beforeyouneedtowakeupat,
                MacosTimePicker(
                  initialTime: TimeOfDay(
                    hour: alarm.wakeTime ~/ 60,
                    minute: alarm.wakeTime % 60,
                  ),
                  style: TimePickerStyle.textual,
                  onTimeChanged: (time) => setState(
                    () => alarm = alarm.copyWith(
                      wakeTime: time.hour * 60 + time.minute,
                    ),
                  ),
                ),
              ),
              _row(
                l10n.pongowillgraduallyincreasethevolume,
                _minutes(
                  alarm.beforeEndTimeMin,
                  (minutes) => setState(
                    () => alarm = alarm.copyWith(beforeEndTimeMin: minutes),
                  ),
                ),
              ),
              _row(
                l10n.linearalarm,
                MacosCheckbox(
                  value: alarm.alarmClockLinear,
                  onChanged: (linear) => setState(
                    () => alarm = alarm.copyWith(alarmClockLinear: linear),
                  ),
                ),
              ),
            ],
            const Spacer(),
            if (!canSave)
              Text(
                l10n.cannotcreateasleepalarmwithoutthe,
                style: theme.typography.caption1.copyWith(
                  color: MacosColors.systemRedColor,
                ),
              ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                PushButton(
                  controlSize: ControlSize.large,
                  secondary: true,
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.cancel),
                ),
                const SizedBox(width: 8),
                PushButton(
                  controlSize: ControlSize.large,
                  onPressed: canSave
                      ? () => Navigator.of(context).pop(alarm)
                      : null,
                  child: Text(widget.alarm == null ? l10n.create : l10n.done),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
