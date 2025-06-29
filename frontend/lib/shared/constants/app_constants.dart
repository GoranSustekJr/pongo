// ignore_for_file: non_constant_identifier_names

import 'dart:ui';
import 'package:pongo/exports.dart';

class AppConstants {
  static final String SERVER_URL = dotenv.get('SERVER_URL');

  static final String SERVER_URL_WSS = dotenv.get('SERVER_URL_WSS');

  static const String LYRICS_URL = "https://lrclib.net/api/get?";

  String BLURHASH = darkMode.value
      ? r'L03[fE,t|H$Q712s2swd{}{}OD{}'
      : r'K8S$M-%~MJrr*J*JR5MJHr'; //r'UAQwR.X8$$10OYAD}r}rR+5mJ8=wxu9^S21I'
  //r'L03[fE,t|H$Q712s2swd{}{}OD{}';

  double liquidGlassBlur = 15;

  BoxDecoration backgroundBoxDecoration = BoxDecoration(
    // color: Colors.black,
    image: DecorationImage(
      image: AssetImage(darkMode.value
              ? 'assets/images/pongo_background_10k.png'
              : 'assets/images/pongo_white_red_background_10k.png'
          /*  mainContext.value != null
            ? MediaQuery.of(mainContext.value!).platformBrightness ==
                    Brightness.dark
                ? 'assets/images/pongo_background_10k.png'
                : 'assets/images/pongo_white_cyan_background_10k.png'
            : 'assets/images/pongo_background_10k.png', */
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
