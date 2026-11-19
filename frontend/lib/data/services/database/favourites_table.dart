import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../../domain/models/library/favourite.dart';
import 'database_service.dart';

/// The `favourites` table.
class FavouritesTable {
  /// Creates a table backed by [_db].
  FavouritesTable(this._db);

  final Database _db;

  /// Inserts [favourite] unless its track is already a favourite.
  Future<void> insert(Favourite favourite) async {
    if (await contains(favourite.stid)) return;
    await _db.insert('favourites', {
      'stid': favourite.stid,
      'title': favourite.title,
      'artists': jsonEncode(favourite.artistTrack),
      'image': favourite.image,
      'album': favourite.albumTrack == null
          ? null
          : jsonEncode(favourite.albumTrack!.toJson()),
    });
  }

  /// All favourites, most recently added first.
  Future<List<Favourite>> queryAll() async {
    final rows = await _db.rawQuery(
      'SELECT * FROM favourites ORDER BY id DESC',
    );
    return rows.map(Favourite.fromMap).toList();
  }

  /// The number of favourites.
  Future<int> count() async =>
      Sqflite.firstIntValue(
        await _db.rawQuery('SELECT COUNT(*) FROM favourites'),
      ) ??
      0;

  /// Whether the track with [stid] is a favourite.
  Future<bool> contains(String stid) async {
    final rows = await _db.query(
      'favourites',
      columns: ['stid'],
      where: 'stid = ?',
      whereArgs: [stid],
    );
    return rows.isNotEmpty;
  }

  /// Removes the track with [stid] from the favourites.
  Future<void> remove(String stid) =>
      _db.delete('favourites', where: 'stid = ?', whereArgs: [stid]);

  /// Removes the tracks with [stids] from the favourites.
  Future<void> removeAll(List<String> stids) => _db.delete(
    'favourites',
    where: 'stid IN (${placeholders(stids.length)})',
    whereArgs: stids,
  );
}
