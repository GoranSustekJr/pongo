import 'package:flutter/painting.dart';

import '../../../domain/models/library/sync_item.dart';
import '../../../domain/models/settings/app_settings.dart';
import 'settings_repository.dart';

typedef _Field = ({
  Object? Function(AppSettings settings) read,
  AppSettings? Function(AppSettings settings, Object? value) write,
});

/// The settings that are the same on all of the user's devices, as sync
/// items, one per setting.
///
/// Settings that depend on the device, such as how much it can animate or
/// cache and the alarm volume, aren't synced.
class SettingsSyncSource implements SyncSource {
  /// Creates a source for the settings in [_settings].
  SettingsSyncSource(this._settings);

  final SettingsRepository _settings;

  static const _kind = 'setting';

  static final Map<String, _Field> _fields = {
    'locale': _string((s) => s.locale, (s, v) => s.copyWith(locale: v)),
    'market': _string((s) => s.market, (s, v) => s.copyWith(market: v)),
    'useSyncTimeDelay': _bool(
      (s) => s.useSyncTimeDelay,
      (s, {required value}) => s.copyWith(useSyncTimeDelay: value),
    ),
    'useSyncedLyrics': _bool(
      (s) => s.useSyncedLyrics,
      (s, {required value}) => s.copyWith(useSyncedLyrics: value),
    ),
    'searchArtistCount': _int(
      (s) => s.searchArtistCount,
      (s, v) => s.copyWith(searchArtistCount: v),
    ),
    'searchAlbumCount': _int(
      (s) => s.searchAlbumCount,
      (s, v) => s.copyWith(searchAlbumCount: v),
    ),
    'searchTrackCount': _int(
      (s) => s.searchTrackCount,
      (s, v) => s.copyWith(searchTrackCount: v),
    ),
    'searchPlaylistCount': _int(
      (s) => s.searchPlaylistCount,
      (s, v) => s.copyWith(searchPlaylistCount: v),
    ),
    'lyricsTextAlign': (
      read: (s) => s.lyricsTextAlign.name,
      write: (s, v) => switch (TextAlign.values.asNameMap()[v]) {
        final align? => s.copyWith(lyricsTextAlign: align),
        null => null,
      },
    ),
    'enableLyrics': _bool(
      (s) => s.enableLyrics,
      (s, {required value}) => s.copyWith(enableLyrics: value),
    ),
    'enableHistory': _bool(
      (s) => s.enableHistory,
      (s, {required value}) => s.copyWith(enableHistory: value),
    ),
    'enableCategories': _bool(
      (s) => s.enableCategories,
      (s, {required value}) => s.copyWith(enableCategories: value),
    ),
    'categoryCount': _int(
      (s) => s.categoryCount,
      (s, v) => s.copyWith(categoryCount: v),
    ),
    'localsSort': _string(
      (s) => s.localsSort.storageValue,
      (s, v) => s.copyWith(localsSort: LocalsSort.fromStorage(v)),
    ),
    'useMix': _bool(
      (s) => s.useMix,
      (s, {required value}) => s.copyWith(useMix: value),
    ),
    'darkMode': _bool(
      (s) => s.darkMode,
      (s, {required value}) => s.copyWith(darkMode: value),
    ),
    'linearSleepIn': _bool(
      (s) => s.linearSleepIn,
      (s, {required value}) => s.copyWith(linearSleepIn: value),
    ),
    'linearWakeUp': _bool(
      (s) => s.linearWakeUp,
      (s, {required value}) => s.copyWith(linearWakeUp: value),
    ),
  };

  static _Field _bool(
    bool Function(AppSettings) read,
    AppSettings Function(AppSettings, {required bool value}) write,
  ) => (read: read, write: (s, v) => v is bool ? write(s, value: v) : null);

  static _Field _int(
    int Function(AppSettings) read,
    AppSettings Function(AppSettings, int) write,
  ) => (read: read, write: (s, v) => v is int ? write(s, v) : null);

  static _Field _string(
    String Function(AppSettings) read,
    AppSettings Function(AppSettings, String) write,
  ) => (read: read, write: (s, v) => v is String ? write(s, v) : null);

  @override
  Set<String> get kinds => const {_kind};

  @override
  Future<Map<SyncKey, SyncItem>> snapshot() async => {
    for (final MapEntry(key: name, value: field) in _fields.entries)
      (kind: _kind, key: name): (
        data: {'v': field.read(_settings.settings)},
        changedAt: 0,
      ),
  };

  @override
  Future<SyncItem> item(SyncKey key) async => (
    data: switch (_fields[key.key]) {
      final field? => {'v': field.read(_settings.settings)},
      null => null,
    },
    changedAt: 0,
  );

  @override
  Future<void> apply(SyncKey key, Map<String, Object?>? data) async {
    // A setting always has a value, so it can't be deleted
    final field = _fields[key.key];
    if (field == null || data == null) return;
    await _settings.update(
      (current) => field.write(current, data['v']) ?? current,
    );
  }
}
