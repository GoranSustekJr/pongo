import 'package:flutter/cupertino.dart';
import '../../../../../exports.dart';

appleLocalePopup(String locale, Function(String) function) {
  return PullDownButton(
    itemBuilder: (context) => [
      PullDownMenuItem(
        title: 'English',
        onTap: () {
          MyAppPhone.setLocale(context, const Locale('en'));
          Storage().writeLocale("en");
          function("en");
        },
      ),
      const PullDownMenuDivider(),
      PullDownMenuItem(
        title: 'Deutsch',
        onTap: () {
          MyAppPhone.setLocale(context, const Locale('de'));
          Storage().writeLocale("de");
          function("de");
        },
      ),
      const PullDownMenuDivider(),
      PullDownMenuItem(
        title: 'Hrvatski',
        onTap: () {
          MyAppPhone.setLocale(context, const Locale('hr'));
          Storage().writeLocale("hr");
          function("hr");
        },
      ),
    ],
    position: PullDownMenuPosition.above,
    buttonBuilder: (context, showMenu) => CupertinoButton(
      onPressed: showMenu,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Icon(
            AppIcons.world,
            color: Col.icon,
          ),
          Text(
            locale,
            style: TextStyle(
              fontSize: 10,
              color: Col.text,
            ),
          )
        ],
      ),
    ),
  );
}
