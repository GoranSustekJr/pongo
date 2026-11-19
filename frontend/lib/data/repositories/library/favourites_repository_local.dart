import '../../../domain/models/library/favourite.dart';
import '../../services/database/database_service.dart';
import 'favourites_repository.dart';

/// A [FavouritesRepository] kept in the device database.
class FavouritesRepositoryLocal implements FavouritesRepository {
  /// Creates a repository backed by [_database].
  FavouritesRepositoryLocal({required this._database});

  final DatabaseService _database;

  @override
  Future<List<Favourite>> favourites() => _database.favourites.queryAll();

  @override
  Future<int> count() => _database.favourites.count();

  @override
  Future<bool> isFavourite(String stid) => _database.favourites.contains(stid);

  @override
  Future<bool> toggle(Favourite favourite) async {
    if (await _database.favourites.contains(favourite.stid)) {
      await _database.favourites.remove(favourite.stid);
      return false;
    }
    await _database.favourites.insert(favourite);
    return true;
  }

  @override
  Future<void> remove(List<String> stids) =>
      _database.favourites.removeAll(stids);
}
