import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/themes/colors.dart';
import 'home_phone.dart';

class HomeMainPhone extends StatefulWidget {
  final GlobalKey<NavigatorState> homeNavigatorKey;
  const HomeMainPhone({super.key, required this.homeNavigatorKey});

  @override
  State<HomeMainPhone> createState() => _HomeMainPhoneState();
}

class _HomeMainPhoneState extends State<HomeMainPhone> {
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final navigator = widget.homeNavigatorKey.currentState;
        if (navigator?.canPop() ?? false) {
          navigator!.pop();
        } else {
          SystemNavigator.pop(); // Nothing to pop, let the app close
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        extendBody: true,
        extendBodyBehindAppBar: true,
        body: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          decoration: context.colors.backgroundBoxDecoration,
          child: Stack(
            children: [
              Navigator(
                key: widget.homeNavigatorKey,
                onGenerateRoute: (routeSettings) {
                  return MaterialPageRoute(
                    builder: (context) => const HomePhone(),
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
