import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'settings_phone.dart';

class SettingsMainPhone extends StatefulWidget {
  final GlobalKey<NavigatorState> settingsHomeNavigatorKey;
  const SettingsMainPhone({super.key, required this.settingsHomeNavigatorKey});

  @override
  State<SettingsMainPhone> createState() => _SettingsMainPhoneState();
}

class _SettingsMainPhoneState extends State<SettingsMainPhone> {
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final navigator = widget.settingsHomeNavigatorKey.currentState;
        if (navigator?.canPop() ?? false) {
          navigator!.pop();
        } else {
          SystemNavigator.pop(); // Nothing to pop, let the app close
        }
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
                    builder: (context) => const SettingsPhone(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
