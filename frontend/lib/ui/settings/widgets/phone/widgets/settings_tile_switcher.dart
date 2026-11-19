import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:pongo/app/theme/colors.dart';
import 'package:pongo/core/constants/platform.dart';
import 'package:pongo/features/settings/presentation/phone/widgets/settings_tile_frame.dart';

settingsTileSwitcher(
  context,
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
                activeColor: Col.onIcon,
                onChanged: (value) {
                  function(value);
                },
              )
            : Switch(
                value: boolean,
                activeColor: Col.onIcon,
                inactiveTrackColor: Col.icon.withAlpha(75),
                thumbColor: MaterialStateProperty.resolveWith<Color?>(
                    (states) => Colors.white),
                trackOutlineColor: MaterialStateProperty.resolveWith<Color?>(
                    (states) => Col.realBackground),
                onChanged: (value) {
                  function(value);
                },
              ),
      ),
      const SizedBox(width: 30),
    ],
  );
}
