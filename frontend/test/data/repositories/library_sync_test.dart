import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pongo/data/repositories/library/library_sync.dart';
import 'package:pongo/data/repositories/settings/settings_repository.dart';
import 'package:pongo/data/repositories/settings/settings_sync_source.dart';
import 'package:pongo/data/services/api/api_client.dart';
import 'package:pongo/domain/models/library/sync_item.dart';
import 'package:pongo/domain/models/settings/app_settings.dart';
import 'package:pongo/utils/result.dart';

typedef _Stored = ({Object? data, int changedAt, int seq});

/// Keeps items the way the server's /sync does.
class _Server extends Fake implements ApiClient {
  final items = <(String, String), _Stored>{};
  final requestSizes = <int>[];
  var _seq = 0;
  bool offline = false;
  void Function()? onRequest;

  @override
  Future<Result<Map<String, dynamic>>> post(
    String path,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    onRequest?.call();
    if (offline) return Result.error(Exception('offline'));
    final request = jsonDecode(jsonEncode(body)) as Map<String, dynamic>;
    final changes = request['changes'] as List;
    requestSizes.add(changes.length);

    final lost = <(String, String)>[];
    for (final change in changes.cast<Map<String, dynamic>>()) {
      final key = (change['kind'] as String, change['key'] as String);
      final changedAt = change['changed_at'] as int;
      if ((items[key]?.changedAt ?? -1) < changedAt) {
        items[key] = (data: change['data'], changedAt: changedAt, seq: ++_seq);
      } else {
        lost.add(key);
      }
    }
    final cursor = request['cursor'] as int;
    final rows = items.entries.where((e) => e.value.seq > cursor).toList()
      ..sort((a, b) => a.value.seq.compareTo(b.value.seq));
    final page = rows.take(500).toList();
    final pulled = {for (final row in page) row.key};
    final winners = <MapEntry<(String, String), _Stored>>[
      for (final key in lost)
        if (!pulled.contains(key)) MapEntry(key, items[key]!),
    ];
    return Result.ok({
      'changes': [
        for (final MapEntry<(String, String), _Stored>(key: (kind, key), :value)
            in [...page, ...winners])
          {
            'kind': kind,
            'key': key,
            'data': value.data,
            'changed_at': value.changedAt,
          },
      ],
      'cursor': page.isEmpty ? cursor : page.last.value.seq,
      'more': rows.length > 500,
    });
  }
}

class _Source implements SyncSource {
  final items = <SyncKey, Map<String, Object?>>{};

  @override
  Set<String> get kinds => const {'favourite', 'online_playlist'};

  @override
  Future<Map<SyncKey, SyncItem>> snapshot() async => {
    for (final MapEntry(:key, :value) in items.entries)
      key: (data: value, changedAt: 0),
  };

  @override
  Future<SyncItem> item(SyncKey key) async => (data: items[key], changedAt: 0);

  @override
  Future<void> apply(SyncKey key, Map<String, Object?>? data) async =>
      data == null ? items.remove(key) : items[key] = data;
}

class _Store implements SyncStateStore {
  int? _cursor;
  final _states = <SyncKey, SyncState>{};
  var _changes = 0;

  @override
  Future<int?> cursor() async => _cursor;

  @override
  Future<void> setCursor(int cursor) async {
    _cursor = cursor;
    _changes++;
  }

  @override
  Future<Map<SyncKey, SyncState>> states() async => Map.of(_states);

  @override
  Future<void> saveStates(Map<SyncKey, SyncState> states) async {
    _states.addAll(states);
    _changes++;
  }

  @override
  Future<void> clear() async {
    _cursor = null;
    _states.clear();
  }

  @override
  Future<int> changeCount() async => _changes;
}

DateTime _clock = DateTime(2026, 11, 19);

class _Device {
  _Device(_Server server) {
    sync = LibrarySync(
      apiClient: server,
      store: _Store(),
      sources: [library],
      now: () => _clock,
    )..addListener(() => notified++);
    addTearDown(sync.stop);
  }

  final library = _Source();
  late final LibrarySync sync;
  int notified = 0;

  Map<SyncKey, Map<String, Object?>> get items => library.items;

  /// Syncs a second later than anything before.
  Future<void> syncNow() {
    _clock = _clock.add(const Duration(seconds: 1));
    return sync.start();
  }
}

const _song = (kind: 'favourite', key: '111');
const _playlist = (kind: 'online_playlist', key: 'abc');

