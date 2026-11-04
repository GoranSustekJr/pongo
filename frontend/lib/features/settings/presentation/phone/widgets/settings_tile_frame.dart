import 'package:flutter/cupertino.dart';
import 'package:liquid_glass/liquid_glass.dart';

import 'package:pongo/app/theme/colors.dart';
import 'package:pongo/core/constants/platform.dart';
import 'package:pongo/shared/widgets/phone/inkwell.dart';

/// Row layout and grouped card shared by every settings tile.
Widget settingsTileFrame(
  BuildContext context, {
  required bool first,
  required bool last,
  required Widget leading,
  required String title,
  required String? subtitle,
  required List<Widget> trailing,
  required Function() onTap,
  double titleSize = 13,
  double subtitleSize = 9,
}) {
  const radius = Radius.circular(15);
  final borderRadius = BorderRadius.only(
    topLeft: first ? radius : Radius.zero,
    topRight: first ? radius : Radius.zero,
    bottomLeft: last ? radius : Radius.zero,
    bottomRight: last ? radius : Radius.zero,
  );

  final child = Column(
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
          SizedBox(width: 58, height: 48, child: leading),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: titleSize, color: Col.text),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: subtitleSize,
                      color: Col.text.withAlpha(150),
                    ),
                  ),
              ],
            ),
          ),
          ...trailing,
        ],
      ),
    ],
  );

  final decoration = BoxDecoration(
    borderRadius: borderRadius,
    color: Col.primaryCard.withAlpha(150),
  );
  final width = MediaQuery.of(context).size.width - 20;

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10),
    child: ClipRRect(
      child: kIsApple
          ? LiquidGlass(
              blur: 0,
              borderRadius: borderRadius,
              tint: Col.text,
              child: Container(
                height: 50,
                width: width,
                decoration: decoration,
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: onTap,
                  child: child,
                ),
              ),
            )
          : Container(
              height: 50,
              width: width,
              decoration: decoration,
              child: ClipRRect(
                borderRadius: borderRadius,
                child: inkWell(child, onTap),
              ),
            ),
    ),
  );
}

/// The thin line between a tile's text and its trailing value.
Widget settingsTileDivider() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 15),
    child: Container(
      height: 25,
      width: 1,
      color: Col.onIcon.withAlpha(200),
    ),
  );
}

Widget settingsTileIcon(IconData icon) {
  return Icon(icon, color: Col.onIcon, size: 27.5);
}
