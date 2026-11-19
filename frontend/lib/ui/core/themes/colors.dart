import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Colors that are the same in light and dark mode.
abstract final class Col {
  static const background = Color(0xFF000000);
  static final appBarBackgroudn = const Color(0xFF101010)
      .withValues(alpha: 0.88);
  static const error = CupertinoColors.destructiveRed;
  static const primary = Color(0xFF20B2AA);
  static const prim = Color.fromARGB(255, 28, 39, 85);
  static final searchBarBackground =
      CupertinoColors.tertiarySystemFill.darkColor;
  static const searchBarPlaceholder = Color(0xFF87868C);
  static final card = CupertinoColors.systemGrey6.darkHighContrastColor
      .withAlpha(200);
  static final divider = Colors.white.withAlpha(200);
  static const transp = Colors.transparent;
  static const tileTitle = Color(0xFF9AA5B1);
  static final fadeIcon = const Color(0xFF6D6D6D).withAlpha(200);
  static const title = Color(0xFFE4E7EB);
  static const tile = Color(0xFF617585);
}

/// Colors and backdrops that change between light and dark mode.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  /// Creates a palette.
  const AppColors({
    required this.realBackground,
    required this.primaryCard,
    required this.onIcon,
    required this.text,
    required this.icon,
    required this.defaultBlurhash,
    required this.backgroundAsset,
  });

  /// The dark mode palette.
  static const dark = AppColors(
    realBackground: Color(0xFF141C3D),
    primaryCard: Color.fromARGB(255, 28, 39, 85),
    onIcon: Color(0xFFBCCCDC),
    text: Colors.white,
    icon: Colors.white,
    defaultBlurhash: r'L03[fE,t|H$Q712s2swd{}{}OD{}',
    backgroundAsset: 'assets/images/pongo_background_dark.jpg',
  );

  /// The light mode palette.
  static const light = AppColors(
    realBackground: Color(0xFFFEFEFE),
    primaryCard: Color.fromARGB(255, 255, 255, 255),
    onIcon: Colors.grey,
    text: Colors.black,
    icon: Colors.grey,
    defaultBlurhash: r'K8S$M-%~MJrr*J*JR5MJHr',
    backgroundAsset: 'assets/images/pongo_background_light.jpg',
  );

  /// The palette for [darkMode].
  static AppColors of({required bool darkMode}) => darkMode ? dark : light;

  /// The color behind the background image.
  final Color realBackground;

  /// The fill of cards and sheets.
  final Color primaryCard;

  /// The color of selected icons.
  final Color onIcon;

  /// The default text color.
  final Color text;

  /// The default icon color.
  final Color icon;

  /// The blurhash shown when there is no artwork to derive one from.
  final String defaultBlurhash;

  /// The background image asset.
  final String backgroundAsset;

  /// A decoration that fills a box with the background image.
  BoxDecoration get backgroundBoxDecoration => BoxDecoration(
    image: DecorationImage(
      image: AssetImage(backgroundAsset),
      fit: BoxFit.cover,
    ),
  );

  @override
  AppColors copyWith({
    Color? realBackground,
    Color? primaryCard,
    Color? onIcon,
    Color? text,
    Color? icon,
    String? defaultBlurhash,
    String? backgroundAsset,
  }) => AppColors(
    realBackground: realBackground ?? this.realBackground,
    primaryCard: primaryCard ?? this.primaryCard,
    onIcon: onIcon ?? this.onIcon,
    text: text ?? this.text,
    icon: icon ?? this.icon,
    defaultBlurhash: defaultBlurhash ?? this.defaultBlurhash,
    backgroundAsset: backgroundAsset ?? this.backgroundAsset,
  );

  @override
  AppColors lerp(AppColors? other, double t) =>
      t < 0.5 || other == null ? this : other;
}

/// Access to the [AppColors] of the current theme.
extension AppColorsContext on BuildContext {
  /// The palette of the current theme.
  AppColors get colors =>
      Theme.of(this).extension<AppColors>() ?? AppColors.dark;
}
