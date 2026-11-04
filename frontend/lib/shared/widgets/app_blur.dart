import 'dart:ui';

import 'package:pongo/core/constants/platform.dart';
import 'package:pongo/core/state/globals.dart';

/// Blur of [sigma], or none when the user turned blur off in preferences.
ImageFilter appBlur(double sigma) {
  final value = useBlur.value ? sigma : 0.0;
  return ImageFilter.blur(sigmaX: value, sigmaY: value);
}

/// [appBlur] for surfaces that stay sharp on Apple platforms.
ImageFilter nonAppleBlur(double sigma) => appBlur(kIsApple ? 0 : sigma);
