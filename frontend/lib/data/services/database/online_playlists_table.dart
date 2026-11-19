import 'dart:convert';
import 'dart:typed_data';

import 'package:sqflite/sqflite.dart';

import '../../../domain/models/playlists/online_playlist_track.dart';
import 'database_service.dart';

/// The `online_playlist` and `opid_stid` tables.
class OnlinePlaylistsTable {
  /// Creates a table backed by [_db].
  OnlinePlaylistsTable(this._db);

  final Database _db;

  /// Creates a playlist and returns its ID.
  Future<int> insert(String title, Uint8List? cover) =>
      _db.insert('online_playlist', {'title': title, 'cover': cover});

  /// Appends [track] to its playlist.
  ///
  /// Returns the new row ID, or `null` if the playlist already holds it.
  Future<int?> insertTrack(OnlinePlaylistTrack track) async {
    final existing = await _db.query(
      'opid_stid',
      where: 'opid = ? AND stid = ?',
      whereArgs: [track.opid, track.stid],
    );
    if (existing.isNotEmpty) return null;

    final result = await _db.rawQuery(
      'SELECT MAX(order_number) as max_order FROM opid_stid WHERE opid = ?',
      [track.opid],
    );
    final maxOrder = result.first['max_order'] as int? ?? -1;
    return _db.insert('opid_stid', {
      ..._row(track),
      'opid': track.opid,
      'order_number': maxOrder + 1,
    });
  }

  /// All playlists, newest first.
  Future<List<Map<String, dynamic>>> queryAll() =>
      _db.query('online_playlist', orderBy: 'opid DESC');

  /// The ID and title of every playlist, newest first.
  Future<List<Map<String, dynamic>>> queryTitles() => _db.rawQuery(
    'SELECT opid, title FROM online_playlist ORDER BY opid DESC',
  );

  /// The tracks in playlist [opid], in playlist order.
  Future<List<OnlinePlaylistTrack>> queryTracks(int opid) async {
    final rows = await _db.query(
      'opid_stid',
      where: 'opid = ?',
      whereArgs: [opid],
      orderBy: 'order_number ASC',
    );
    return rows.map(OnlinePlaylistTrack.fromMap).toList();
  }

  /// The number of playlists.
  Future<int> count() async =>
      Sqflite.firstIntValue(
        await _db.rawQuery('SELECT COUNT(*) FROM online_playlist'),
      ) ??
      0;

  /// The number of tracks explicitly shown in playlist [opid].
  Future<int> countShownTracks(int opid) async =>
      Sqflite.firstIntValue(
        await _db.rawQuery(
          'SELECT COUNT(*) FROM opid_stid WHERE opid = ? AND hidden = false',
          [opid],
        ),
      ) ??
      0;

  /// Rewrites playlist [opid] to hold [tracks] in this order.
  Future<void> updateOrder(int opid, List<OnlinePlaylistTrack> tracks) =>
      _db.transaction((txn) async {
        await txn.delete('opid_stid', where: 'opid = ?', whereArgs: [opid]);
        for (var i = 0; i < tracks.length; i++) {
          await txn.insert('opid_stid', {
            ..._row(tracks[i]),
            'opid': opid,
            'order_number': i + 1,
          });
        }
      });

  /// Renames playlist [opid].
  Future<void> updateTitle(int opid, String title) => _db.update(
    'online_playlist',
    {'title': title},
    where: 'opid = ?',
    whereArgs: [opid],
  );

  /// Replaces the cover of playlist [opid].
  Future<void> updateCover(int opid, Uint8List cover) => _db.update(
    'online_playlist',
    {'cover': cover},
    where: 'opid = ?',
    whereArgs: [opid],
  );

  /// Shows or hides the tracks with [stids] in playlist [opid].
  Future<void> updateHidden(
    int opid,
    List<String> stids, {
    required bool hidden,
  }) => _db.rawUpdate(
    'UPDATE opid_stid SET hidden = ? '
    'WHERE opid = ? AND stid IN (${placeholders(stids.length)})',
    [if (hidden) 1 else 0, opid, ...stids],
  );

  /// Removes the tracks with [stids] from playlist [opid].
  Future<void> removeTracks(int opid, List<String> stids) => _db.delete(
    'opid_stid',
    where: 'opid = ? AND stid IN (${placeholders(stids.length)})',
    whereArgs: [opid, ...stids],
  );

  /// Deletes playlist [opid] and its entries.
  Future<void> remove(int opid) => _db.transaction((txn) async {
    await txn.delete('opid_stid', where: 'opid = ?', whereArgs: [opid]);
    await txn.delete('online_playlist', where: 'opid = ?', whereArgs: [opid]);
  });

  Map<String, dynamic> _row(OnlinePlaylistTrack track) => {
    'stid': track.stid,
    'title': track.title,
    'artists': jsonEncode(track.artistTrack),
    'image': track.image,
    'album': track.albumTrack == null
        ? null
        : jsonEncode(track.albumTrack!.toJson()),
    'hidden': track.hidden ? 1 : 0,
  };
}
