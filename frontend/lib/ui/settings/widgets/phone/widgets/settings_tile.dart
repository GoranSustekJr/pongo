import 'package:flutter/material.dart';

import '../../../../../utils/platform.dart';
import '../../../../core/themes/colors.dart';
import 'settings_tile_frame.dart';

Widget settingsTile(
  BuildContext context,
  bool first,
  bool last,
  IconData icon,
  IconData? trailingIcon,
  String title,
  String? subtitle,
  Function() function, {
  bool special = false,
}) {
  return settingsTileFrame(
    context,
    first: first,
    last: last,
    leading: special
        ? Image.asset(
            'assets/images/pongo_logo_tranparent.png',
            color: context.colors.text,
          )
        : settingsTileIcon(icon),
    title: title,
    subtitle: subtitle,
    titleSize: kIsApple ? 13 : 15,
    subtitleSize: kIsApple ? 9 : 11,
    onTap: function,
    trailing: [
      if (trailingIcon != null) settingsTileDivider(),
      if (trailingIcon != null)
        SizedBox(
          width: 28,
          height: 48,
          child: Icon(
            trailingIcon,
            color: context.colors.onIcon.withAlpha(200),
            size: 20,
          ),
        ),
      const SizedBox(width: 15),
    ],
  );
}
