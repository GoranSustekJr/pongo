import 'package:flutter/cupertino.dart';
import 'package:flutter_swipe_action_cell/core/cell.dart';

import '../../../../domain/models/sleep_alarm/sleep_alarm.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../utils/platform.dart';
import '../../../core/app_icons.dart';
import '../../../core/themes/colors.dart';
import '../../../core/themes/dimens.dart';
import '../../../core/ui/phone/buttons/icon_button.dart';
import '../../../core/ui/phone/inkwell.dart';
import '../../../core/ui/phone/liquid_glass_background.dart';
import '../../../core/ui/space.dart';

Padding sleepAlarmTile(
  BuildContext context,
  bool first,
  bool last,
  SleepAlarm sleepAlarm,
  Function() function,
  bool active,
  Function(bool) changeActive,
  Function() removeSleepAlarm, {
  bool special = false,
}) {
  const double radius = 15;
  final BorderRadius borderRadius = BorderRadius.only(
    topLeft: first ? const Radius.circular(radius) : Radius.zero,
    topRight: first ? const Radius.circular(radius) : Radius.zero,
    bottomLeft: last ? const Radius.circular(radius) : Radius.zero,
    bottomRight: last ? const Radius.circular(radius) : Radius.zero,
  );

  final Widget child = Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!first && !kIsApple)
              Container(
                height: 1,
                width: MediaQuery.of(context).size.width - 70,
                color: context.colors.onIcon.withAlpha(50),
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
                          ? '${sleepAlarm.sleepDuration} min'
                          : AppLocalizations.of(context).off,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.colors.text,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Container(
                    height: 25,
                    width: 1,
                    color: context.colors.onIcon.withAlpha(200),
                  ),
                ),
                Text(
                  AppLocalizations.of(context).sleepin,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: context.colors.text),
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
                      style: TextStyle(
                        color: context.colors.text,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Container(
                    height: 25,
                    width: 1,
                    color: context.colors.onIcon.withAlpha(200),
                  ),
                ),
                Text(
                  AppLocalizations.of(context).alarm,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: context.colors.text),
                ),
              ],
            ),
            const SizedBox(width: 15),
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
            AppIcons.trash,
            Col.error.withAlpha(200),
            removeSleepAlarm,
          ),
          onTap: (CompletionHandler handler) {},
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
            color: context.colors.primaryCard.withAlpha(150),
          ),
          child: kIsApple
              ? GlassSurface(
                  blur: Dimens.liquidGlassBlur,
                  borderRadius: borderRadius,
                  tint: context.colors.text,
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: function,
                    child: child,
                  ),
                )
              : ClipRRect(
                  borderRadius: borderRadius,
                  child: inkWell(child, function),
                ),
        ),
      ),
    ),
  );
}
