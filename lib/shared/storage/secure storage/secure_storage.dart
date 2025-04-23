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
  static String enableLyricsKey = "ENABLEYRCSKEY";
  static String loopModeKey = "LOOPMODEKEY";
  static String shuffleModeKey = "SHUFFLEMODEKEY";
  static String enableHistoryKey = "ENABLEHISTORYKEY";
  static String enableCategoriesKey = "ENABLECATEGORIESKEY";
  static String numOfCategoriesKey = "NUMOFCATEGORIESKEY";
  static String queueKey = "QUEUEKEY";
  static String queueIndexKey = "QUEUEINDEXKEY";
  static String currentPLayingPositionKey = "CURRENTPLAYINGPOSITIONKEY";
  static String cacheImagesKey = "CACHEIMAGESKEY";
  static String localsSortKey = "LOCALSSORTKEY";
  static String subscriptionKey = "SUBSCRIPTIONKEY";
  static String subscriptionEndKey = "SUBSCRIPTIONENDKEY";
  static String useBlurKey = "USEBLURKEY";
  static String useMixKey = "USEMIXKEY";
  static String useDetailedBlurhashKey = " USEDETAILEDBLURHASHKEY";
  static String sleepAlarmDeviceVolumeKey = "SLEEPALARMDEVICEVOLUMEKEY";
  static String darkModeKey = "DARKMODEKEY";
  static String linearSleepinKey = "LINEARSLEEPINKEY";
  static String linearWakeupKey = "LINEARWAKEUPKEY";

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
      return true;
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
      return 1;
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
      return 1;
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
      return TextAlign.left;
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
      return false;
    } else {
      return key == "true";
    }
  }

  // Get enable lyrics
  Future<void> writeEnableLyrics(bool useLyrics) async {
    await storage.write(key: enableLyricsKey, value: useLyrics.toString());
  }

  Future<bool> getEnableLyrics() async {
    String? key = await storage.read(key: enableLyricsKey);
    if (key == null) {
      return true;
    } else {
      return key == "true";
    }
  }

  // Get loop
  Future<void> writeLoopMode(LoopMode loopMode) async {
    await storage.write(key: loopModeKey, value: loopMode.toString());
  }

  Future<AudioServiceRepeatMode> getLoopMode() async {
    String? key = await storage.read(key: loopModeKey);
    if (key == "LoopMode.off") {
      return AudioServiceRepeatMode.none;
    } else if (key == "LoopMode.one") {
      return AudioServiceRepeatMode.one;
    } else {
      return AudioServiceRepeatMode.all;
    }
  }

  // Get shuffle
  Future<void> writeShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    await storage.write(key: shuffleModeKey, value: shuffleMode.toString());
  }

  Future<AudioServiceShuffleMode> getShuffleMode() async {
    String? key = await storage.read(key: shuffleModeKey);
    if (key == "AudioServiceShuffleMode.all") {
      return AudioServiceShuffleMode.all;
    } else {
      return AudioServiceShuffleMode.none;
    }
  }

  // Get enable history
  Future<void> writeEnableHistory(bool enableHistory) async {
    await storage.write(key: enableHistoryKey, value: enableHistory.toString());
  }

  Future<bool> getEnableHistory() async {
    String? key = await storage.read(key: enableHistoryKey);
    if (key == null) {
      return true;
    } else {
      return key == "true";
    }
  }

  // Get enable categories
  Future<void> writeEnableCategories(bool enableCategories) async {
    await storage.write(
        key: enableCategoriesKey, value: enableCategories.toString());
  }

  Future<bool> getEnableCategories() async {
    String? key = await storage.read(key: enableCategoriesKey);
    if (key == null) {
      return true;
    } else {
      return key == "true";
    }
  }

  // Num of categories
  Future<void> writeNumOfCategories(int numOfCategories) async {
    await storage.write(
        key: numOfCategoriesKey, value: numOfCategories.toString());
  }

  Future<int> getNumOfCategories() async {
    String? key = await storage.read(key: numOfCategoriesKey);
    if (key == null) {
      return 50;
    } else {
      return int.parse(key);
    }
  }

  // Queue media items
  Future<void> writeQueue(List<MediaItem> queue) async {
    await storage.write(key: queueKey, value: mediaItemsToString(queue));
  }

  Future<List<MediaItem>> getQueue() async {
    String? key = await storage.read(key: queueKey);
    if (key == null) {
      return [];
    } else {
      return stringToMediaItems(key);
    }
  }

  // Convert a list of MediaItems to a JSON string
  String mediaItemsToString(List<MediaItem> mediaItems) {
    List<Map<String, dynamic>> jsonList =
        mediaItems.map((item) => mediaItemToJson(item)).toList();
    return jsonEncode(jsonList);
  }

// Convert a JSON string back to a list of MediaItems
  List<MediaItem> stringToMediaItems(String mediaItemsString) {
    List<dynamic> jsonList = jsonDecode(mediaItemsString);
    return jsonList
        .map((json) => mediaItemFromJson(Map<String, dynamic>.from(json)))
        .toList();
  }

// Serialize a MediaItem to JSON
  Map<String, dynamic> mediaItemToJson(MediaItem item) {
    return {
      'id': item.id,
      'title': item.title,
      'album': item.album,
      'artist': item.artist,
      'duration': item.duration?.inMilliseconds, // Convert to milliseconds
      'artUri': item.artUri?.toString(),
      'extras': item.extras,
    };
  }

