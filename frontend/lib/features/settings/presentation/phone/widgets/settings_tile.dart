import 'package:flutter/material.dart';

import 'package:pongo/app/theme/colors.dart';
import 'package:pongo/core/constants/platform.dart';
import 'package:pongo/features/settings/presentation/phone/widgets/settings_tile_frame.dart';

settingsTile(context, bool first, bool last, IconData icon,
    IconData? trailingIcon, String title, String? subtitle, Function() function,
    {bool special = false}) {
  return settingsTileFrame(
    context,
    first: first,
    last: last,
    leading: special
        ? Image.asset(
            'assets/images/pongo_logo_tranparent.png',
            color: Col.text,
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
          child: Icon(trailingIcon, color: Col.onIcon.withAlpha(200), size: 20),
        ),
      const SizedBox(width: 15),
    ],
  );
}
