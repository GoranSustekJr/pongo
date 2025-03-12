import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:pongo/exports.dart';

class SleepAlarmAddPhone extends StatefulWidget {
  final Function(SleepAlarm) insertSleepAlarm;
  const SleepAlarmAddPhone({super.key, required this.insertSleepAlarm});

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

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
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
                  textButton(AppLocalizations.of(context)!.cancel, () {
                    Navigator.of(context).pop();
                  },
                      const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                  Expanded(
                      child: textButton(AppLocalizations.of(context)!.sleep,
                          () {}, const TextStyle(color: Colors.white),
                          edgeInsets: EdgeInsets.zero)),
                  textButton(AppLocalizations.of(context)!.create, () async {
                    if (sleep || alarmClock) {
                      SleepAlarm sleepAlarm = SleepAlarm(
                        id: -1,
                        sleep: sleep,
                        sleepDuration: sleepDuration,
                        sleepLinear: sleepLinear,
                        alarmClock: alarmClock,
                        wakeTime: wakeTimeHour * 60 + wakeTimeMin,
                        beforeEndTimeMin: beforeEndTimeMin,
                        alarmClockLinear: alarmClockLinear,
                      );
                      int id =
                          await DatabaseHelper().insertSleepAlarm(sleepAlarm);
                      widget.insertSleepAlarm(SleepAlarm(
                        id: id,
                        sleep: sleep,
                        sleepDuration: sleepDuration,
                        sleepLinear: sleepLinear,
                        alarmClock: alarmClock,
                        wakeTime: wakeTimeHour * 60 + wakeTimeMin,
                        beforeEndTimeMin: beforeEndTimeMin,
                        alarmClockLinear: alarmClockLinear,
                      ));
                      Navigator.of(context).pop();
                    } else {
                      Notifications().showWarningNotification(
                          context,
                          AppLocalizations.of(context)!
                              .cannotcreateasleepalarmwithoutthe);
                    }
                  },
                      const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                ],
              ),
              razh(20),
              Row(
                children: [
                  textButton(AppLocalizations.of(context)!.sleepin, () {
                    setState(() {
                      sleep = !sleep;
                    });
                  }, const TextStyle(color: Colors.white),
                      edgeInsets: const EdgeInsets.only(left: 15, right: 5)),
                  CupertinoSwitch(
                      value: sleep,
                      activeColor: Col.onIcon,
                      onChanged: (val) {
                        setState(() {
                          sleep = val;
                        });
                      }),
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
                              initialItem: sleepDuration - 1),
                          itemExtent: 40, // Height of each item
                          onSelectedItemChanged: (int index) {
                            setState(() {
                              sleepDuration = index + 1;
                            });
                          },
                          children: List.generate(60, (index) {
                            return Center(
                                child: Text('${index + 1}',
                                    style: const TextStyle(fontSize: 20)));
                          }),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 5, left: 15),
                        child: Text(
                          "${AppLocalizations.of(context)!.pongowillgraduallylowerthevolumefor} $sleepDuration min",
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
                  textButton(AppLocalizations.of(context)!.alarm, () {
                    setState(() {
                      alarmClock = !alarmClock;
                    });
                  }, const TextStyle(color: Colors.white),
                      edgeInsets: const EdgeInsets.only(left: 15, right: 5)),
                  CupertinoSwitch(
                      value: alarmClock,
                      activeColor: Col.onIcon,
                      onChanged: (val) {
                        setState(() {
                          alarmClock = val;
                        });
                      }),
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
                                    initialItem: wakeTimeHour),
                                itemExtent: 40,
                                onSelectedItemChanged: (index) {
                                  setState(() {
                                    wakeTimeHour = index;
                                  });
                                },
                                children: List.generate(24, (index) {
                                  return Center(
                                      child: Text('$index h',
                                          style:
                                              const TextStyle(fontSize: 20)));
                                }),
                              ),
                            ),

                            // Minute Picker
                            Expanded(
                              child: CupertinoPicker(
                                scrollController: FixedExtentScrollController(
                                    initialItem: wakeTimeMin),
                                itemExtent: 40,
                                onSelectedItemChanged: (index) {
                                  setState(() {
                                    wakeTimeMin = index;
                                  });
                                },
                                children: List.generate(60, (index) {
                                  return Center(
                                      child: Text('$index min',
                                          style:
                                              const TextStyle(fontSize: 20)));
                                }),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 1,
                        width: size.width,
                        color: Col.onIcon.withAlpha(150),
                      ),
                      SizedBox(
                        height: 120,
                        child: CupertinoPicker(
                          scrollController: FixedExtentScrollController(
                              initialItem: beforeEndTimeMin - 1),
                          itemExtent: 40, // Height of each item
                          onSelectedItemChanged: (int index) {
                            setState(() {
                              beforeEndTimeMin = index + 1;
                            });
                          },
                          children: List.generate(60, (index) {
                            return Center(
                                child: Text('${index + 1}',
                                    style: const TextStyle(fontSize: 20)));
                          }),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 5, left: 15),
                        child: Text(
                          "${AppLocalizations.of(context)!.pongowillgraduallyincreasethevolume} $beforeEndTimeMin min ${AppLocalizations.of(context)!.beforeyouneedtowakeupat} $wakeTimeHour:${(wakeTimeMin).toString().padLeft(2, '0')}",
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


/*
  "donotterminatetheapp": "Do NOT terminate the app",
  "cannotstartalarm": "Can't start the alarm",
  "thequeuemustnotbeemptyinordertostartthealarm": "The queue must not be empty in order to start the alarm",
  "maximumvolumeofthealarm": "Maximum volume of the alarm",
  "createnewsleepalarm": "Create new sleep alarm",
  "off": "Off",
  "sleepin": "Sleep in",
  "alarm": "Alarm",
  "cannotcreateasleepalarmwithoutthe": "Cannot create a sleep alarm without the 'sleep in' or 'alarm'",
  "pongowillgraduallylowerthevolumefor": "Pongo will gradually lower the volume for",
  "pongowillgraduallyincreasethevolume": "Pongo will gradually increase the valume",
  "beforeyouneedtowakeupat": "before you need to wake up at",
  "about": "About",
  "aboutpongo": "About Pongo",
  "contactusviamail": "Contact us via mail",
  "termsandconditions": "Terms & Conditions",
  "ourtermsandconditions": "Our Terms & Conditions",
  "privacypolicy": "Privacy Policy",
  "ourprivacypolicy": "Our Privacy Policy",

 */