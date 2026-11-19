import '../../../data/repositories/catalog/catalog_repository.dart';
import '../../../domain/models/catalog/catalog_results.dart';
import '../../../domain/models/catalog/playlist.dart';
import '../../../utils/result.dart';
import '../../core/view_models/online_collection_view_model.dart';

/// The tracks of a catalog playlist.
class CatalogPlaylistViewModel extends OnlineCollectionViewModel {
  /// Creates a view model for [playlist].
  CatalogPlaylistViewModel({
    required this.playlist,
    required this._catalog,
    required super.player,
    required super.blurhash,
  }) : super(collectionId: 'online.playlist:${playlist.id}');

  /// The playlist.
  final Playlist playlist;

  final CatalogRepository _catalog;

  @override
  Future<Result<TrackListing>> fetch() => _catalog.playlistTracks(playlist.id);

  @override
  String get coverUrl => playlist.image;
}
