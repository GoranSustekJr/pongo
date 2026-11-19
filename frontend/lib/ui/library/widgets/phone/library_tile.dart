import 'package:flutter/cupertino.dart';

import '../../../../utils/platform.dart';
import '../../../core/themes/colors.dart';
import '../../../core/ui/phone/inkwell.dart';
import '../../../core/ui/phone/liquid_glass_background.dart';

Padding libraryTile(
  BuildContext context,
  bool first,
  bool last,
  IconData icon,
  IconData trailingIcon,
  String title,
  String? subtitle,
  Function() function,
) {
  const double radius = 15;
  final BorderRadius borderRadius = BorderRadius.only(
    topLeft: first ? const Radius.circular(radius) : Radius.zero,
    topRight: first ? const Radius.circular(radius) : Radius.zero,
    bottomLeft: last ? const Radius.circular(radius) : Radius.zero,
    bottomRight: last ? const Radius.circular(radius) : Radius.zero,
  );

  final Widget child = Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    mainAxisAlignment: MainAxisAlignment.start,
    children: [
      if (!first && !kIsApple)
        Container(
          height: 1,
          width: MediaQuery.of(context).size.width - 70,
          color: context.colors.onIcon.withAlpha(50),
        ),
      const Expanded(child: SizedBox()),
      Row(
        children: [
          SizedBox(
            width: 58,
            height: 48,
            child: Icon(icon, color: context.colors.onIcon, size: 27.5),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: kIsApple ? 13 : 15,
                    color: context.colors.text,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: kIsApple ? 9 : 11,
                      color: context.colors.text.withAlpha(150),
                    ),
                  ),
              ],
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
          SizedBox(
            width: 28,
            height: 40,
            child: Icon(trailingIcon, size: 22.5, color: context.colors.onIcon),
          ),
          const SizedBox(width: 15),
        ],
      ),
      const Expanded(child: SizedBox()),
    ],
  );

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
                width: MediaQuery.of(context).size.width - 20,
                decoration: BoxDecoration(
                  borderRadius: borderRadius,
                  color: context.colors.primaryCard.withAlpha(150),
                ),
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    function();
                  },
                  child: child,
                ),
              ),
            )
          : Container(
              height: 50,
              width: MediaQuery.of(context).size.width - 20,
              decoration: BoxDecoration(
                borderRadius: borderRadius,
                color: context.colors.primaryCard.withAlpha(150),
              ),
              child: ClipRRect(
                borderRadius: borderRadius,
                child: inkWell(child, function),
              ),
            ),
    ),
  );
}
