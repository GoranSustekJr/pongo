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
  static String syncDelayKey = "SYNCDELAYKEY";
  static String useSyncedLyricsKey = "USESYNCEDLYRICSKEY";
  static String numOfSearchArtistsKey = "NUMOFSEARCHARTISTSKEY";
  static String numOfSearchAlbumsKey = "NUMOFSEARCHALBUMSKEY";
  static String numOfSearchTracksKey = "NUMOFSEARCHTRACKSKEY";
  static String numOfSearchPlaylistsKey = "NUMOFSEARCHPLAYLISTSKEY";
  static String recommendedForYouKey = "RECOMMENDEDFORYOUKEY";
  static String recommendedPongoKey = "RECOMMENDEDPONGOKEY";
  static String lyricsTextAlignKey = "LYRICSTEXTALIGNKEY";
  static String useCacheAudioSourceKey = "CACHEAUDIOSOURCEKEY";

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

  // Sync delay
  Future<void> writeSyncDelay(bool syncDelay) async {
    await storage.write(key: syncDelayKey, value: syncDelay.toString());
  }

  Future<bool> getSyncDelay() async {
    String? key = await storage.read(key: syncDelayKey);
    if (key == null) {
      return false;
    } else {
      return key == "true";
    }
  }

  // Sync lyrics
  Future<void> writeUseSyncedLyrics(bool useSyncedLyrics) async {
    await storage.write(
        key: useSyncedLyricsKey, value: useSyncedLyrics.toString());
  }

  Future<bool> getUseSyncedLyrics() async {
    String? key = await storage.read(key: useSyncedLyricsKey);
    if (key == null) {
      return false;
    } else {
      return key == "true";
    }
  }

  // Num of search artists
  Future<void> writeNumOfSearchArtists(int numOfSearchArtists) async {
    await storage.write(
        key: numOfSearchArtistsKey, value: numOfSearchArtists.toString());
  }

  Future<int> getNumOfSearchArtists() async {
    String? key = await storage.read(key: numOfSearchArtistsKey);
    if (key == null) {
      return 3;
    } else {
      return int.parse(key);
    }
  }

  // Num of search albums
  Future<void> writeNumOfSearchAlbums(int numOfSearchAlbums) async {
    await storage.write(
        key: numOfSearchAlbumsKey, value: numOfSearchAlbums.toString());
  }

  Future<int> getNumOfSearchAlbums() async {
    String? key = await storage.read(key: numOfSearchAlbumsKey);
    if (key == null) {
      return 5;
    } else {
      return int.parse(key);
    }
  }

  // Num of search tracks
  Future<void> writeNumOfSearchTracks(int numOfSearchTracks) async {
    await storage.write(
        key: numOfSearchTracksKey, value: numOfSearchTracks.toString());
  }

  Future<int> getNumOfSearchTracks() async {
    String? key = await storage.read(key: numOfSearchTracksKey);
    if (key == null) {
      return 50;
    } else {
      return int.parse(key);
    }
  }

  // Num of search playlists
  Future<void> writeNumOfSearchPlaylists(int numOfSearchPlaylists) async {
    await storage.write(
        key: numOfSearchPlaylistsKey, value: numOfSearchPlaylists.toString());
  }

  Future<int> getNumOfSearchPlaylists() async {
    String? key = await storage.read(key: numOfSearchPlaylistsKey);
    if (key == null) {
      return 20;
    } else {
      return int.parse(key);
    }
  }

  // Get recommendations for oyu
  Future<void> writeRecommendedForYou(bool recommendedForYou) async {
    await storage.write(
        key: recommendedForYouKey, value: recommendedForYou.toString());
  }

  Future<bool> getRecommendedForYou() async {
    String? key = await storage.read(key: recommendedForYouKey);
    if (key == null) {
      return true;
    } else {
      return key == "true";
    }
  }

  // Get recommendations by Pongo
  Future<void> writeRecommendedPongo(bool recommendedPongo) async {
    await storage.write(
        key: recommendedPongoKey, value: recommendedPongo.toString());
  }

  Future<bool> getRecommendedPongo() async {
    String? key = await storage.read(key: recommendedPongoKey);
    if (key == null) {
      return true;
    } else {
      return key == "true";
    }
  }

  // Get lyrics text align
  Future<void> writeLyricsTextAlign(TextAlign lyricsTextAlign) async {
    await storage.write(
        key: lyricsTextAlignKey, value: lyricsTextAlign.toString());
  }

  Future<TextAlign> getLyricsTextAlign() async {
    String? key = await storage.read(key: lyricsTextAlignKey);
    if (key == null) {
      return TextAlign.center;
    } else if (key == "TextAlign.left") {
      return TextAlign.left;
    } else if (key == "TextAlign.right") {
      return TextAlign.right;
    } else if (key == "TextAlign.justify") {
      return TextAlign.justify;
    } else {
      return TextAlign.center;
    }
  }

  // Use cachinga audio source
  Future<void> writeUseCacheAudioSource(bool useCacheAudioSource) async {
    await storage.write(
        key: useCacheAudioSourceKey, value: useCacheAudioSource.toString());
  }

  Future<bool> getUseCachingAudioSource() async {
    String? key = await storage.read(key: useCacheAudioSourceKey);
    if (key == null) {
      return true;
    } else {
      return key == "true";
    }
  }

  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\ //
}
