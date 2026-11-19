import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keys of the values kept in secure storage.
///
/// The strings are stored on users' devices, so they must never change.
abstract final class StorageKeys {
  static const signedIn = 'SIGNEDIN';
  static const accessToken = 'ACCESSTOKENKEY';
  static const refreshToken = 'REFRESHTOKENKEY';
  static const streamToken = 'STREAMTOKEN';
  static const locale = 'LOCALEKEY';
  static const market = 'MARKETKEY';
  static const syncDelay = 'SYNCDELAYKEY';
  static const useSyncedLyrics = 'USESYNCEDLYRICSKEY';
  static const searchArtistCount = 'NUMOFSEARCHARTISTSKEY';
  static const searchAlbumCount = 'NUMOFSEARCHALBUMSKEY';
  static const searchTrackCount = 'NUMOFSEARCHTRACKSKEY';
  static const searchPlaylistCount = 'NUMOFSEARCHPLAYLISTSKEY';
  static const lyricsTextAlign = 'LYRICSTEXTALIGNKEY';
  static const useCacheAudioSource = 'CACHEAUDIOSOURCEKEY';
  static const streamWhileDownloading = 'STREAMWHILEDOWNLOADINGKEY';
  static const enableLyrics = 'ENABLEYRCSKEY';
  static const loopMode = 'LOOPMODEKEY';
  static const shuffleMode = 'SHUFFLEMODEKEY';
  static const enableHistory = 'ENABLEHISTORYKEY';
  static const enableCategories = 'ENABLECATEGORIESKEY';
  static const categoryCount = 'NUMOFCATEGORIESKEY';
  static const queue = 'QUEUEKEY';
  static const queueIndex = 'QUEUEINDEXKEY';
  static const playingPosition = 'CURRENTPLAYINGPOSITIONKEY';
  static const cacheImages = 'CACHEIMAGESKEY';
  static const localsSort = 'LOCALSSORTKEY';
  static const useBlur = 'USEBLURKEY';
  static const useMix = 'USEMIXKEY';
  // The leading space is a historical typo kept for existing installs.
  static const useDetailedBlurhash = ' USEDETAILEDBLURHASHKEY';
  static const sleepAlarmDeviceVolume = 'SLEEPALARMDEVICEVOLUMEKEY';
  static const darkMode = 'DARKMODEKEY';
  static const linearSleepIn = 'LINEARSLEEPINKEY';
  static const linearWakeUp = 'LINEARWAKEUPKEY';
  static const dynamicBlurhash = 'DYNAMICBLURHASH';
  static const useAnimations = 'USEANIMATIONSKEY';
  static const useLiquidGlass = 'USELIQUIDGLASSKEY';
}

/// Reads and writes string values in the platform's secure storage.
class SecureStorageService {
  /// Creates a service backed by [storage].
  SecureStorageService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  /// The value stored under [key], or `null` if there is none.
  Future<String?> read(String key) => _storage.read(key: key);

  /// Stores [value] under [key], deleting the entry when [value] is `null`.
  Future<void> write(String key, String? value) =>
      _storage.write(key: key, value: value);

  /// The boolean stored under [key], or [fallback] if there is none.
  Future<bool> readBool(String key, {required bool fallback}) async {
    final value = await read(key);
    return value == null ? fallback : value == 'true';
  }

  /// Stores the boolean [value] under [key].
  Future<void> writeBool(String key, {required bool value}) =>
      write(key, value.toString());

  /// The integer stored under [key], or [fallback] if there is none.
  Future<int> readInt(String key, {required int fallback}) async {
    final value = await read(key);
    return value == null ? fallback : int.tryParse(value) ?? fallback;
  }

  /// Stores the integer [value] under [key].
  Future<void> writeInt(String key, int value) => write(key, value.toString());

  /// The double stored under [key], or `null` if there is none.
  Future<double?> readDouble(String key) async {
    final value = await read(key);
    return value == null ? null : double.tryParse(value);
  }

  /// Stores the double [value] under [key].
  Future<void> writeDouble(String key, double value) =>
      write(key, value.toString());
}
