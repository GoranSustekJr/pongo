import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:sqflite/sqflite.dart';

import '../../../domain/models/library/sync_item.dart';

/// Reads the library in the database as sync items and writes synced items
/// back, and keeps track of what was synced in the `sync_state` and
/// `sync_meta` tables.
class SyncTable implements SyncSource, SyncStateStore {
  /// Creates a table backed by [_db].
  SyncTable(this._db);

  final Database _db;

  /// Covers larger than this stay on the device.
  static const maxCoverBytes = 1000000;

  static const _alarmColumns = [
    'sleep',
    'sleep_duration',
    'sleep_linear',
    'alarm_clock',
    'wake_time',
    'before_end_time_min',
    'alarm_clock_linear',
  ];
  static const _historyLimit = 500;

  /// Adds what syncing needs to the database.
  static Future<void> create(Database db) async {
    // Playlists and alarms have local IDs, so each gets an ID that's the same
    // on every device
    for (final table in ['online_playlist', 'local_playlist', 'sleep']) {
      await _addColumn(db, table, 'sync_id', 'TEXT');
    }
    for (final table in ['lfh_tracks', 'lfh_artists', 'search_history']) {
      await _addColumn(db, table, 'played_at', 'INTEGER');
      // Older entries keep their order, and stay older than any new one
      await db.execute(
        'UPDATE $table SET played_at = id WHERE played_at IS NULL',
      );
    }
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_state (
        kind TEXT NOT NULL,
        key TEXT NOT NULL,
        hash TEXT,
        changed_at INTEGER NOT NULL,
        dirty INTEGER NOT NULL,
        PRIMARY KEY (kind, key)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_meta (
        name TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
  }

  static Future<void> _addColumn(
    Database db,
    String table,
    String column,
    String type,
  ) async {
    final columns = await db.rawQuery('PRAGMA table_info($table)');
    if (columns.any((c) => c['name'] == column)) return;
    await db.execute('ALTER TABLE $table ADD COLUMN $column $type');
  }

  @override
  Set<String> get kinds => const {
    'favourite',
    'online_playlist',
    'local_playlist',
    'played_track',
    'played_artist',
    'search',
    'sleep_alarm',
    'lyrics_delay',
  };

  @override
  Future<Map<SyncKey, SyncItem>> snapshot() async {
    final items = <SyncKey, SyncItem>{};
    for (final kind in kinds) {
      for (final (key, item) in await _read(kind)) {
        items[(kind: kind, key: key)] = item;
      }
    }
    return items;
  }

  @override
  Future<SyncItem> item(SyncKey key) async {
    for (final (itemKey, item) in await _read(key.kind, key: key.key)) {
      if (itemKey == key.key) return item;
    }
    return (data: null, changedAt: 0);
  }

  Future<List<(String, SyncItem)>> _read(String kind, {String? key}) async {
    switch (kind) {
      case 'favourite':
        return [
          for (final row in await _rows('favourites', 'stid', key))
            if (row['stid'] case final String stid)
              (
                stid,
                (
                  data: {
                    'title': row['title'],
                    'artists': row['artists'],
                    'image': row['image'],
                    'album': row['album'],
                  },
                  changedAt: 0,
                ),
              ),
        ];
      case 'online_playlist':
        return [
          for (final row in await _rows('online_playlist', 'sync_id', key))
            (
              await _syncId('online_playlist', 'opid', row),
              (
                data: {
                  'title': row['title'],
                  ..._cover(row['cover']),
                  'tracks': [
                    for (final track in await _db.query(
                      'opid_stid',
                      where: 'opid = ?',
                      whereArgs: [row['opid']],
                      orderBy: 'order_number ASC',
                    ))
                      {
                        'stid': track['stid'],
                        'title': track['title'],
                        'artists': track['artists'],
                        'image': track['image'],
                        'album': track['album'],
                        'hidden': _isTrue(track['hidden']),
                      },
                  ],
                },
                changedAt: 0,
              ),
            ),
        ];
      case 'local_playlist':
        return [
          for (final row in await _rows('local_playlist', 'sync_id', key))
            (
              await _syncId('local_playlist', 'lpid', row),
              (
                data: {
                  'title': row['title'],
                  ..._cover(row['cover']),
                  'tracks': [
                    for (final track in await _db.query(
                      'lpid_track_id',
                      where: 'lpid = ?',
                      whereArgs: [row['lpid']],
                      orderBy: 'order_number ASC',
                    ))
                      {
                        'track_id': track['track_id'],
                        'hidden': _isTrue(track['hidden']),
                      },
                  ],
                },
                changedAt: 0,
              ),
            ),
        ];
      case 'played_track' || 'played_artist' || 'search':
        final (table, column) = _historyTable(kind);
        return [
          for (final row in await _rows(table, column, key))
            if (row[column] case final String id)
              (
                id,
                (
                  data: {'at': row['played_at']},
                  changedAt: row['played_at'] as int? ?? 0,
                ),
              ),
        ];
      case 'sleep_alarm':
        return [
          for (final row in await _rows('sleep', 'sync_id', key))
            (
              await _syncId('sleep', 'id', row),
              (data: {for (final c in _alarmColumns) c: row[c]}, changedAt: 0),
            ),
        ];
      case 'lyrics_delay':
        return [
          for (final row in await _rows('lyrics_sync_time_delay', 'stid', key))
            if (row['stid'] case final String stid)
              (stid, (data: {'ms': row['sync_time_delay']}, changedAt: 0)),
        ];
    }
    return const [];
  }

  Future<List<Map<String, Object?>>> _rows(
    String table,
    String keyColumn,
    String? key,
  ) => key == null
      ? _db.query(table)
      : _db.query(table, where: '$keyColumn = ?', whereArgs: [key]);

  /// The row's sync ID, giving it one first if it has none.
  Future<String> _syncId(
    String table,
    String idColumn,
    Map<String, Object?> row,
  ) async {
    if (row['sync_id'] case final String id) return id;
    final id = newSyncId();
    await _db.update(
      table,
      {'sync_id': id},
      where: '$idColumn = ?',
      whereArgs: [row[idColumn]],
    );
    return id;
  }

  /// A random ID, unique for all practical purposes.
  static String newSyncId() {
    final random = Random.secure();
    return [
      for (var i = 0; i < 16; i++)
        random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ].join();
  }

  static Map<String, Object?> _cover(Object? cover) => switch (cover) {
    null => {'cover': null},
    final Uint8List bytes when bytes.length <= maxCoverBytes => {
      'cover': base64Encode(bytes),
    },
    // Too large to sync: other devices keep whatever cover they have
    _ => const {},
  };

  static bool _isTrue(Object? value) => value == 1 || value == true;

  static (String, String) _historyTable(String kind) => switch (kind) {
    'played_track' => ('lfh_tracks', 'stid'),
    'played_artist' => ('lfh_artists', 'said'),
    _ => ('search_history', 'query'),
  };

  @override
  Future<void> apply(SyncKey key, Map<String, Object?>? data) =>
      _db.transaction((txn) => _apply(txn, key, data));

  Future<void> _apply(
    Transaction txn,
    SyncKey item,
    Map<String, Object?>? data,
  ) async {
    final key = item.key;
    switch (item.kind) {
      case 'favourite':
        final row = {
          'title': data?['title'],
          'artists': data?['artists'],
          'image': data?['image'],
          'album': data?['album'],
        };
        if (data == null) {
          await txn.delete('favourites', where: 'stid = ?', whereArgs: [key]);
        } else if (await txn.update(
              'favourites',
              row,
              where: 'stid = ?',
              whereArgs: [key],
            ) ==
            0) {
          await txn.insert('favourites', {'stid': key, ...row});
        }
      case 'online_playlist':
        await _applyPlaylist(
          txn,
          key,
          data,
          table: 'online_playlist',
          idColumn: 'opid',
          tracksTable: 'opid_stid',
          trackRow: (track) => {
            'stid': track['stid'],
            'title': track['title'],
            'artists': track['artists'],
            'image': track['image'],
            'album': track['album'],
          },
        );
      case 'local_playlist':
        await _applyPlaylist(
          txn,
          key,
          data,
          table: 'local_playlist',
          idColumn: 'lpid',
          tracksTable: 'lpid_track_id',
          trackRow: (track) => {'track_id': track['track_id']},
        );
      case 'played_track' || 'played_artist' || 'search':
        final (table, column) = _historyTable(item.kind);
        await txn.delete(table, where: '$column = ?', whereArgs: [key]);
        if (data?['at'] case final int at) {
          await txn.insert(table, {column: key, 'played_at': at});
          await txn.rawDelete('''
            DELETE FROM $table WHERE id NOT IN (
              SELECT id FROM $table ORDER BY played_at DESC, id DESC
              LIMIT $_historyLimit
            )
          ''');
        }
      case 'sleep_alarm':
        if (data == null) {
          await txn.delete('sleep', where: 'sync_id = ?', whereArgs: [key]);
          return;
        }
        final row = {for (final c in _alarmColumns) c: data[c]};
        if (await txn.update(
              'sleep',
              row,
              where: 'sync_id = ?',
              whereArgs: [key],
            ) ==
            0) {
          await txn.insert('sleep', {...row, 'sync_id': key});
        }
      case 'lyrics_delay':
        await txn.delete(
          'lyrics_sync_time_delay',
          where: 'stid = ?',
          whereArgs: [key],
        );
        if (data?['ms'] case final int ms) {
          await txn.insert('lyrics_sync_time_delay', {
            'stid': key,
            'sync_time_delay': ms,
          });
        }
    }
  }

  Future<void> _applyPlaylist(
    Transaction txn,
    String key,
    Map<String, Object?>? data, {
    required String table,
    required String idColumn,
    required String tracksTable,
    required Map<String, Object?> Function(Map<String, Object?> track) trackRow,
  }) async {
    final existing = await txn.query(
      table,
      columns: [idColumn],
      where: 'sync_id = ?',
      whereArgs: [key],
    );
    final id = existing.isEmpty ? null : existing.first[idColumn];
    if (id != null) {
      await txn.delete(tracksTable, where: '$idColumn = ?', whereArgs: [id]);
    }
    if (data == null) {
      if (id != null) {
        await txn.delete(table, where: '$idColumn = ?', whereArgs: [id]);
      }
      return;
    }

    final row = {
      'title': data['title'],
      // Without a cover in the data, the playlist keeps the one it has
      if (data.containsKey('cover'))
        'cover': switch (data['cover']) {
          final String encoded => base64Decode(encoded),
          _ => null,
        },
    };
    final playlistId = id == null
        ? await txn.insert(table, {...row, 'sync_id': key})
        : (
            await txn.update(
              table,
              row,
              where: '$idColumn = ?',
              whereArgs: [id],
            ),
            id,
          ).$2;
    final tracks = data['tracks'];
    if (tracks is! List) return;
    for (final (order, track) in tracks.indexed) {
      if (track is! Map<String, Object?>) continue;
      await txn.insert(tracksTable, {
        ...trackRow(track),
        idColumn: playlistId,
        'order_number': order,
        'hidden': _isTrue(track['hidden']) ? 1 : 0,
      });
    }
  }

  @override
  Future<Map<SyncKey, SyncState>> states() async => {
    for (final row in await _db.query('sync_state'))
      (kind: row['kind']! as String, key: row['key']! as String): (
        hash: row['hash'] as String?,
        changedAt: row['changed_at']! as int,
        dirty: row['dirty'] == 1,
      ),
  };

  @override
  Future<void> saveStates(Map<SyncKey, SyncState> states) async {
    final batch = _db.batch();
    for (final MapEntry(key: item, value: state) in states.entries) {
      batch.insert('sync_state', {
        'kind': item.kind,
        'key': item.key,
        'hash': state.hash,
        'changed_at': state.changedAt,
        'dirty': state.dirty ? 1 : 0,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<int?> cursor() async {
    final rows = await _db.query(
      'sync_meta',
      where: 'name = ?',
      whereArgs: ['cursor'],
    );
    return int.tryParse('${rows.firstOrNull?['value']}');
  }

  @override
  Future<void> setCursor(int cursor) => _db.insert('sync_meta', {
    'name': 'cursor',
    'value': '$cursor',
  }, conflictAlgorithm: ConflictAlgorithm.replace);

  @override
  Future<void> clear() async {
    await _db.delete('sync_state');
    await _db.delete('sync_meta');
  }

  @override
  Future<int> changeCount() async =>
      Sqflite.firstIntValue(await _db.rawQuery('SELECT total_changes()')) ?? 0;
}
