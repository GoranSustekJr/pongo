import 'package:pongo/exports.dart';

class Storage {
  // Instance storage
  final storage = const FlutterSecureStorage();

  // Specific platform options
  //final AndroidOptions aOptions = AndroidOptions();

  static String singedInKey = "SIGNEDIN";
  static String accessTokenKey = "ACCESSTOKENKEY";
  static String refreshTokenKey = "REFRESHTOKENKEY";
  static String spotifyAPIKey = "SPOTIFYAPIKEY";
  static String oauth2APIKey = "OAUTH2APIKEY";
  static String oauth2APIClientIDKey = "OAUTH2APICLIENTIDKEY";
  static String localeKey = "LOCALEKEY";
  static String marketKey = "MARKETKEY";

  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\ //
  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\ //

  // Singned In
  Future<void> writeSignedIn(bool signedIn) async {
    await storage.write(key: singedInKey, value: signedIn.toString());
  }

  Future<bool> getSignedIn() async {
    String? key = await storage.read(key: singedInKey);
    if (key == null) {
      return false;
    } else {
      return key == "true";
    }
  }

  // Access Token
  Future<void> writeAccessToken(String? accessToken) async {
    await storage.write(key: accessTokenKey, value: accessToken);
  }

  Future<String?> getAccessToken() async {
    String? key = await storage.read(key: accessTokenKey);
    if (key == null) {
      return null;
    } else {
      return key;
    }
  }

  // Refresh Token
  Future<void> writeRefreshToken(String? refreshToken) async {
    await storage.write(key: refreshTokenKey, value: refreshToken);
  }

  Future<String?> getRefreshToken() async {
    String? key = await storage.read(key: refreshTokenKey);
    if (key == null) {
      return null;
    } else {
      return key;
    }
  }

  // Spotify API Key
  Future<void> writeSpotifyAPIKey(String spotifyAPI) async {
    await storage.write(key: spotifyAPIKey, value: spotifyAPI);
  }

  Future<String?> getSpotifyAPIKey() async {
    String? key = await storage.read(key: spotifyAPIKey);
    if (key == null) {
      return null;
    } else {
      return key;
    }
  }

  // OAuth2 API Client ID
  Future<void> writeOAuth2APIClientID(String oAuth2APIClientID) async {
    await storage.write(key: oauth2APIClientIDKey, value: oAuth2APIClientID);
  }

  Future<String?> getOAuth2APIClientID() async {
    String? key = await storage.read(key: oauth2APIClientIDKey);
    if (key == null) {
      return null;
    } else {
      return key;
    }
  }

  // Locale
  Future<void> writeLocale(String locale) async {
    await storage.write(key: localeKey, value: locale);
  }

  Future<String?> getLocale() async {
    String? key = await storage.read(key: localeKey);
    if (key == null) {
      return "en";
    } else {
      return key;
    }
  }

  // Market
  Future<void> writeMarket(String market) async {
    await storage.write(key: marketKey, value: market);
  }

  Future<String?> getMarket() async {
    String? key = await storage.read(key: marketKey);
    if (key == null) {
      return "US";
    } else {
      return key;
    }
  }

  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\ //
}
