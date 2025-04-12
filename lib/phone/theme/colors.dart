// ignore_for_file: deprecated_member_use

import 'package:flutter/cupertino.dart';
import 'package:pongo/exports.dart';

class Col {
  static const background = Color(0xFF000000); // Scaffold background
  static Color get realBackground =>
      darkMode.value ? const Color(0xFF141C3D) : const Color(0xFFFEFEFE);
  static final appBarBackgroudn =
      const Color(0xFF101010).withOpacity(0.88); // App bar background
  static const error = CupertinoColors.destructiveRed; // Error
  static const primary = Color(0xFF20B2AA); // Primary
  static Color get primaryCard => darkMode.value
      ? const Color.fromARGB(255, 28, 39, 85)
      : const Color.fromARGB(255, 255, 255, 255);

  static final searchBarBackground =
      CupertinoColors.tertiarySystemFill.darkColor; // Search bar background
  static const searchBarPlaceholder =
      Color(0xFF87868C); // Search bar background
  static final card =
      CupertinoColors.systemGrey6.darkHighContrastColor.withAlpha(200); // Card
  static final divider = Colors.white.withAlpha(200); // Divider
  static const transp = Colors.transparent;

  // Settings
  static const tileTitle = Color(0xFF9AA5B1); // Setting tile title
  static final fadeIcon = const Color(0xFF6D6D6D).withAlpha(200); // Fade icon
  static const title = Color(0xFFE4E7EB); // Setting title color
  static const tile = Color(0xFF617585); // 446879static
  static Color get onIcon =>
      darkMode.value ? const Color(0xFFBCCCDC) : Colors.grey; // Selected Icon
  static Color get text => darkMode.value ? Colors.white : Colors.black;
  static Color get icon => darkMode.value ? Colors.white : Colors.grey;
}
