import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../utils/platform.dart';

class TrackPageRoute extends PageRouteBuilder {
  final Widget child;

  TrackPageRoute({required this.child})
    : super(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (context, animation, secondaryAnimation) => child,
      );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => SlideTransition(
    position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.fastEaseInToSlowEaseOut,
          ),
        ),
    child: child,
  );
}

class Navigations {
  void nextScreen(
    BuildContext context,
    Widget page, {
    bool useRootNavigator = false,
  }) {
    Navigator.of(context, rootNavigator: useRootNavigator).push(
      !kIsApple
          ? MaterialPageRoute(builder: (context) => page)
          : CupertinoPageRoute(builder: (context) => page),
    );
  }

  /// Pushes [page] on [navigator] with the platform's transition.
  void push(NavigatorState navigator, Widget page) {
    navigator.push(
      !kIsApple
          ? MaterialPageRoute(builder: (context) => page)
          : CupertinoPageRoute(builder: (context) => page),
    );
  }

  void nextScreenReplace(BuildContext context, Widget page, Object? arguments) {
    Navigator.of(context).pushReplacement(
      !kIsApple
          ? MaterialPageRoute(builder: (context) => page)
          : CupertinoPageRoute(builder: (context) => page),
    );
  }

  void trackScreen(BuildContext context, Widget page) {
    Navigator.of(context).push(TrackPageRoute(child: page));
    /* Navigator.of(context).push(MaterialWithModalsPageRoute(
      builder: (context) => page,
    )); */
  }
}

class Navigationss {
  void nextScreen(BuildContext context, String page, Object? arguments) {
    //CupertinoPageRoute.
    Navigator.of(context).pushNamed(page, arguments: arguments);
  }

  void nextScreenReplace(BuildContext context, String page, Object? arguments) {
    //CupertinoPageRoute.
    Navigator.of(context).pushReplacementNamed(page, arguments: arguments);
  }
}