void main() {
  late _Server server;
  late _Device phone;
  late _Device tablet;

  setUp(() {
    server = _Server();
    phone = _Device(server);
    tablet = _Device(server);
  });

  test('a new favourite reaches the other device', () async {
    phone.items[_song] = {'title': 'Song'};
    await phone.syncNow();
    await tablet.syncNow();

    expect(tablet.items[_song], {'title': 'Song'});
    expect(tablet.notified, 1);
    // Its own change coming back isn't news to the phone
    expect(phone.notified, 0);
  });

  test('a deletion reaches the other device', () async {
    phone.items[_song] = {'title': 'Song'};
    await phone.syncNow();
    await tablet.syncNow();

    tablet.items.remove(_song);
    await tablet.syncNow();
    await phone.syncNow();

    expect(phone.items, isEmpty);
  });

  test('the latest edit wins on both devices', () async {
    phone.items[_playlist] = {'title': 'Road trip'};
    await phone.syncNow();
    await tablet.syncNow();

    // The phone notices its edit while offline, so it's dated then
    server.offline = true;
    phone.items[_playlist] = {'title': 'Phone name'};
    await phone.syncNow();
    server.offline = false;
    tablet.items[_playlist] = {'title': 'Tablet name'};
    await tablet.syncNow();
    // The tablet's edit is later, though the phone sends its own last
    await phone.syncNow();
    await tablet.syncNow();

    expect(phone.items[_playlist], {'title': 'Tablet name'});
    expect(tablet.items[_playlist], {'title': 'Tablet name'});
  });

  test('an edit after seeing the other device\'s edit wins', () async {
    phone.items[_playlist] = {'title': 'One'};
    await phone.syncNow();
    await tablet.syncNow();
    tablet.items[_playlist] = {'title': 'Two'};
    await tablet.syncNow();
    await phone.syncNow();

    phone.items[_playlist] = {'title': 'Three'};
    await phone.syncNow();
    await tablet.syncNow();

    expect(tablet.items[_playlist], {'title': 'Three'});
  });

  test('a change made while syncing is kept and sent next time', () async {
    phone.items[_playlist] = {'title': 'One'};
    await phone.syncNow();
    await tablet.syncNow();
    tablet.items[_playlist] = {'title': 'From tablet'};
    await tablet.syncNow();

    server.onRequest = () => phone.items[_playlist] = {'title': 'Just now'};
    await phone.syncNow();
    server.onRequest = null;
    expect(phone.items[_playlist], {'title': 'Just now'});

    await phone.syncNow();
    await tablet.syncNow();
    expect(tablet.items[_playlist], {'title': 'Just now'});
  });

  test('a change made offline is sent once the server is reachable', () async {
    server.offline = true;
    phone.items[_song] = {'title': 'Song'};
    await phone.syncNow();
    server.offline = false;
    await tablet.syncNow();
    expect(tablet.items, isEmpty);

    await phone.syncNow();
    await tablet.syncNow();
    expect(tablet.items[_song], {'title': 'Song'});
  });

  test('on its first sync a device takes the account\'s versions and adds '
      'what only it has', () async {
    phone.items[_song] = {'title': 'Song'};
    phone.items[_playlist] = {'title': 'Phone name'};
    await phone.syncNow();
    phone.items.remove(_song);
    await phone.syncNow();

    // The tablet had the library before it ever synced
    tablet.items[_song] = {'title': 'Song'};
    tablet.items[_playlist] = {'title': 'Old tablet name'};
    const onlyTablet = (kind: 'favourite', key: '222');
    tablet.items[onlyTablet] = {'title': 'Other'};
    await tablet.syncNow();
    await phone.syncNow();

    expect(tablet.items, {
      _playlist: {'title': 'Phone name'},
      onlyTablet: {'title': 'Other'},
    });
    expect(phone.items, tablet.items);
  });

  test('a large library goes in requests the server takes', () async {
    for (var i = 0; i < 1200; i++) {
      phone.items[(kind: 'favourite', key: '$i')] = {'title': 'Song $i'};
    }
    await phone.syncNow();
    await tablet.syncNow();

    expect(server.requestSizes.every((size) => size <= 500), isTrue);
    expect(tablet.items.length, 1200);
  });

  test('after signing out a device syncs as if for the first time', () async {
    phone.items[_song] = {'title': 'Song'};
    await phone.syncNow();
    await phone.sync.reset();

    await phone.sync.sync();
    expect(server.requestSizes, [1], reason: 'stopped syncing');

    await phone.syncNow();
    expect(phone.items[_song], {'title': 'Song'});
  });

  group('settings', () {
    test('only settings that suit every device are synced', () async {
      final settings = _Settings();
      final items = await SettingsSyncSource(settings).snapshot();
      final names = {for (final key in items.keys) key.key};

      expect(names, containsAll(['darkMode', 'locale', 'useMix']));
      expect(names, isNot(contains('useBlur')));
      expect(names, isNot(contains('sleepAlarmDeviceVolume')));
    });

    test('a synced setting is saved, and a bad value ignored', () async {
      final settings = _Settings();
      final source = SettingsSyncSource(settings);

      await source.apply((kind: 'setting', key: 'darkMode'), {'v': false});
      await source.apply((kind: 'setting', key: 'locale'), {'v': 7});
      await source.apply(
        (kind: 'setting', key: 'lyricsTextAlign'),
        {'v': 'right'},
      );

      expect(settings.settings.darkMode, isFalse);
      expect(settings.settings.locale, const AppSettings().locale);
      expect(
        (await source.item((kind: 'setting', key: 'lyricsTextAlign'))).data,
        {'v': 'right'},
      );
    });
  });
}

class _Settings extends SettingsRepository {
  AppSettings _settings = const AppSettings(darkMode: true);

  @override
  AppSettings get settings => _settings;

  @override
  Future<void> load() async {}

  @override
  Future<void> save(AppSettings settings) async => _settings = settings;
}
