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
    return WillPopScope(
      onWillPop: () async {
        final canPop =
            widget.settingsHomeNavigatorKey.currentState?.canPop() ?? false;
        if (canPop) {
          widget.settingsHomeNavigatorKey.currentState?.pop();
          return false; // Prevent root navigator from popping (i.e. don't close the app)
        }
        return true; // Nothing to pop, let the app close
      },
      child: Scaffold(
          resizeToAvoidBottomInset: false,
          body: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: Stack(
              children: [
                Navigator(
                  key: widget.settingsHomeNavigatorKey,
                  onGenerateRoute: (routeSettings) {
                    return MaterialPageRoute(
                        builder: (context) => const SettingsPhone());
                  },
                )
              ],
            ),
          )),
    );
  }
}