// Deserialize a JSON map back to a MediaItem
  MediaItem mediaItemFromJson(Map<String, dynamic> json) {
    return MediaItem(
      id: json['id'],
      title: json['title'],
      album: json['album'],
      artist: json['artist'],
      duration: json['duration'] != null
          ? Duration(milliseconds: json['duration'])
          : null,
      artUri: json['artUri'] != null ? Uri.parse(json['artUri']) : null,
      extras: json['extras'],
    );
  }

  // Queue current index
  Future<void> writeQueueIndex(int queueIndex) async {
    await storage.write(key: queueIndexKey, value: queueIndex.toString());
  }

  Future<int> getQueueIndex() async {
    String? key = await storage.read(key: queueIndexKey);
    if (key == null) {
      return -1;
    } else {
      return int.parse(key);
    }
  }

  // Current palying position
  Future<void> writeCurrentPlayingPosition(
      Duration currentPlayingPosition) async {
    await storage.write(
        key: currentPLayingPositionKey,
        value: currentPlayingPosition.inMicroseconds.toString());
  }

  Future<Duration> getCurrentPlayingPosition() async {
    String? key = await storage.read(key: currentPLayingPositionKey);
    if (key == null) {
      return Duration.zero;
    } else {
      return Duration(microseconds: int.parse(key));
    }
  }

  // Cache images
  Future<void> writeCacheImages(bool cacheImages) async {
    await storage.write(key: cacheImagesKey, value: cacheImages.toString());
  }

  Future<bool> getCacheImages() async {
    String? key = await storage.read(key: cacheImagesKey);
    if (key == null) {
      return false;
    } else {
      return key == "true";
    }
  }

  // Locals sort
  Future<void> writeLocalsSort(String localsSort) async {
    await storage.write(key: localsSortKey, value: localsSort.toString());
  }

  Future<String> getLocalsSort() async {
    String? key = await storage.read(key: localsSortKey);
    if (key == null) {
      return "A-Z";
    } else {
      return key;
    }
  }

  // Subscription
  Future<void> writeSubscription(bool subscription) async {
    await storage.write(key: subscriptionKey, value: subscription.toString());
  }

  Future<bool> getSubscription() async {
    String? key = await storage.read(key: subscriptionKey);
    if (key == null) {
      return false;
    } else {
      return key == "true";
    }
  }

  // Subscription end
  Future<void> writeSubscriptionEnd(String subscriptionEnd) async {
    await storage.write(key: subscriptionEndKey, value: subscriptionEnd);
  }

  Future<DateTime> getSubscriptionEnd() async {
    String? key = await storage.read(key: subscriptionEndKey);
    if (key == null) {
      return DateTime.now();
    } else {
      return DateTime.parse(key);
    }
  }

  // Blur usage
  Future<void> writeUseBlur(bool useBlur) async {
    await storage.write(key: useBlurKey, value: useBlur.toString());
  }

  Future<bool> getUseBlur() async {
    String? key = await storage.read(key: useBlurKey);
    if (key == null) {
      return true;
    } else {
      return key == "true";
    }
  }

  // Mix usage
  Future<void> writeUseMix(bool useMix) async {
    await storage.write(key: useMixKey, value: useMix.toString());
  }

  Future<bool> getUseMix() async {
    String? key = await storage.read(key: useMixKey);
    if (key == null) {
      return true;
    } else {
      return key == "true";
    }
  }

  // Use detailed blurhash
  Future<void> writeUseDetailedBlurhash(bool useDetailedBlurhash) async {
    await storage.write(
        key: useDetailedBlurhashKey, value: useDetailedBlurhash.toString());
  }

  Future<bool> getUseDetailedBlurhash() async {
    String? key = await storage.read(key: useDetailedBlurhashKey);
    if (key == null) {
      return true;
    } else {
      return key == "true";
    }
  }

  // sleep alarm device volume
  Future<void> writeSleepAlarmDeviceVolume(
      double sleepAlarmDeviceVolume) async {
    await storage.write(
        key: sleepAlarmDeviceVolumeKey,
        value: sleepAlarmDeviceVolume.toString());
  }

  Future<double> getSleepAlarmDeviceVolume() async {
    String? key = await storage.read(key: sleepAlarmDeviceVolumeKey);
    if (key == null) {
      //----------------------------------------------------------------
      return VolumeManager()
          .currentVolume; /* 
      final volumeManager = Provider.of<VolumeManager>(
          notificationsContext.value!,
          listen: false);
           */
      //----------------------------------------------------------------
    } else {
      return double.parse(key);
    }
  }

  // Dark mode on
  Future<void> writeDarkMode(bool darkMode) async {
    await storage.write(key: darkModeKey, value: darkMode.toString());
  }

  Future<bool> getDarkMode() async {
    String? key = await storage.read(key: darkModeKey);
    if (key == null) {
      return true;
    } else {
      return key == "true";
    }
  }

  // Linear sleep-in on
  Future<void> writeLinearSleepin(bool linearSleepin) async {
    await storage.write(key: linearSleepinKey, value: linearSleepin.toString());
  }

  Future<bool> getLinearSleepin() async {
    String? key = await storage.read(key: linearSleepinKey);
    if (key == null) {
      return true;
    } else {
      return key == "true";
    }
  }

  // Linear wake-up
  Future<void> writeLinearWakeup(bool linearWakeup) async {
    await storage.write(key: linearWakeupKey, value: linearWakeup.toString());
  }

  Future<bool> getLinearWakeup() async {
    String? key = await storage.read(key: linearWakeupKey);
    if (key == null) {
      return true;
    } else {
      return key == "true";
    }
  }

  // \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\ //
}
