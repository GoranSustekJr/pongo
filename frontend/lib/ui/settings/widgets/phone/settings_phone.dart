import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../routing/navigation.dart';
import '../../../../utils/platform.dart';
import '../../../core/app_icons.dart';
import '../../../core/themes/colors.dart';
import '../../../core/ui/space.dart';
import '../../../onboarding/widgets/phone/introduction_phone.dart';
import 'about/about_phone.dart';
import 'preferences/preferences_phone.dart';
import 'profile/profile_phone.dart';
import 'widgets/settings_text.dart';
import 'widgets/settings_tile.dart';

class SettingsPhone extends StatefulWidget {
  const SettingsPhone({super.key});

  @override
  State<SettingsPhone> createState() => _SettingsPhoneState();
}

class _SettingsPhoneState extends State<SettingsPhone> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: context.colors.backgroundBoxDecoration,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              snap: true,
              floating: true,
              pinned: true,
              stretch: true,
              automaticallyImplyLeading: false,
              expandedHeight: kIsApple
                  ? MediaQuery.of(context).size.height / 5
                  : MediaQuery.of(context).size.height / 4,
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                title: Text(
                  AppLocalizations.of(context).settings,
                  style: TextStyle(
                    fontSize: kIsApple ? 30 : 40,
                    fontWeight: kIsApple ? FontWeight.w700 : FontWeight.w800,
                    color: context.colors.text,
                  ),
                ),
                stretchModes: const [
                  StretchMode.zoomBackground,
                  StretchMode.blurBackground,
                  StretchMode.fadeTitle,
                ],
              ),
            ),
            // Other slivers for your Wi-Fi settings content
            SliverList(
              delegate: SliverChildBuilderDelegate((
                BuildContext context,
                int index,
              ) {
                return Column(
                  children: [
                    razh(kIsApple ? size.width / 5 : size.width / 4),
                    settingsText(AppLocalizations.of(context).profile),
                    settingsTile(
                      context,
                      true,
                      false,
                      AppIcons.profile,
                      AppIcons.settings,
                      AppLocalizations.of(context).profile,
                      AppLocalizations.of(context).yourprofile,
                      () {
                        //Navigationss().nextScreen(context, '/profile', {});
                        Navigations().nextScreen(context, const ProfilePhone());
                      },
                    ),
                    settingsTile(
                      context,
                      false,
                      true,
                      AppIcons.preferences,
                      AppIcons.settings,
                      AppLocalizations.of(context).preferences,
                      AppLocalizations.of(context).yourpreferences,
                      () {
                        Navigations().nextScreen(
                          context,
                          const PreferencesPhone(),
                        );
                      },
                    ),
                    razh(20),
                    settingsText(AppLocalizations.of(context).about),
                    settingsTile(
                      context,
                      true,
                      false,
                      CupertinoIcons.info_circle,
                      AppIcons.musicAlbums,
                      AppLocalizations.of(context).about,
                      AppLocalizations.of(context).aboutpongo,
                      () {
                        Navigations().nextScreen(context, const AboutPhone());
                      },
                    ),
                    settingsTile(
                      context,
                      false,
                      true,
                      CupertinoIcons.chart_bar_fill,
                      AppIcons.settings,
                      'Tipps & tricks',
                      'Pongo tipps & tricks',
                      () {
                        Navigations().nextScreen(
                          context,
                          const IntroductionPhone(),
                        );
                      },
                      special: true,
                    ),
                  ],
                );
              }, childCount: 1),
            ),
          ],
        ),
      ),
    );
  }
}
