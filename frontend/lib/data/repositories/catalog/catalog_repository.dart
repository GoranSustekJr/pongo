import '../../../domain/models/catalog/album.dart';
import '../../../domain/models/catalog/catalog_results.dart';
import '../../../utils/result.dart';

/// Source of truth for the music catalog.
abstract class CatalogRepository {
  /// Searches the catalog of [market] for [query].
  Future<Result<SearchResults>> search(String query, {required String market});

  /// The album with [id].
  Future<Result<Album>> album(String id);

  /// The tracks of [album].
  Future<Result<TrackListing>> albumTracks(Album album);

  /// The releases and top tracks of the artist with [id] in [market].
  Future<Result<ArtistDetails>> artist(String id, {required String market});

  /// The URL of the profile image of the artist with [id].
  Future<Result<String>> artistImage(String id);

  /// The tracks of the catalog playlist with [id].
  Future<Result<TrackListing>> playlistTracks(String id);

  /// Which of the tracks with [stids] the server can stream right away.
  Future<Result<TrackAvailabilityMap>> availability(List<String> stids);

  /// The home screen content for the user's [history] of played track IDs.
  Future<Result<HomeFeed>> homeFeed({
    required List<String> history,
    required String market,
    required String locale,
    required int categoryCount,
    required bool includeHistory,
    required bool includeCategories,
  });

  /// Recognizes the song behind the track with [stid].
  Future<Result<ShazamMatch>> shazam(String stid);
}
