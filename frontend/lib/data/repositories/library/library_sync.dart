import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../../../domain/models/library/sync_item.dart';
import '../../../utils/result.dart';
import '../../services/api/api_client.dart';

/// Keeps the library the same on all of the user's devices.
///
/// A sync compares the library with what was last synced, sends the server
/// the items that changed, and stores the items that changed on the server
/// since the last sync. The latest change to an item wins. Listeners are told
/// when a sync changed the library.
class LibrarySync extends ChangeNotifier {
  /// Creates a sync of the items in [sources] that keeps its state in
  /// [_store] and talks to the server with [_apiClient].
  LibrarySync({
    required this._apiClient,
    required this._store,
    required List<SyncSource> sources,
    DateTime Function()? now,
  }) : _sources = {
         for (final source in sources)
           for (final kind in source.kinds) kind: source,
       },
       _now = now ?? DateTime.now;

  final ApiClient _apiClient;
  final SyncStateStore _store;
  final Map<String, SyncSource> _sources;
  final DateTime Function() _now;

  /// How often the library is checked for changes to send.
  static const checkEvery = Duration(seconds: 30);

  /// How often the server is asked for changes when the library didn't
  /// change, and how often a failed sync is retried.
  static const pullEvery = Duration(minutes: 5);

  // What the server takes in one request
  static const _maxChanges = 500;
  static const _maxRequestBytes = 6000000;
  static const _maxItemBytes = 1900000;
  static const _maxKeyLength = 200;
  static const _maxRequests = 1000;

  Timer? _timer;
  Future<void>? _running;
  var _again = false;
  int? _checkedChanges;
  DateTime? _lastAttempt;

  /// Syncs now and then whenever the library changes, until [stop].
  Future<void> start() {
    _timer ??= Timer.periodic(checkEvery, (_) => unawaited(_check()));
    return sync();
  }

  /// Stops syncing.
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Stops syncing and forgets what was synced, for when the user signs out.
  Future<void> reset() async {
    stop();
    await _running;
    await _store.clear();
    _checkedChanges = null;
    _lastAttempt = null;
  }

  /// Syncs once, if started. If a sync is running, syncs again after it.
  Future<void> sync() {
    if (_timer == null) return Future.value();
    if (_running case final running?) {
      _again = true;
      return running;
    }
    return _running = _syncWhileAsked().whenComplete(() => _running = null);
  }

  Future<void> _check() async {
    final last = _lastAttempt;
    if (last == null ||
        _now().difference(last) >= pullEvery ||
        await _store.changeCount() != _checkedChanges) {
      await sync();
    }
  }

  Future<void> _syncWhileAsked() async {
    do {
      _again = false;
      _lastAttempt = _now();
      final changesBefore = await _store.changeCount();
      try {
        final synced = await _syncOnce();
        // Changes while syncing, including the sync's own, are checked again;
        // after a failure only new changes are, so it isn't retried at once
        _checkedChanges = synced ? changesBefore : await _store.changeCount();
      } on Object catch (e) {
        debugPrint('LibrarySync failed: $e');
        _checkedChanges = await _store.changeCount();
      }
    } while (_again && _timer != null);
  }

