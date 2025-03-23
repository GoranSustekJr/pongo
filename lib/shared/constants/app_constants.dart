// ignore_for_file: non_constant_identifier_names

import 'dart:ui';
import 'package:pongo/exports.dart';

class AppConstants {
  static const String SERVER_URL = "https://gogodom.ddns.net:48129/";

  static const String SERVER_URL_WSS = "REMOVED";

  static const String LYRICS_URL = "https://lrclib.net/api/get?";

  String BLURHASH =
      r'L03[fE,t|H$Q712s2swd{}{}OD{}'; //r'L03[fE,t|H$Q712s2swd{}{}OD{}';

  BoxDecoration backgroundBoxDecoration = const BoxDecoration(
    // color: Colors.black,
    image: DecorationImage(
      image: AssetImage(
        'assets/images/pongo_background_10k.png',
      ),
      fit: BoxFit.fill,
    ),
  );

  int noBlur = 150;
}

class CustomScrollBehaviour extends MaterialScrollBehavior {
  // Override behavior methods and getters like dragDevices
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.invertedStylus,
      };
}
