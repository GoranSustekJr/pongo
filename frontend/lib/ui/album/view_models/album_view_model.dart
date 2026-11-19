import '../../../data/repositories/catalog/catalog_repository.dart';
import '../../../domain/models/catalog/album.dart';
import '../../../domain/models/catalog/catalog_results.dart';
import '../../../utils/result.dart';
import '../../core/view_models/online_collection_view_model.dart';

/// The tracks of an album.
class AlbumViewModel extends OnlineCollectionViewModel {
  /// Creates a view model for [album].
  AlbumViewModel({
    required this.album,
    required this._catalog,
    required super.player,
    required super.blurhash,
  }) : super(collectionId: 'online.album:${album.id}');

  /// The album.
  final Album album;

  final CatalogRepository _catalog;

  @override
  Future<Result<TrackListing>> fetch() => _catalog.albumTracks(album);

  @override
  String get coverUrl => album.image;
}
