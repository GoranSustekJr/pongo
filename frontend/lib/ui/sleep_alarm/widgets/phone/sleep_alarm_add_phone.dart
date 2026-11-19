import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../domain/models/sleep_alarm/sleep_alarm.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/notifications.dart';
import '../../../core/themes/colors.dart';
import '../../../core/ui/buttons/text_button.dart';
import '../../../core/ui/space.dart';

class SleepAlarmAddPhone extends StatefulWidget {
  final SleepAlarm? sleepAlarm;
  final Future<void> Function(SleepAlarm) insertSleepAlarm;

  const SleepAlarmAddPhone({
    super.key,
    required this.sleepAlarm,
    required this.insertSleepAlarm,
  });

  @override
  State<SleepAlarmAddPhone> createState() => _SleepAlarmAddPhoneState();
}

class _SleepAlarmAddPhoneState extends State<SleepAlarmAddPhone> {
  // Sleep
  bool sleep = true;
  int sleepDuration = 30;
  bool sleepLinear = true;

  // Alarm clocl
  bool alarmClock = true;
  int wakeTimeHour = 7;
  int wakeTimeMin = 30;
  int beforeEndTimeMin = 30;
  bool alarmClockLinear = true;

  // Update
  bool update = false;

  @override
  void initState() {
    super.initState();
    initUpdate();
  }

