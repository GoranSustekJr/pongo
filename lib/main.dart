import 'package:pongo/exports.dart';

Future<void> configureMacosWindowUtils() async {
  const config = MacosWindowUtilsConfig(
    toolbarStyle: NSWindowToolbarStyle.unified,
  );
  await config.apply();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Audio Session Configuration
  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.music());

  // Initialize the audio handle
  late AudioHandler audioHandler;
  audioHandler = await AudioService.init(
    builder: () => AudioServiceHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId:
          'com.goransustekdoo.ddns.net.3.pongo.channel.audio',
      androidNotificationChannelName: 'Music playback Pongo',
    ),
  );

  // Macos config
  if (kIsMacOS) {
    await configureMacosWindowUtils();
  }
  // DB init
  final DatabaseHelper databaseHelper = DatabaseHelper();

  // Initialize database
  await databaseHelper.initDatabase();

  // Internet Connectition Handler
  InternetConnectivityHandler internetConnectivityHandler =
      InternetConnectivityHandler();

  // Volume Manager instance and initialize it
  VolumeManager volumeManager = VolumeManager();
  if (kIsMobile) {
    await volumeManager.initializeVolume();
  }

  // Init Access TokenÞ

  AccessToken accessTokenJWT = AccessToken();
  await accessTokenJWT.initializeAccessToken();

  // Is User Signed In
  bool signedIn = await Storage().getSignedIn();
  isUserSignedIn.value = signedIn;

  // Preferences
  bool syncTimeDelay = await Storage().getSyncDelay(); // use sync delay
  useSyncTimeDelay.value = syncTimeDelay;
  bool syncedLyircs = await Storage().getUseSyncedLyrics(); // use synced lyrics
  useSyncedLyrics.value = syncedLyircs;
  int numSearchArtists =
      await Storage().getNumOfSearchArtists(); // Num of search artists
  numberOfSearchArtists.value = numSearchArtists;
  int numSearchAlbums =
      await Storage().getNumOfSearchAlbums(); // Num of search albums
  numberOfSearchAlbums.value = numSearchAlbums;
  int numSearchTracks =
      await Storage().getNumOfSearchTracks(); // Num of search tracks
  numberOfSearchTracks.value = numSearchTracks;
  int numSearchPlaylists =
      await Storage().getNumOfSearchPlaylists(); // Num of search playlists
  numberOfSearchPlaylists.value = numSearchPlaylists;
  TextAlign curLyricsTextAlignment =
      await Storage().getLyricsTextAlign(); // Lyrics alignment
  currentLyricsTextAlignment.value = curLyricsTextAlignment;
  bool useCache =
      await Storage().getUseCachingAudioSource(); // Audio source type
  useCacheAudioSource.value = useCache;
  bool enblLyrics = await Storage().getEnableLyrics(); // Enable lyrics
  enableLyrics.value = enblLyrics;
  bool cacheImags = await Storage().getCacheImages(); // Cache images
  cacheImages.value = cacheImags;

  if (kIsAndroid) {
    await FlutterDisplayMode.setHighRefreshRate();
  }

  if (kIsDesktop) {
    await windowManager.ensureInitialized();
    await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
    //await windowManager.setPreventClose(true);
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1066, 625),
      minimumSize: Size(1066, 625),
      center: true,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]).then((_) {
    runApp(
      MultiProvider(
        providers: [
          Provider<AudioHandler>.value(value: audioHandler),
          Provider<InternetConnectivityHandler>.value(
              value: internetConnectivityHandler),
          if (kIsMobile) Provider<VolumeManager>.value(value: volumeManager),
          Provider<AccessToken>.value(value: accessTokenJWT),
        ],
        child: Builder(
          builder: (context) {
            return const MyAppPhone();
          },
        ),
      ),
    );
  });
}
