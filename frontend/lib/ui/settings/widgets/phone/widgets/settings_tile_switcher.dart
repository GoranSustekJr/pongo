import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../../utils/platform.dart';
import '../../../../core/themes/colors.dart';
import 'settings_tile_frame.dart';

Widget settingsTileSwitcher(
  BuildContext context,
  bool first,
  bool last,
  IconData icon,
  bool boolean,
  String title,
  String? subtitle,
  Function(bool) function,
) {
  return settingsTileFrame(
    context,
    first: first,
    last: last,
    leading: settingsTileIcon(icon),
    title: title,
    subtitle: subtitle,
    onTap: () {
      function(!boolean);
    },
    trailing: [
      SizedBox(
        width: 28,
        height: 48,
        child: kIsApple
            ? CupertinoSwitch(
                value: boolean,
                activeTrackColor: Col.primary,
                onChanged: (value) {
                  function(value);
                },
              )
            : Switch(
                value: boolean,
                activeThumbColor: context.colors.onIcon,
                inactiveTrackColor: context.colors.icon.withAlpha(75),
                thumbColor: WidgetStateProperty.resolveWith<Color?>(
                  (states) => Colors.white,
                ),
                trackOutlineColor: WidgetStateProperty.resolveWith<Color?>(
                  (states) => context.colors.realBackground,
                ),
                onChanged: (value) {
                  function(value);
                },
              ),
      ),
      const SizedBox(width: 30),
    ],
  );
}
