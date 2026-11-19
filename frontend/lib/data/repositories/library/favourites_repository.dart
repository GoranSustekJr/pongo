import '../../../domain/models/library/favourite.dart';

/// Source of truth for the user's favourite tracks.
abstract class FavouritesRepository {
  /// All favourites, most recently added first.
  Future<List<Favourite>> favourites();

  /// The number of favourites.
  Future<int> count();

  /// Whether the track with [stid] is a favourite.
  Future<bool> isFavourite(String stid);

  /// Adds [favourite], or removes it if it's already a favourite.
  ///
  /// Returns whether the track is a favourite afterwards.
  Future<bool> toggle(Favourite favourite);

  /// Removes the tracks with [stids] from the favourites.
  Future<void> remove(List<String> stids);
}
