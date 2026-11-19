import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'colors.dart';

/// The app's Material themes.
abstract final class AppTheme {
  static final _base = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.transparent,
    colorScheme: const ColorScheme.dark(),
    useMaterial3: true,
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        textStyle: WidgetStateProperty.all(
          const TextStyle(color: Colors.white),
        ),
      ),
    ),
    textTheme: const TextTheme().apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    ),
    primarySwatch: Colors.blue,
    primaryColor: Col.primary,
    cupertinoOverrideTheme: const CupertinoThemeData(primaryColor: Col.primary),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      shadowColor: Colors.transparent,
      surfaceTintColor: Col.transp,
      centerTitle: true,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
    ),
    splashColor: Col.fadeIcon.withAlpha(0),
    highlightColor: Col.fadeIcon.withAlpha(0),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: AppColors.dark.onIcon,
    ),
  );

  /// The dark theme.
  static final dark = _base.copyWith(extensions: const [AppColors.dark]);

  /// The light theme, which keeps the dark Material colors and only swaps
  /// the app palette.
  static final light = _base.copyWith(
    brightness: Brightness.light,
    platform: TargetPlatform.iOS,
    extensions: const [AppColors.light],
  );
}
