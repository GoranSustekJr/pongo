import 'package:flutter/material.dart';

import 'package:pongo/app/theme/colors.dart';
import 'package:pongo/features/settings/presentation/phone/widgets/settings_tile_frame.dart';

settingsTileInt(context, bool first, bool last, IconData icon, int trailingNum,
    String title, String? subtitle, Function() function) {
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
            style: TextStyle(color: Col.text),
          ),
        ),
      ),
      const SizedBox(width: 15),
    ],
  );
}
