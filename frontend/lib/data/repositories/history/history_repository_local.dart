import '../../services/database/database_service.dart';
import 'history_repository.dart';

/// A [HistoryRepository] kept in the device database.
class HistoryRepositoryLocal implements HistoryRepository {
  /// Creates a repository backed by [_database].
  HistoryRepositoryLocal({required this._database});

  final DatabaseService _database;

  @override
  Future<List<String>> searches() => _database.searchHistory.queryAll();

  @override
  Future<void> addSearch(String query) => _database.searchHistory.insert(query);

  @override
  Future<void> removeSearch(String query) =>
      _database.searchHistory.remove(query);

  @override
  Future<void> clearSearches() => _database.searchHistory.clear();

  @override
  Future<List<String>> playedTracks({int? limit}) =>
      _database.playHistory.queryTracks(limit: limit);

  @override
  Future<void> addPlayedTrack(String stid) =>
      _database.playHistory.insertTrack(stid);

  @override
  Future<List<String>> viewedArtists({int? limit}) =>
      _database.playHistory.queryArtists(limit: limit);

  @override
  Future<void> addViewedArtist(String said) =>
      _database.playHistory.insertArtist(said);
}
