import 'package:flutter/cupertino.dart';
import 'package:kr_pull_down_button/pull_down_button.dart';
import 'package:provider/provider.dart';

import '../../../../app/view_models/app_settings_view_model.dart';
import '../../../../core/app_icons.dart';
import '../../../../core/themes/colors.dart';

PullDownButton appleLocalePopup(String locale, Function(String) function) {
  return PullDownButton(
    itemBuilder: (context) => [
      PullDownMenuItem(
        title: 'English',
        onTap: () {
          context.read<AppSettingsViewModel>().update(
            (s) => s.copyWith(locale: 'en'),
          );
          function('en');
        },
      ),
      const PullDownMenuDivider(),
      PullDownMenuItem(
        title: 'Deutsch',
        onTap: () {
          context.read<AppSettingsViewModel>().update(
            (s) => s.copyWith(locale: 'de'),
          );
          function('de');
        },
      ),
      const PullDownMenuDivider(),
      PullDownMenuItem(
        title: 'Hrvatski',
        onTap: () {
          context.read<AppSettingsViewModel>().update(
            (s) => s.copyWith(locale: 'hr'),
          );
          function('hr');
        },
      ),
    ],
    position: PullDownMenuPosition.above,
    buttonBuilder: (context, showMenu) => CupertinoButton(
      onPressed: showMenu,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Icon(AppIcons.world, color: context.colors.icon),
          Text(
            locale,
            style: TextStyle(fontSize: 10, color: context.colors.text),
          ),
        ],
      ),
    ),
  );
}
