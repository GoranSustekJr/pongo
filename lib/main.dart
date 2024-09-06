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
  //final session = await AudioSession.instance;
  //await session.configure(AudioSessionConfiguration.music());

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
