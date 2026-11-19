import 'dart:ui';

import 'package:flutter/material.dart';

/// Shared sizes and alpha values.
abstract final class Dimens {
  /// Blur sigma of liquid glass surfaces.
  static const liquidGlassBlur = 15.0;

  /// Background alpha of surfaces when blur is turned off.
  static const noBlur = 150;
}

/// Scroll behavior that lets every pointer kind drag scrollables.
class CustomScrollBehaviour extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.invertedStylus,
  };
}
