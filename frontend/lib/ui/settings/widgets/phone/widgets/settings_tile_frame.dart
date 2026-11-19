import 'package:flutter/cupertino.dart';

import '../../../../../utils/platform.dart';
import '../../../../core/themes/colors.dart';
import '../../../../core/ui/phone/inkwell.dart';
import '../../../../core/ui/phone/liquid_glass_background.dart';

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
  double titleSize = 15,
  double subtitleSize = 11,
}) {
  const radius = Radius.circular(18);
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
          color: context.colors.onIcon.withAlpha(50),
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
                  style: TextStyle(
                    fontSize: titleSize,
                    color: context.colors.text,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: subtitleSize,
                      color: context.colors.text.withAlpha(150),
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
    color: context.colors.primaryCard.withAlpha(150),
  );
  final width = MediaQuery.of(context).size.width - 20;

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10),
    child: ClipRRect(
      child: kIsApple
          ? GlassSurface(
              blur: 0,
              borderRadius: borderRadius,
              tint: context.colors.text,
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
    child: Builder(
      builder: (context) => Container(
        height: 25,
        width: 1,
        color: context.colors.onIcon.withAlpha(200),
      ),
    ),
  );
}

Widget settingsTileIcon(IconData icon) {
  return Builder(
    builder: (context) => Icon(icon, color: context.colors.onIcon, size: 27.5),
  );
}
