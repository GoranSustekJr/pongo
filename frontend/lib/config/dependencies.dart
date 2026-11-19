import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../data/repositories/auth/auth_repository.dart';
import '../data/repositories/auth/auth_repository_remote.dart';
import '../data/repositories/catalog/catalog_repository.dart';
import '../data/repositories/catalog/catalog_repository_remote.dart';
import '../data/repositories/history/history_repository.dart';
import '../data/repositories/history/history_repository_local.dart';
import '../data/repositories/library/downloads_repository.dart';
import '../data/repositories/library/downloads_repository_local.dart';
import '../data/repositories/library/favourites_repository.dart';
import '../data/repositories/library/favourites_repository_local.dart';
import '../data/repositories/library/library_sync.dart';
import '../data/repositories/lyrics/lyrics_repository.dart';
import '../data/repositories/lyrics/lyrics_repository_remote.dart';
import '../data/repositories/player/player_repository.dart';
import '../data/repositories/player/player_repository_audio.dart';
import '../data/repositories/player/track_gains.dart';
import '../data/repositories/playlists/playlist_repository.dart';
import '../data/repositories/playlists/playlist_repository_local.dart';
import '../data/repositories/settings/settings_repository.dart';
import '../data/repositories/settings/settings_repository_local.dart';
import '../data/repositories/settings/settings_sync_source.dart';
import '../data/repositories/sleep_alarm/sleep_alarm_repository.dart';
import '../data/repositories/sleep_alarm/sleep_alarm_repository_local.dart';
import '../data/services/api/api_client.dart';
import '../data/services/api/lyrics_api_client.dart';
import '../data/services/api/track_socket_service.dart';
import '../data/services/audio/pongo_audio_handler.dart';
import '../data/services/audio/sleep_alarm_log.dart';
import '../data/services/auth/identity_service.dart';
import '../data/services/database/database_service.dart';
import '../data/services/device/connectivity_service.dart';
import '../data/services/device/volume_service.dart';
import '../data/services/local/secure_storage_service.dart';
import '../data/services/media/blurhash_service.dart';
import '../data/services/media/image_bytes_service.dart';
import '../utils/platform.dart';
import 'app_config.dart';

/// Creates and starts every service and repository, and returns the
/// providers that make them available to the widget tree.
///
/// View models get their dependencies from these providers; nothing else in
/// the app is global.
Future<List<SingleChildWidget>> createProviders(AppConfig config) async {
  final storage = SecureStorageService();
  final apiClient = ApiClient(config: config);
  final socketService = TrackSocketService(config: config);

  final database = DatabaseService();
  await database.open();

  final connectivity = ConnectivityService();
  await connectivity.start();

  final volume = VolumeService();
  if (kIsMobile) await volume.start();

  final auth = AuthRepositoryRemote(
    config: config,
    apiClient: apiClient,
    socketService: socketService,
    identityService: IdentityService(config: config),
    storage: storage,
  );
  await auth.load();

  final settings = SettingsRepositoryLocal(
    storage: storage,
    deviceVolume: () => volume.volume,
  );
  await settings.load();

  final alarmLog = SleepAlarmLog();
  final cacheDirectory = '${(await getTemporaryDirectory()).path}/tracks';
  final gains = TrackGains(apiClient: apiClient, table: database.trackGains);
  final handler = await AudioService.init(
    builder: () => PongoAudioHandler(
      volumeService: volume,
      alarmLog: alarmLog,
      cacheDirectory: cacheDirectory,
      gainFor: gains.gainFor,
      streamUrl: (stid, {caching = false}) =>
          '${config.serverUrl}'
          '${caching ? 'play_song_caching' : 'play_song'}/'
          '${kIsApple ? '' : 'android/'}$stid?st=${auth.streamToken}',
    ),
    config: const AudioServiceConfig(
      androidNotificationChannelId:
          'com.goransustekdoo.ddns.net.3.pongo.channel.audio',
      androidNotificationChannelName: 'Music playback Pongo',
    ),
  );
  void applyAudioPreferences() {
    final current = settings.settings;
    handler.preferences = (
      useCachingSource: current.useCacheAudioSource,
      linearSleepIn: current.linearSleepIn,
      linearWakeUp: current.linearWakeUp,
      alarmDeviceVolume: current.sleepAlarmDeviceVolume,
    );
  }

  final session = await AudioSession.instance;
  session.interruptionEventStream.listen((event) {
    if (handler.activeSleepAlarm == -1) return;
    alarmLog.add(
      'interruption ${event.type.name}, ${event.begin ? 'began' : 'ended'}',
    );
  });

  applyAudioPreferences();
  settings.addListener(applyAudioPreferences);

  final player = PlayerRepositoryAudio(
    handler: handler,
    apiClient: apiClient,
    socketService: socketService,
    storage: storage,
    gains: gains,
  );
  await player.restoreState();

  final librarySync = LibrarySync(
    apiClient: apiClient,
    store: database.sync,
    sources: [database.sync, SettingsSyncSource(settings)],
  );
  // Syncs while signed in; signing out forgets what was synced, so another
  // account starts afresh
  var wasSignedIn = false;
  void followSession() {
    if (auth.isSignedIn) {
      unawaited(librarySync.start());
    } else if (wasSignedIn) {
      unawaited(librarySync.reset());
    }
    wasSignedIn = auth.isSignedIn;
  }

  auth.addListener(followSession);
  followSession();

  return [
    Provider.value(value: connectivity),
    Provider.value(value: volume),
    Provider.value(value: BlurhashService()),
    Provider.value(value: ImageBytesService()),
    ChangeNotifierProvider<AuthRepository>.value(value: auth),
    ChangeNotifierProvider<SettingsRepository>.value(value: settings),
    ChangeNotifierProvider.value(value: librarySync),
    Provider<PlayerRepository>.value(value: player),
    Provider<CatalogRepository>.value(
      value: CatalogRepositoryRemote(apiClient: apiClient),
    ),
    Provider<FavouritesRepository>.value(
      value: FavouritesRepositoryLocal(database: database),
    ),
    Provider<DownloadsRepository>.value(
      value: DownloadsRepositoryLocal(
        apiClient: apiClient,
        socketService: socketService,
        database: database,
      ),
    ),
    Provider<PlaylistRepository>.value(
      value: PlaylistRepositoryLocal(database: database),
    ),
    Provider<HistoryRepository>.value(
      value: HistoryRepositoryLocal(database: database),
    ),
    Provider<SleepAlarmRepository>.value(
      value: SleepAlarmRepositoryLocal(database: database),
    ),
    Provider<LyricsRepository>.value(
      value: LyricsRepositoryRemote(
        client: LyricsApiClient(),
        database: database,
      ),
    ),
  ];
}
