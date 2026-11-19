import 'package:flutter/painting.dart';

import '../../../domain/models/settings/app_settings.dart';
import '../../services/local/secure_storage_service.dart';
import 'settings_repository.dart';

/// A [SettingsRepository] kept in secure storage on the device.
class SettingsRepositoryLocal extends SettingsRepository {
  /// Creates a repository backed by [_storage].
  ///
  /// The device volume from [_deviceVolume] is the alarm volume until the
  /// user picks one.
  SettingsRepositoryLocal({
    required this._storage,
    required this._deviceVolume,
  });

  final SecureStorageService _storage;
  final double Function() _deviceVolume;

  AppSettings _settings = const AppSettings();

  @override
  AppSettings get settings => _settings;

  @override
  Future<void> load() async {
    const defaults = AppSettings();
    Future<bool> readBool(String key, {required bool fallback}) =>
        _storage.readBool(key, fallback: fallback);
    Future<int> readInt(String key, int fallback) =>
        _storage.readInt(key, fallback: fallback);

    final localsSort = await _storage.read(StorageKeys.localsSort);
    _settings = AppSettings(
      locale: await _storage.read(StorageKeys.locale) ?? defaults.locale,
      market: await _storage.read(StorageKeys.market) ?? defaults.market,
      useSyncTimeDelay: await readBool(
        StorageKeys.syncDelay,
        fallback: defaults.useSyncTimeDelay,
      ),
      useSyncedLyrics: await readBool(
        StorageKeys.useSyncedLyrics,
        fallback: defaults.useSyncedLyrics,
      ),
      searchArtistCount: await readInt(
        StorageKeys.searchArtistCount,
        defaults.searchArtistCount,
      ),
      searchAlbumCount: await readInt(
        StorageKeys.searchAlbumCount,
        defaults.searchAlbumCount,
      ),
      searchTrackCount: await readInt(
        StorageKeys.searchTrackCount,
        defaults.searchTrackCount,
      ),
      searchPlaylistCount: await readInt(
        StorageKeys.searchPlaylistCount,
        defaults.searchPlaylistCount,
      ),
      lyricsTextAlign: _textAlign(
        await _storage.read(StorageKeys.lyricsTextAlign),
      ),
      useCacheAudioSource: await readBool(
        StorageKeys.useCacheAudioSource,
        fallback: defaults.useCacheAudioSource,
      ),
      enableLyrics: await readBool(
        StorageKeys.enableLyrics,
        fallback: defaults.enableLyrics,
      ),
      enableHistory: await readBool(
        StorageKeys.enableHistory,
        fallback: defaults.enableHistory,
      ),
      enableCategories: await readBool(
        StorageKeys.enableCategories,
        fallback: defaults.enableCategories,
      ),
      categoryCount: await readInt(
        StorageKeys.categoryCount,
        defaults.categoryCount,
      ),
      cacheImages: await readBool(
        StorageKeys.cacheImages,
        fallback: defaults.cacheImages,
      ),
      localsSort: localsSort == null
          ? defaults.localsSort
          : LocalsSort.fromStorage(localsSort),
      useBlur: await readBool(StorageKeys.useBlur, fallback: defaults.useBlur),
      useMix: await readBool(StorageKeys.useMix, fallback: defaults.useMix),
      useDetailedBlurhash: await readBool(
        StorageKeys.useDetailedBlurhash,
        fallback: defaults.useDetailedBlurhash,
      ),
      sleepAlarmDeviceVolume:
          await _storage.readDouble(StorageKeys.sleepAlarmDeviceVolume) ??
          _deviceVolume(),
      darkMode: await readBool(
        StorageKeys.darkMode,
        fallback: defaults.darkMode,
      ),
      linearSleepIn: await readBool(
        StorageKeys.linearSleepIn,
        fallback: defaults.linearSleepIn,
      ),
      linearWakeUp: await readBool(
        StorageKeys.linearWakeUp,
        fallback: defaults.linearWakeUp,
      ),
      useDynamicBlurhash: await readBool(
        StorageKeys.dynamicBlurhash,
        fallback: defaults.useDynamicBlurhash,
      ),
      useAnimations: await readBool(
        StorageKeys.useAnimations,
        fallback: defaults.useAnimations,
      ),
      useLiquidGlass: await readBool(
        StorageKeys.useLiquidGlass,
        fallback: defaults.useLiquidGlass,
      ),
    );
    notifyListeners();
  }

