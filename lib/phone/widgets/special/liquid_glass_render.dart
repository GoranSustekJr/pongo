import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:pongo/shared/constants/app_constants.dart';
import 'package:pongo/shared/constants/platform.dart';

import '../../theme/colors.dart';

Widget liquidGlassLayer(
    {Widget child = const SizedBox(),
    double blend = 40,
    double thickness = 20}) {
  return kIsApple
      ? LiquidGlassLayer(
          settings: LiquidGlassSettings(
            thickness: thickness,
            glassColor: const Color(0x1AFFFFFF), // A subtle white tint
            lightIntensity: 0.1,
            blend: blend,
          ),
          child: child)
      : child;
}

Widget liquidGlass(
    {Widget child = const SizedBox(), double radius = 7.5, double blur = 10}) {
  return kIsApple
      ? LiquidGlass.inLayer(
          blur: blur,
          glassContainsChild: false,
          shape: LiquidRoundedSuperellipse(
            borderRadius: Radius.circular(radius),
          ),
          child: child)
      : child;
}
