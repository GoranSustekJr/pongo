import 'package:flutter/painting.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_settings.freezed.dart';

/// How downloaded tracks are sorted.
enum LocalsSort {
  /// By title, ascending.
  titleAscending('A-Z'),

  /// By title, descending.
  titleDescending('Z-A'),

  /// Oldest download first.
  firstAdded('First added'),

  /// Newest download first.
  lastAdded('Last added');

  const LocalsSort(this.storageValue);

  /// The value kept in storage.
  final String storageValue;

  /// The sort stored as [value], defaulting to the newest first like before.
  static LocalsSort fromStorage(String value) => values.firstWhere(
    (sort) => sort.storageValue == value,
    orElse: () => lastAdded,
  );
}

/// The user's preferences.
@freezed
abstract class AppSettings with _$AppSettings {
  /// Creates settings, with the defaults of a fresh install.
  const factory AppSettings({
    @Default('en') String locale,
    @Default('US') String market,
    @Default(false) bool useSyncTimeDelay,
    @Default(true) bool useSyncedLyrics,
    @Default(1) int searchArtistCount,
    @Default(1) int searchAlbumCount,
    @Default(50) int searchTrackCount,
    @Default(20) int searchPlaylistCount,
    @Default(TextAlign.left) TextAlign lyricsTextAlign,
    @Default(false) bool useCacheAudioSource,
    // Experimental: plays tracks the server is still downloading
    @Default(false) bool streamWhileDownloading,
    @Default(true) bool enableLyrics,
    @Default(true) bool enableHistory,
    @Default(true) bool enableCategories,
    @Default(50) int categoryCount,
    @Default(false) bool cacheImages,
    @Default(LocalsSort.titleAscending) LocalsSort localsSort,
    @Default(true) bool useBlur,
    @Default(true) bool useMix,
    @Default(true) bool useDetailedBlurhash,
    @Default(0) double sleepAlarmDeviceVolume,
    @Default(true) bool darkMode,
    @Default(true) bool linearSleepIn,
    @Default(true) bool linearWakeUp,
    @Default(false) bool useDynamicBlurhash,
    @Default(true) bool useAnimations,
    @Default(true) bool useLiquidGlass,
  }) = _AppSettings;
}
