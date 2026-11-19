import '../../../domain/models/catalog/album.dart';
import '../../../domain/models/catalog/artist.dart';
import '../../../domain/models/catalog/catalog_results.dart';
import '../../../domain/models/catalog/category.dart';
import '../../../domain/models/catalog/playlist.dart';
import '../../../domain/models/catalog/track.dart';
import '../../../utils/image_resolution.dart';
import '../../../utils/json.dart';
import '../../../utils/result.dart';
import '../../services/api/api_client.dart';
import 'catalog_repository.dart';

/// A [CatalogRepository] backed by the Pongo API.
class CatalogRepositoryRemote implements CatalogRepository {
  /// Creates a repository that calls [_apiClient].
  CatalogRepositoryRemote({required this._apiClient});

  final ApiClient _apiClient;

  Future<Result<T>> _post<T>(
    String path,
    Map<String, dynamic> body,
    T Function(Map<String, dynamic> data) parse,
  ) async {
    final result = await _apiClient.post(path, body);
    switch (result) {
      case Ok(:final value):
        try {
          return Result.ok(parse(value));
          // Malformed responses surface as errors instead of crashes.
          // ignore: avoid_catching_errors
        } on TypeError catch (e) {
          return Result.error(FormatException('$path: $e'));
        }
      case Error(:final error):
        return Result.error(error);
    }
  }

  @override
  Future<Result<SearchResults>> search(
    String query, {
    required String market,
  }) => _post('search_spotify', {'query': query, 'market': market}, (data) {
    List<dynamic> items(String key) =>
        (data[key] as Map<String, dynamic>)['items'] as List;
    return SearchResults(
      tracks: Track.fromMapList(items('tracks')),
      artists: Artist.fromMapList(items('artists')),
      albums: Album.fromMapList(items('albums')),
      playlists: Playlist.fromMapList(items('playlists')),
    );
  });

  @override
  Future<Result<Album>> album(String id) =>
      _post('get_album_data', {'salid': id}, Album.fromMapWithThumbnail);

  @override
  Future<Result<TrackListing>> albumTracks(Album album) =>
      _post('get_album', {'salid': album.id}, (data) {
        // Album tracks arrive without their album, so it's attached here.
        final albumMap = {
          'id': album.id,
          'name': album.name,
          'images': [
            {'url': album.image, 'height': null, 'width': null},
          ],
          'release_date': '',
        };
        return TrackListing(
          tracks: [
            for (final track in data['items'] as List)
              Track.fromMap({
                ...track as Map<String, dynamic>,
                'album': albumMap,
              }),
          ],
          availability: TrackAvailabilityMap.fromMap(data),
        );
      });

  @override
  Future<Result<ArtistDetails>> artist(String id, {required String market}) =>
      _post('get_artist_metadata', {'said': id, 'market': market}, (data) {
        final albums = Album.fromMapList(data['albums'] as List);
        return ArtistDetails(
          albums: albums.where((album) => album.type == 'album').toList(),
          otherReleases: albums
              .where((album) => album.type != 'album')
              .toList(),
          tracks: Track.fromMapList(data['tracks'] as List),
        );
      });

  @override
  Future<Result<String>> artistImage(String id) => _post(
    'caf5cc332d474f35ff74e94af44f2a7801b620b2ce0196560e038b511d14986e',
    {'said': id},
    (data) =>
        bestImageUrl(AlbumImagesTrack.fromMapList(data['images'] as List)),
  );

  @override
  Future<Result<TrackListing>> playlistTracks(String id) =>
      _post('get_playlist', {'spid': id}, (data) {
        return TrackListing(
          tracks: [
            for (final item
                in (data['items'] as List).cast<Map<String, dynamic>>())
              if (item.objectAt(['track']) case final track?
                  when track['name'] != '')
                Track.fromMap(track),
          ],
          availability: TrackAvailabilityMap.fromMap(data),
        );
      });

  @override
  Future<Result<TrackAvailabilityMap>> availability(List<String> stids) =>
      _post('get_serialized_shuffle', {
        'stids': stids,
      }, TrackAvailabilityMap.fromMap);

  @override
  Future<Result<HomeFeed>> homeFeed({
    required List<String> history,
    required String market,
    required String locale,
    required int categoryCount,
    required bool includeHistory,
    required bool includeCategories,
  }) => _post(
    'get_recommendations',
    {
      'market': market,
      'history': history,
      'category_num': categoryCount,
      'locale': locale,
    },
    (data) {
      final charts = data.objectAt(['charts']);
      final history = data.listAt(['history', 'tracks']);
      final categories = data.listAt(['categories', 'categories', 'items']);
      final newReleases = data.listAt(['new_releases', 'albums', 'items']);
      return HomeFeed(
        history: includeHistory && history != null
            ? Track.fromMapList(history)
            : const [],
        categories: includeCategories && categories != null
            ? SpCategory.fromMapList(categories)
            : const [],
        newReleases: includeCategories && newReleases != null
            ? [
                for (final album in newReleases)
                  Album.fromMapWithThumbnail(album as Map<String, dynamic>),
              ]
            : const [],
        topTracks: includeCategories && charts != null
            ? Track.fromMapList(charts['tracks'] as List)
            : const [],
        topArtists: includeCategories && charts != null
            ? Artist.fromMapList(charts['artists'] as List)
            : const [],
        topPlaylists: includeCategories && charts != null
            ? Playlist.fromMapList(charts['playlists'] as List)
            : const [],
      );
    },
  );

  @override
  Future<Result<ShazamMatch>> shazam(String stid) => _post(
    '6a2f5d49dda86647d136751f354f0bbfbd76a414a283b18f211b34f911029e0e',
    {'stid': stid},
    (data) {
      final track = data['track'] as Map<String, dynamic>;
      return ShazamMatch(
        title: track['title'] as String,
        subtitle: track['subtitle'] as String,
        coverArt: track.objectAt(['images'])!['coverart'] as String,
      );
    },
  );
}
