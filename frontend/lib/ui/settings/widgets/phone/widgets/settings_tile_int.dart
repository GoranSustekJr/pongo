import 'package:flutter/material.dart';

import '../../../../core/themes/colors.dart';
import 'settings_tile_frame.dart';

Widget settingsTileInt(
  BuildContext context,
  bool first,
  bool last,
  IconData icon,
  int trailingNum,
  String title,
  String? subtitle,
  Function() function,
) {
  return settingsTileFrame(
    context,
    first: first,
    last: last,
    leading: settingsTileIcon(icon),
    title: title,
    subtitle: subtitle,
    onTap: function,
    trailing: [
      settingsTileDivider(),
      SizedBox(
        width: 28,
        height: 48,
        child: Center(
          child: Text(
            trailingNum.toString(),
            style: TextStyle(color: context.colors.text),
          ),
        ),
      ),
      const SizedBox(width: 15),
    ],
  );
}
