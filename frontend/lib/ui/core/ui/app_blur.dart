import 'dart:ui';

import 'package:flutter/widgets.dart';

import '../../../utils/platform.dart';
import '../../app/view_models/app_settings_view_model.dart';

/// Blur of [sigma], or none when the user turned blur off in preferences.
ImageFilter appBlur(BuildContext context, double sigma) {
  final value = context.readSettings.useBlur ? sigma : 0.0;
  return ImageFilter.blur(sigmaX: value, sigmaY: value);
}

/// [appBlur] for surfaces that stay sharp on Apple platforms.
ImageFilter nonAppleBlur(BuildContext context, double sigma) =>
    appBlur(context, kIsApple ? 0 : sigma);
