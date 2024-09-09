import 'package:pongo/exports.dart';

class AppConstants {
  static const String SERVER_URL = "http://goransustekdoo.ddns.net:9090/";

  static const String LYRICS_URL = "https://lrclib.net/api/get?";

  String BLURHASH = r'L03[fE,t|H$Q712s2swd{}{}OD{}';

  BoxDecoration backgroundBoxDecoration = const BoxDecoration(
      image: DecorationImage(
    image: AssetImage(
      'assets/images/pongo_background_10k.png',
    ),
    fit: BoxFit.fill,
  ));
}
