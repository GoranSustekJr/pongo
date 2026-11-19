import 'package:flutter/material.dart';

import '../../themes/colors.dart';

/// Paints the app's background image behind [child].
class Background extends StatelessWidget {
  /// Creates a background for [child].
  const Background({super.key, required this.child});

  /// The content in front of the background.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ColoredBox(
      color: colors.realBackground,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Image.asset(colors.backgroundAsset, fit: BoxFit.cover),
          child,
        ],
      ),
    );
  }
}