  void initUpdate() {
    if (widget.sleepAlarm != null) {
      setState(() {
        update = true;
        // Set current choice
        sleep = widget.sleepAlarm!.sleep;
        sleepDuration = widget.sleepAlarm!.sleepDuration;
        sleepLinear = widget.sleepAlarm!.sleepLinear;

        alarmClock = widget.sleepAlarm!.alarmClock;
        wakeTimeHour = (widget.sleepAlarm!.wakeTime / 60).floor();
        wakeTimeMin = widget.sleepAlarm!.wakeTime - wakeTimeHour * 60;
        beforeEndTimeMin = widget.sleepAlarm!.beforeEndTimeMin;
        alarmClockLinear = widget.sleepAlarm!.alarmClockLinear;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final Size size = MediaQuery.of(context).size;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 7.5, sigmaY: 7.5),
        child: Container(
          height:
              MediaQuery.of(context).size.height * 0.90, // Almost full-screen
          decoration: BoxDecoration(
            color: CupertinoColors.darkBackgroundGray.withAlpha(200),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  textButton(
                    AppLocalizations.of(context).cancel,
                    () {
                      Navigator.of(context).pop();
                    },
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Expanded(
                    child: textButton(
                      AppLocalizations.of(context).sleep,
                      () {},
                      const TextStyle(color: Colors.white),
                      edgeInsets: EdgeInsets.zero,
                    ),
                  ),
                  textButton(
                    update
                        ? AppLocalizations.of(context).change
                        : AppLocalizations.of(context).create,
                    () async {
                      if (update) {
                        final SleepAlarm sleepAlarm = SleepAlarm(
                          id: widget.sleepAlarm!.id,
                          sleep: sleep,
                          sleepDuration: sleepDuration,
                          sleepLinear: sleepLinear,
                          alarmClock: alarmClock,
                          wakeTime: wakeTimeHour * 60 + wakeTimeMin,
                          beforeEndTimeMin: beforeEndTimeMin,
                          alarmClockLinear: alarmClockLinear,
                        );
                        await widget.insertSleepAlarm(sleepAlarm);
                        if (context.mounted) Navigator.of(context).pop();
                      } else {
                        if (sleep || alarmClock) {
                          final SleepAlarm sleepAlarm = SleepAlarm(
                            id: -1,
                            sleep: sleep,
                            sleepDuration: sleepDuration,
                            sleepLinear: sleepLinear,
                            alarmClock: alarmClock,
                            wakeTime: wakeTimeHour * 60 + wakeTimeMin,
                            beforeEndTimeMin: beforeEndTimeMin,
                            alarmClockLinear: alarmClockLinear,
                          );
                          await widget.insertSleepAlarm(sleepAlarm);
                          if (context.mounted) Navigator.of(context).pop();
                        } else {
                          Notifications().showWarningNotification(
                            context,
                            AppLocalizations.of(context)
                                .cannotcreateasleepalarmwithoutthe,
                          );
                        }
                      }
                    },
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              razh(20),
              Row(
                children: [
                  textButton(
                    AppLocalizations.of(context).sleepin,
                    () {
                      setState(() {
                        sleep = !sleep;
                      });
                    },
                    const TextStyle(color: Colors.white),
                    edgeInsets: const EdgeInsets.only(left: 15, right: 5),
                  ),
                  CupertinoSwitch(
                    value: sleep,
                    activeTrackColor: Col.primary,
                    onChanged: (val) {
                      setState(() {
                        sleep = val;
                      });
                    },
                  ),
                ],
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                height: sleep ? 160 : 0,
                width: size.width,
                //color: Colors.amberAccent,
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 120,
                        child: CupertinoPicker(
                          scrollController: FixedExtentScrollController(
                            initialItem: sleepDuration - 1,
                          ),
                          itemExtent: 40, // Height of each item
                          onSelectedItemChanged: (int index) {
                            setState(() {
                              sleepDuration = index + 1;
                            });
                          },
                          children: List.generate(60, (index) {
                            return Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 5, left: 15),
                        child: Text(
                          '${l10n.pongowillgraduallylowerthevolumefor} '
                          '$sleepDuration min',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.normal,
                            decoration: TextDecoration.none,
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              divider(size.width),
              razh(20),
              Row(
                children: [
                  textButton(
                    AppLocalizations.of(context).alarm,
                    () {
                      setState(() {
                        alarmClock = !alarmClock;
                      });
                    },
                    const TextStyle(color: Colors.white),
                    edgeInsets: const EdgeInsets.only(left: 15, right: 5),
                  ),
                  CupertinoSwitch(
                    value: alarmClock,
                    activeTrackColor: Col.primary,
                    onChanged: (val) {
                      setState(() {
                        alarmClock = val;
                      });
                    },
                  ),
                ],
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                height: alarmClock ? 280 : 0,
                width: size.width,
                //color: Colors.amberAccent,
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 120,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Hour Picker
                            Expanded(
                              child: CupertinoPicker(
                                scrollController: FixedExtentScrollController(
                                  initialItem: wakeTimeHour,
                                ),
                                itemExtent: 40,
                                onSelectedItemChanged: (index) {
                                  setState(() {
                                    wakeTimeHour = index;
                                  });
                                },
                                children: List.generate(24, (index) {
                                  return Center(
                                    child: Text(
                                      '$index h',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        color: Colors.white,
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),

                            // Minute Picker
                            Expanded(
                              child: CupertinoPicker(
                                scrollController: FixedExtentScrollController(
                                  initialItem: wakeTimeMin,
                                ),
                                itemExtent: 40,
                                onSelectedItemChanged: (index) {
                                  setState(() {
                                    wakeTimeMin = index;
                                  });
                                },
                                children: List.generate(60, (index) {
                                  return Center(
                                    child: Text(
                                      '$index min',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        color: Colors.white,
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 1,
                        width: size.width,
                        color: context.colors.onIcon.withAlpha(150),
                      ),
                      SizedBox(
                        height: 120,
                        child: CupertinoPicker(
                          scrollController: FixedExtentScrollController(
                            initialItem: beforeEndTimeMin - 1,
                          ),
                          itemExtent: 40, // Height of each item
                          onSelectedItemChanged: (int index) {
                            setState(() {
                              beforeEndTimeMin = index + 1;
                            });
                          },
                          children: List.generate(60, (index) {
                            return Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 5, left: 15),
                        child: Text(
                          '${l10n.pongowillgraduallyincreasethevolume} '
                          '$beforeEndTimeMin min '
                          '${l10n.beforeyouneedtowakeupat} '
                          '$wakeTimeHour:${wakeTimeMin.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.normal,
                            decoration: TextDecoration.none,
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              razh(10),
              divider(size.width),
            ],
          ),
        ),
      ),
    );
  }
}