  @override
  Future<void> save(AppSettings settings) async {
    final old = _settings;
    if (settings == old) return;
    _settings = settings;
    notifyListeners();

    Future<void> saveBool(String key, bool Function(AppSettings) field) async {
      if (field(settings) != field(old)) {
        await _storage.writeBool(key, value: field(settings));
      }
    }

    Future<void> saveInt(String key, int Function(AppSettings) field) async {
      if (field(settings) != field(old)) {
        await _storage.writeInt(key, field(settings));
      }
    }

    if (settings.locale != old.locale) {
      await _storage.write(StorageKeys.locale, settings.locale);
    }
    if (settings.market != old.market) {
      await _storage.write(StorageKeys.market, settings.market);
    }
    if (settings.lyricsTextAlign != old.lyricsTextAlign) {
      await _storage.write(
        StorageKeys.lyricsTextAlign,
        settings.lyricsTextAlign.toString(),
      );
    }
    if (settings.localsSort != old.localsSort) {
      await _storage.write(
        StorageKeys.localsSort,
        settings.localsSort.storageValue,
      );
    }
    if (settings.sleepAlarmDeviceVolume != old.sleepAlarmDeviceVolume) {
      await _storage.writeDouble(
        StorageKeys.sleepAlarmDeviceVolume,
        settings.sleepAlarmDeviceVolume,
      );
    }
    await saveBool(StorageKeys.syncDelay, (s) => s.useSyncTimeDelay);
    await saveBool(StorageKeys.useSyncedLyrics, (s) => s.useSyncedLyrics);
    await saveInt(StorageKeys.searchArtistCount, (s) => s.searchArtistCount);
    await saveInt(StorageKeys.searchAlbumCount, (s) => s.searchAlbumCount);
    await saveInt(StorageKeys.searchTrackCount, (s) => s.searchTrackCount);
    await saveInt(
      StorageKeys.searchPlaylistCount,
      (s) => s.searchPlaylistCount,
    );
    await saveBool(
      StorageKeys.useCacheAudioSource,
      (s) => s.useCacheAudioSource,
    );
    await saveBool(StorageKeys.enableLyrics, (s) => s.enableLyrics);
    await saveBool(StorageKeys.enableHistory, (s) => s.enableHistory);
    await saveBool(StorageKeys.enableCategories, (s) => s.enableCategories);
    await saveInt(StorageKeys.categoryCount, (s) => s.categoryCount);
    await saveBool(StorageKeys.cacheImages, (s) => s.cacheImages);
    await saveBool(StorageKeys.useBlur, (s) => s.useBlur);
    await saveBool(StorageKeys.useMix, (s) => s.useMix);
    await saveBool(
      StorageKeys.useDetailedBlurhash,
      (s) => s.useDetailedBlurhash,
    );
    await saveBool(StorageKeys.darkMode, (s) => s.darkMode);
    await saveBool(StorageKeys.linearSleepIn, (s) => s.linearSleepIn);
    await saveBool(StorageKeys.linearWakeUp, (s) => s.linearWakeUp);
    await saveBool(StorageKeys.dynamicBlurhash, (s) => s.useDynamicBlurhash);
    await saveBool(StorageKeys.useAnimations, (s) => s.useAnimations);
    await saveBool(StorageKeys.useLiquidGlass, (s) => s.useLiquidGlass);
  }

  TextAlign _textAlign(String? stored) => switch (stored) {
    null || 'TextAlign.left' => TextAlign.left,
    'TextAlign.right' => TextAlign.right,
    'TextAlign.justify' => TextAlign.justify,
    _ => TextAlign.center,
  };
}
