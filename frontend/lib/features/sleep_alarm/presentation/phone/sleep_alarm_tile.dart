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

  Widget child = Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!first && !kIsApple)
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
                          : AppLocalizations.of(context).off,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Col.text, fontSize: 20),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Container(
                    height: 25,
                    width: 1,
                    color: Col.onIcon.withAlpha(200),
                  ),
                ),
                Text(
                  AppLocalizations.of(context).sleepin,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: Col.text,
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
                          : AppLocalizations.of(context).off,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Col.text, fontSize: 20),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Container(
                    height: 25,
                    width: 1,
                    color: Col.onIcon.withAlpha(200),
                  ),
                ),
                Text(AppLocalizations.of(context).alarm,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: Col.text,
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
        child: CupertinoSwitch(value: active, onChanged: changeActive),
      ),
      razw(25),
    ],
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
        child: Container(
          height: 100,
          width: MediaQuery.of(context).size.width - 20,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            color: Col.primaryCard.withAlpha(150),
          ),
          child: kIsApple
              ? LiquidGlass(
                  blur: AppConstants().liquidGlassBlur,
                  borderRadius: borderRadius,
                  tint: Col.text,
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: function,
                    child: child,
                  ),
                )
              : ClipRRect(
                  borderRadius: borderRadius, child: inkWell(child, function)),
        ),
      ),
    ),
  );
}
