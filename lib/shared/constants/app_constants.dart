import 'package:pongo/exports.dart';

class AppConstants {
  static const String SERVER_URL = "https://gogodom.ddns.net:9090/";

  static const String SERVER_URL_WSS = "wss://gogodom.ddns.net:9090/";

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
}
