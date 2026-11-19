import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../../utils/platform.dart';
import '../../../app/view_models/app_settings_view_model.dart';

/// Groups the [liquidGlass] shapes below it. The optics come from the iOS 27
/// [GlassThemeData] set up in main.dart.
Widget liquidGlassLayer({Widget child = const SizedBox(), double blend = 10}) {
  if (!kIsApple) return child;
  return Builder(
    builder: (context) => context.readSettings.useLiquidGlass
        ? AdaptiveLiquidGlassLayer(blendAmount: blend, child: child)
        : child,
  );
}

Widget liquidGlass({Widget child = const SizedBox(), double radius = 14}) {
  if (!kIsApple) return child;
  return Builder(
    builder: (context) => context.readSettings.useLiquidGlass
        ? GlassContainer(
            shape: LiquidRoundedSuperellipse(borderRadius: radius),
            child: child,
          )
        : child,
  );
}
