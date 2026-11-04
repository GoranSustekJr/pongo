// ignore_for_file: depend_on_referenced_packages


import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:window_manager/window_manager.dart';

import 'package:pongo/app/desktop_app.dart';
import 'package:pongo/app/phone_app.dart';
import 'package:pongo/core/audio/audio_service_handler.dart';
import 'package:pongo/core/audio/volume_manager.dart';
import 'package:pongo/core/constants/platform.dart';
import 'package:pongo/core/network/connectivity_handler.dart';
import 'package:pongo/core/state/globals.dart';
import 'package:pongo/core/storage/database/database_helper.dart';
import 'package:pongo/core/storage/secure_storage.dart';
import 'package:pongo/features/auth/models/access_token.dart';

Future<void> configureMacosWindowUtils() async {
  const config = MacosWindowUtilsConfig(
    toolbarStyle: NSWindowToolbarStyle.expanded,
    autoHideToolbarAndMenuBarInFullScreenMode: false,
  );
  await config.apply();
  //await windowManager.ensureInitialized();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();

  // Init .env file
  await dotenv.load(fileName: '.env');

  // Macos config
  if (kIsMacOS) {
    await configureMacosWindowUtils();
  }

  if (kIsDesktop && !kIsMacOS) {
    await windowManager.ensureInitialized();
    await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
    //await windowManager.setPreventClose(true);
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1066, 625),
      minimumSize: Size(1066, 625),
      titleBarStyle: TitleBarStyle.hidden,
      center: true,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // Audio Session Configuration
  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.music());

  // Audio urls carry this token, so it has to be ready before a saved queue is restored
  streamToken = await Storage().getStreamToken() ?? "";

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
  bool enablUeseBlur = await Storage().getUseBlur(); // Usage of blur
  useBlur.value = enablUeseBlur;
  bool enableDetailedBlurhash =
      await Storage().getUseDetailedBlurhash(); // Detailed blurhash
  detailedBlurhash.value = enableDetailedBlurhash;
  bool enableUseMix = await Storage().getUseMix(); // Use mix
  useMix.value = enableUseMix;
  double sleepAlarmDevicVolume = await Storage().getSleepAlarmDeviceVolume();
  sleepAlarmDevVolume = sleepAlarmDevicVolume;
  bool drkMode = await Storage().getDarkMode();
  darkMode.value = drkMode;
  bool usDynamicBlurhash = await Storage().getUseDynamicBlurhash();
  useDynamicBlurhash = usDynamicBlurhash;
  bool usLiquidGlass = await Storage().getUseLiquidGlass();
  liquidGlassEnabled = usLiquidGlass;

  if (kIsAndroid) {
    await FlutterDisplayMode.setHighRefreshRate();
  }

  if (kIsDesktop && !kIsMacOS) {
    await windowManager.ensureInitialized();
    await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
    //await windowManager.setPreventClose(true);
    WindowOptions windowOptions = const WindowOptions(
      size: Size(938, 550),
      minimumSize: Size(938, 550),
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
        child: ValueListenableBuilder(
          valueListenable: darkMode,
          builder: (context, _, __) {
            return kIsMobile ? const MyAppPhone() : const MyAppDesktop();
          },
        ),
      ),
    );
  });
}
