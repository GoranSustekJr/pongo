import 'package:flutter/material.dart';
import 'package:pongo/phone/views/settings/settings_phone.dart';

class SettingsMainPhone extends StatefulWidget {
  final GlobalKey<NavigatorState> settingsHomeNavigatorKey;
  const SettingsMainPhone({super.key, required this.settingsHomeNavigatorKey});

  @override
  State<SettingsMainPhone> createState() => _SettingsMainPhoneState();
}

class _SettingsMainPhoneState extends State<SettingsMainPhone> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      //decoration: Constants().backgroundBoxDecoration,
      child: Stack(
        children: [
          Navigator(
            key: widget.settingsHomeNavigatorKey,
            onGenerateRoute: (routeSettings) {
              return MaterialPageRoute(
                  builder: (context) => const SettingsPhone());
              //TODO: Add clear player cache setting
              //TODO: Add data save settings for various images and other data
            },
          )
        ],
      ),
    ));
  }
}