  /// Returns whether the server got every change.
  Future<bool> _syncOnce() async {
    final cursor = await _store.cursor();
    final local = <SyncKey, SyncItem>{};
    for (final source in _sources.values.toSet()) {
      local.addAll(await source.snapshot());
    }
    final hashes = {
      for (final MapEntry(:key, value: item) in local.entries)
        key: _hash(item.data),
    };
    final states = await _store.states();
    final now = _now().millisecondsSinceEpoch;

    // The changes the server still has to get
    final pending = <SyncKey, SyncItem>{};
    for (final MapEntry(:key, value: item) in local.entries) {
      final state = states[key];
      if (state != null && state.hash == hashes[key]) {
        if (state.dirty) {
          pending[key] = (data: item.data, changedAt: state.changedAt);
        }
        continue;
      }
      // The server would refuse these, and with them the rest of the request
      if (key.key.isEmpty ||
          key.key.length > _maxKeyLength ||
          jsonEncode(item.data).length > _maxItemBytes) {
        continue;
      }
      // Before the first sync it's unknown when items changed, so the
      // server's versions win
      final since = item.changedAt > 0
          ? item.changedAt
          : cursor == null && state == null
          ? 1
          : now;
      pending[key] = (
        data: item.data,
        changedAt: max(since, (state?.changedAt ?? 0) + 1),
      );
    }
    for (final MapEntry(:key, value: state) in states.entries) {
      if (local.containsKey(key) || !_sources.containsKey(key.kind)) continue;
      if (state.hash != null) {
        pending[key] = (data: null, changedAt: max(now, state.changedAt + 1));
      } else if (state.dirty) {
        pending[key] = (data: null, changedAt: state.changedAt);
      }
    }
    // Stored first, so a change is sent again if this sync fails
    if (pending.isNotEmpty) {
      await _store.saveStates({
        for (final MapEntry(:key, value: item) in pending.entries)
          key: (hash: _hash(item.data), changedAt: item.changedAt, dirty: true),
      });
    }

    final requests = _requests(pending);
    var at = cursor ?? 0;
    var more = true;
    var changed = false;
    for (var sent = 0; sent < requests.length || more; sent++) {
      if (sent == _maxRequests) return false;
      final result = await _apiClient.post('sync', {
        'cursor': at,
        'changes': sent < requests.length ? requests[sent] : const [],
      });
      final Map<String, dynamic> response;
      switch (result) {
        case Ok(:final value):
          response = value;
        case Error():
          return false;
      }

      final synced = <SyncKey, SyncState>{};
      final changes = switch (response['changes']) {
        final List<Object?> changes => changes,
        _ => const <Object?>[],
      };
      for (final change in changes) {
        if (change
            case {
              'kind': final String kind,
              'key': final String key,
              'changed_at': final int changedAt,
            }
            when _sources.containsKey(kind)) {
          final item = (kind: kind, key: key);
          final data = switch (change['data']) {
            final Map<String, dynamic> data => data,
            _ => null,
          };
          final stored = await _receive(
            item,
            data,
            changedAt,
            snapshotHash: hashes[item],
            mine: pending[item],
          );
          if (stored == null) continue;
          if (stored.changed) changed = true;
          hashes[item] = stored.state.hash;
          synced[item] = stored.state;
        }
      }
      if (synced.isNotEmpty) await _store.saveStates(synced);
      more = response['more'] == true;
      if (response['cursor'] case final int next when next != at) {
        at = next;
        await _store.setCursor(at);
      } else if (cursor == null && sent == 0) {
        await _store.setCursor(at);
      }
    }
    if (changed) notifyListeners();
    return true;
  }

  /// Stores [data] from the server as [item], unless the device has a newer
  /// change to it, and returns what's synced of the item and whether it
  /// changed; returns `null` if the device's change is newer.
  Future<({SyncState state, bool changed})?> _receive(
    SyncKey item,
    Map<String, Object?>? data,
    int changedAt, {
    required String? snapshotHash,
    required SyncItem? mine,
  }) async {
    final source = _sources[item.kind]!;
    final current = _hash((await source.item(item)).data);
    final hash = _hash(data);
    // The device has it already, such as its own change coming back
    if (current == hash) {
      return (
        state: (hash: hash, changedAt: changedAt, dirty: false),
        changed: false,
      );
    }
    // Changed while syncing: the next sync sends it as the latest change
    if (current != snapshotHash) {
      return (
        state: (hash: hash, changedAt: changedAt, dirty: false),
        changed: false,
      );
    }
    if (mine != null && mine.changedAt > changedAt) return null;

    await source.apply(item, data);
    // Stored as the device stores it, which can differ from the data, such
    // as a playlist keeping its own cover when the data has none
    return (
      state: (
        hash: _hash((await source.item(item)).data),
        changedAt: changedAt,
        dirty: false,
      ),
      changed: true,
    );
  }

  /// [pending] as the changes of each request.
  List<List<Map<String, Object?>>> _requests(Map<SyncKey, SyncItem> pending) {
    final requests = <List<Map<String, Object?>>>[];
    var current = <Map<String, Object?>>[];
    var bytes = 0;
    for (final MapEntry(:key, value: item) in pending.entries) {
      final change = {
        'kind': key.kind,
        'key': key.key,
        'data': item.data,
        'changed_at': item.changedAt,
      };
      final size = jsonEncode(change).length;
      if (current.length == _maxChanges ||
          (current.isNotEmpty && bytes + size > _maxRequestBytes)) {
        requests.add(current);
        current = [];
        bytes = 0;
      }
      current.add(change);
      bytes += size;
    }
    if (current.isNotEmpty) requests.add(current);
    return requests;
  }

  /// A hash of [data] that's the same however its keys are ordered.
  static String? _hash(Map<String, Object?>? data) => data == null
      ? null
      : sha1.convert(utf8.encode(jsonEncode(_sorted(data)))).toString();

  static Object? _sorted(Object? value) => switch (value) {
    final Map<Object?, Object?> map => {
      for (final key in map.keys.map((k) => '$k').toList()..sort())
        key: _sorted(map[key]),
    },
    final List<Object?> list => [for (final item in list) _sorted(item)],
    _ => value,
  };
}
