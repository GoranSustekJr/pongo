import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:pongo/shared/constants/app_constants.dart';
import 'package:pongo/shared/constants/platform.dart';
import 'package:pongo/shared/storage/storage.dart';

import '../../theme/colors.dart';

Widget liquidGlassLayer({
  Widget child = const SizedBox(),
  double blend = 40,
  double thickness = 20,
  double blur = 10,
  Color glassColor = Colors.white12,
}) {
  return kIsApple && liquidGlassEnabled
      ? LiquidGlassLayer(
          settings: LiquidGlassSettings(
            blur: blur,
            thickness: thickness,
            glassColor: glassColor,
            lightIntensity: 0.1,
            blend: blend,
            ambientStrength: 0.5,
            lightAngle: 0.628,
          ),
          child: child)
      : child;
}

Widget liquidGlass({Widget child = const SizedBox(), double radius = 7.5}) {
  return kIsApple && liquidGlassEnabled
      ? LiquidGlass.inLayer(
          glassContainsChild: false,
          shape: LiquidRoundedSuperellipse(
            borderRadius: Radius.circular(radius),
          ),
          child: child)
      : child;
}
