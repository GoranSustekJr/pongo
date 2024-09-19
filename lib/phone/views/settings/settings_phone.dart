import 'package:flutter/cupertino.dart';
import 'package:pongo/exports.dart';
import 'package:pongo/phone/views/settings/data/data_phone.dart';
import 'package:pongo/phone/views/settings/profile/profile_phone.dart';

import 'preferences/preferences_phone.dart';

class SettingsPhone extends StatefulWidget {
  const SettingsPhone({super.key});

  @override
  State<SettingsPhone> createState() => _SettingsPhoneState();
}

class _SettingsPhoneState extends State<SettingsPhone> {
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
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
                  AppLocalizations.of(context)!.settings,
                  style: TextStyle(
                    fontSize: kIsApple ? 30 : 40,
                    fontWeight: kIsApple ? FontWeight.w700 : FontWeight.w800,
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
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  return Column(
                    children: [
                      razh(kIsApple ? size.width / 5 : size.width / 4),
                      settingsText(AppLocalizations.of(context)!.profile),
                      settingsTile(
                          context,
                          true,
                          false,
                          AppIcons.profile,
                          AppIcons.settings,
                          AppLocalizations.of(context)!.profile,
                          AppLocalizations.of(context)!.yourprofile, () {
                        //Navigationss().nextScreen(context, '/profile', {});
                        Navigations().nextScreen(context, const ProfilePhone());
                      }),
                      settingsTile(
                          context,
                          false,
                          true,
                          AppIcons.preferences,
                          AppIcons.settings,
                          AppLocalizations.of(context)!.preferences,
                          AppLocalizations.of(context)!.yourpreferences, () {
                        Navigations()
                            .nextScreen(context, const PreferencesPhone());
                        //Navigations().nextScreen(context, PhonePreferencesScreen());
                      }),
                      razh(20),
                      settingsText("Data"),
                      settingsTile(
                          context,
                          true,
                          true,
                          CupertinoIcons.chart_bar_fill,
                          AppIcons.settings,
                          AppLocalizations.of(context)!.data,
                          AppLocalizations.of(context)!.saveyourdata, () {
                        Navigations().nextScreen(context, const DataPhone());
                        //Navigationss().nextScreen(context, '/profile', {});
                        // Navigations().nextScreen(context, PhoneProfileOther());
                      }),
                    ],
                  );
                },
                childCount: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
