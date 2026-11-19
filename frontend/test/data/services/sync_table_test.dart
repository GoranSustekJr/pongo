import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pongo/data/services/database/database_service.dart';
import 'package:pongo/data/services/database/sync_table.dart';
import 'package:pongo/domain/models/catalog/track.dart';
import 'package:pongo/domain/models/library/favourite.dart';
import 'package:pongo/domain/models/playlists/online_playlist_track.dart';
import 'package:pongo/domain/models/sleep_alarm/sleep_alarm.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory folder;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    folder = await Directory.systemTemp.createTemp('pongo_sync');
  });

  tearDown(() => folder.delete(recursive: true));

  Future<DatabaseService> openDevice(String name) async {
    final database = DatabaseService(fileName: '${folder.path}/$name.db');
    await database.open();
    return database;
  }

  Future<void> fillLibrary(DatabaseService db) async {
    const artists = [ArtistTrack(id: '1', name: 'Artist')];
    await db.favourites.insert(
      const Favourite(
        id: 0,
        stid: '111',
        title: 'Song',
        artistTrack: artists,
        albumTrack: null,
        image: 'https://img/1',
      ),
    );
    final opid = await db.onlinePlaylists.insert(
      'Road trip',
      Uint8List.fromList([1, 2, 3]),
    );
    for (final (i, stid) in ['222', '333'].indexed) {
      await db.onlinePlaylists.insertTrack(
        OnlinePlaylistTrack(
          opid: opid,
          stid: stid,
          title: 'Track $stid',
          artistTrack: artists,
          albumTrack: null,
          image: null,
          orderNumber: i,
          hidden: false,
        ),
      );
    }
    await db.onlinePlaylists.updateHidden(opid, ['333'], hidden: true);
    final lpid = await db.localPlaylists.insert('Offline', null);
    await db.localPlaylists.insertTrack(lpid, '444');
    await db.playHistory.insertTrack('555');
    await db.playHistory.insertArtist('666');
    await db.searchHistory.insert('daft punk');
    await db.sleepAlarms.insert(const SleepAlarm(id: 0, sleepDuration: 45));
    await db.lyricsSyncDelays.upsert('111', 250);
  }

  test('every kind of item reads back the same on another device', () async {
    final phone = await openDevice('phone');
    final tablet = await openDevice('tablet');
    await fillLibrary(phone);

    final items = await phone.sync.snapshot();
    expect({for (final key in items.keys) key.kind}, phone.sync.kinds);
    for (final MapEntry(:key, :value) in items.entries) {
      await tablet.sync.apply(key, value.data);
    }

    final copied = await tablet.sync.snapshot();
    expect(
      {for (final e in copied.entries) e.key: e.value.data},
      {for (final e in items.entries) e.key: e.value.data},
    );
    // And the app's own tables see them
    expect((await tablet.favourites.queryAll()).single.title, 'Song');
    final opid = (await tablet.onlinePlaylists.queryAll()).single['opid']!;
    final tracks = await tablet.onlinePlaylists.queryTracks(opid as int);
    expect(
      [for (final t in tracks) (t.stid, t.hidden)],
      [('222', false), ('333', true)],
    );
    expect(await tablet.playHistory.queryTracks(), ['555']);
    expect(await tablet.searchHistory.queryAll(), ['daft punk']);
    expect((await tablet.sleepAlarms.queryAll()).single.sleepDuration, 45);
    expect(await tablet.lyricsSyncDelays.query('111'), 250);
  });

  test('a playlist is deleted with its tracks', () async {
    final phone = await openDevice('phone');
    await fillLibrary(phone);
    final playlist = (await phone.sync.snapshot()).keys.firstWhere(
      (key) => key.kind == 'online_playlist',
    );

    await phone.sync.apply(playlist, null);

    expect(await phone.onlinePlaylists.queryAll(), isEmpty);
    expect(await phone.onlinePlaylists.queryTracks(1), isEmpty);
  });

  test('a cover too large to sync stays on its device', () async {
    final phone = await openDevice('phone');
    final big = Uint8List(SyncTable.maxCoverBytes + 1);
    await phone.onlinePlaylists.insert('Big cover', big);
    final (key, item) = (await phone.sync.snapshot()).entries
        .map((e) => (e.key, e.value))
        .single;
    expect(item.data!.containsKey('cover'), isFalse);

    // Another device renaming it leaves the cover alone
    await phone.sync.apply(key, {...item.data!, 'title': 'Renamed'});
    final row = (await phone.onlinePlaylists.queryAll()).single;
    expect(row['title'], 'Renamed');
    expect((row['cover']! as Uint8List).length, big.length);
  });

  test('upgrading keeps the order of the history', () async {
    final path = '${folder.path}/old.db';
    // The tables syncing changes, as version 40 had them
    final old = await openDatabase(
      path,
      version: 40,
      onCreate: (db, _) async {
        for (final (table, column) in [
          ('lfh_tracks', 'stid'),
          ('lfh_artists', 'said'),
          ('search_history', 'query'),
        ]) {
          await db.execute(
            'CREATE TABLE $table (id INTEGER PRIMARY KEY AUTOINCREMENT, '
            '$column TEXT)',
          );
        }
        for (final table in ['online_playlist', 'local_playlist', 'sleep']) {
          await db.execute('CREATE TABLE $table (id INTEGER)');
        }
      },
    );
    for (final stid in ['old', 'older']) {
      await old.insert('lfh_tracks', {'stid': stid});
    }
    await old.close();

    final upgraded = DatabaseService(fileName: path);
    await upgraded.open();
    await upgraded.playHistory.insertTrack('new');
    expect(await upgraded.playHistory.queryTracks(), ['new', 'older', 'old']);
  });
}
