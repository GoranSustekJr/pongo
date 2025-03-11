import 'package:flutter/cupertino.dart';
import 'package:flutter_swipe_action_cell/core/cell.dart';
import 'package:pongo/exports.dart';

sleepAlarmTile(
    context,
    bool first,
    bool last,
    SleepAlarm sleepAlarm,
    Function() function,
    bool active,
    Function(bool) changeActive,
    Function() removeSleepAlarm,
    {bool special = false}) {
  double radius = 15;
  BorderRadius borderRadius = BorderRadius.only(
    topLeft: first ? Radius.circular(radius) : Radius.zero,
    topRight: first ? Radius.circular(radius) : Radius.zero,
    bottomLeft: last ? Radius.circular(radius) : Radius.zero,
    bottomRight: last ? Radius.circular(radius) : Radius.zero,
  );

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10),
    child: SwipeActionCell(
      key: UniqueKey(),
      trailingActions: [
        SwipeAction(
          content: iconButton(
              AppIcons.trash, Col.error.withAlpha(200), removeSleepAlarm),
          onTap: (CompletionHandler handler) async {},
          color: Col.transp,
          backgroundRadius: radius,
        ),
      ],
      child: ClipRRect(
        child: kIsApple
            ? Container(
                height: 100,
                width: MediaQuery.of(context).size.width - 20,
                decoration: BoxDecoration(
                  borderRadius: borderRadius,
                  color: Col.primaryCard.withAlpha(150),
                ),
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: function,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (!first)
                              Container(
                                height: 1,
                                width: MediaQuery.of(context).size.width - 70,
                                color: Col.onIcon.withAlpha(50),
                              ),
                            Row(
                              children: [
                                razw(10),
                                SizedBox(
                                  width: 70,
                                  height: 49,
                                  child: Center(
                                    child: Text(
                                      sleepAlarm.sleep
                                          ? "${sleepAlarm.sleepDuration} min"
                                          : "Off",
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 20),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 15),
                                  child: Container(
                                    height: 25,
                                    width: 1,
                                    color: Col.onIcon.withAlpha(200),
                                  ),
                                ),
                                const Text(
                                  "Sleep in",
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                razw(10),
                                SizedBox(
                                  width: 70,
                                  height: 49,
                                  child: Center(
                                    child: Text(
                                      sleepAlarm.alarmClock
                                          ? "${(sleepAlarm.wakeTime / 60).floor().toString()}:${(sleepAlarm.wakeTime % 60).toString().padLeft(2, '0')}"
                                          : "Off",
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 20),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 15),
                                  child: Container(
                                    height: 25,
                                    width: 1,
                                    color: Col.onIcon.withAlpha(200),
                                  ),
                                ),
                                const Text("Alarm",
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white,
                                    )),
                              ],
                            ),
                            const SizedBox(
                              width: 15,
                            )
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 28,
                        height: 48,
                        child: CupertinoSwitch(
                            value: active, onChanged: changeActive),
                      ),
                      razw(25),
                    ],
                  ),
                ),
              )
            : InkWell(
                onTap: () {
                  function();
                },
                splashColor: Colors.white.withAlpha(100),
                borderRadius: borderRadius,
                child: Container(
                  height: 50,
                  width: MediaQuery.of(context).size.width - 20,
                  decoration: BoxDecoration(
                    borderRadius: borderRadius,
                    color: Col.primaryCard.withAlpha(200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (!first)
                        Container(
                          height: 1,
                          width: MediaQuery.of(context).size.width - 70,
                          color: Col.onIcon.withAlpha(50),
                        ),
                      Row(
                        children: [
                          const SizedBox(
                            width: 50,
                            height: 49,
                            /* child: special
                                  ? Image.asset(
                                      'assets/images/pongo_logo_tranparent.png')
                                  : Icon(icon, color: Col.onIcon, size: 27.5) */
                          ),
                          Expanded(
                              child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "title",
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 17,
                                ),
                              ),
                              Text(
                                "subtitle",
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Colors.white.withAlpha(150),
                                ),
                              ),
                            ],
                          )),
                          // if (trailingIcon != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            child: Container(
                              height: 25,
                              width: 1,
                              color: Col.onIcon.withAlpha(200),
                            ),
                          ),
                          /* if (trailingIcon != null)
                            SizedBox(
                                width: 28,
                                height: 49,
                                child: Icon(trailingIcon,
                                    color: Col.onIcon.withAlpha(200), size: 20)), */
                          const SizedBox(
                            width: 15,
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ),
      ),
    ),
  );
}
