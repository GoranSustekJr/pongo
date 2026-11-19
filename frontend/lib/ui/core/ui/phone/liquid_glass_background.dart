import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../utils/platform.dart';
import '../../themes/colors.dart';
import '../../themes/dimens.dart';

/// Frosted surface for content inside lists and for corners that differ per
/// side, which the shader based glass can't draw and shouldn't run per row.
class GlassSurface extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final Color tint;
  final BorderRadius borderRadius;

  const GlassSurface({
    super.key,
    required this.child,
    this.blur = 15,
    this.opacity = 0.1,
    this.tint = Colors.white,
    this.borderRadius = BorderRadius.zero,
  });

  @override
  Widget build(BuildContext context) {
    final surface = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        color: tint.withValues(alpha: opacity),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 0.5,
        ),
      ),
      child: child,
    );
    return ClipRRect(
      borderRadius: borderRadius,
      child: blur == 0
          ? surface
          : BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: surface,
            ),
    );
  }
}

Widget liquidGlassBackground({
  Widget child = const SizedBox(),
  bool enabled = false,
}) {
  return !enabled
      ? GlassSurface(
          blur: kIsApple ? Dimens.liquidGlassBlur : 0,
          opacity: kIsApple ? 0.2 : 0,
          tint: kIsApple ? Colors.white : Col.transp,
          borderRadius: kIsApple
              ? const BorderRadius.all(Radius.circular(28))
              : BorderRadius.zero,
          child: child,
        )
      : child;
}
