import 'package:flutter/cupertino.dart';
import '../../exports.dart';

class TrackPageRoute extends PageRouteBuilder {
  final Widget child;

  TrackPageRoute({
    required this.child,
  }) : super(
            transitionDuration: const Duration(milliseconds: 600),
            pageBuilder: (context, animation, secondaryAnimation) => child);

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation, Widget child) =>
      SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0, 1),
          end: Offset.zero,
        ).animate(CurvedAnimation(
            parent: animation, curve: Curves.fastEaseInToSlowEaseOut)),
        child: child,
      );
}

class Navigations {
  void nextScreen(context, page, {bool useRootNavigator = false}) {
    Navigator.of(context, rootNavigator: useRootNavigator).push(
      !kIsApple
          ? MaterialPageRoute(builder: (context) => page)
          : CupertinoPageRoute(builder: (context) => page),
    );
  }

  void nextScreenReplace(context, page, arguments) {
    Navigator.of(context).pushReplacement(
      !kIsApple
          ? MaterialPageRoute(builder: (context) => page)
          : CupertinoPageRoute(builder: (context) => page),
    );
  }

  void trackScreen(context, page) {
    Navigator.of(context).push(TrackPageRoute(child: page));
    /* Navigator.of(context).push(MaterialWithModalsPageRoute(
      builder: (context) => page,
    )); */
  }
}

class Navigationss {
  void nextScreen(context, page, arguments) {
    //CupertinoPageRoute.
    Navigator.of(context).pushNamed(page, arguments: arguments);
  }

  void nextScreenReplace(context, page, arguments) {
    //CupertinoPageRoute.
    Navigator.of(context).pushReplacementNamed(page, arguments: arguments);
  }
}
