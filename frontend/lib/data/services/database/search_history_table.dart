import 'package:sqflite/sqflite.dart';

/// The `search_history` table, capped at the 500 latest queries.
///
/// `played_at` is when the query was last searched, in milliseconds since the
/// epoch.
class SearchHistoryTable {
  /// Creates a table backed by [_db].
  SearchHistoryTable(this._db);

  final Database _db;

  /// Moves [query] to the top of the history.
  Future<void> insert(String query) async {
    await remove(query);
    await _db.transaction((txn) async {
      await txn.insert('search_history', {
        'query': query,
        'played_at': DateTime.now().millisecondsSinceEpoch,
      });
      await txn.rawDelete('''
        DELETE FROM search_history WHERE id NOT IN (
          SELECT id FROM search_history ORDER BY played_at DESC, id DESC
          LIMIT 500
        )
      ''');
    });
  }

  /// All queries, latest first.
  Future<List<String>> queryAll() async {
    final rows = await _db.query(
      'search_history',
      columns: ['query'],
      orderBy: 'played_at DESC, id DESC',
    );
    return [for (final row in rows) row['query'] as String];
  }

  /// Removes [query] from the history.
  Future<void> remove(String query) =>
      _db.delete('search_history', where: 'query = ?', whereArgs: [query]);

  /// Removes every query.
  Future<void> clear() => _db.delete('search_history');
}
