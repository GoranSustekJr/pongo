import 'package:flutter/foundation.dart';

import '../../../data/repositories/catalog/catalog_repository.dart';
import '../../../data/repositories/history/history_repository.dart';
import '../../../data/repositories/settings/settings_repository.dart';
import '../../../data/services/media/blurhash_service.dart';
import '../../../domain/models/catalog/album.dart';
import '../../../domain/models/catalog/artist.dart';
import '../../../domain/models/catalog/track.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';

/// An artist's releases and top tracks.
class ArtistViewModel extends ChangeNotifier {
  /// Creates a view model for [artist] and loads it.
  ArtistViewModel({
    required this.artist,
    required this._catalog,
    required this._history,
    required this._settings,
    required this._blurhash,
  }) {
    load = Command0(_load)..execute();
  }

  /// The artist.
  final Artist artist;

  final CatalogRepository _catalog;
  final HistoryRepository _history;
  final SettingsRepository _settings;
  final BlurhashService _blurhash;

  /// Loads the artist.
  late final Command0<void> load;

  bool _showBody = false;
  List<Album> _albums = const [];
  List<Album> _otherAlbums = const [];
  List<Track> _tracks = const [];
  String? _blurhashValue;

  /// Whether the artist is loaded.
  bool get showBody => _showBody;

  /// The artist's albums.
  List<Album> get albums => _albums;

  /// Singles, compilations and appearances.
  List<Album> get otherAlbums => _otherAlbums;

  /// Top tracks.
  List<Track> get tracks => _tracks;

  /// Related artists, which the server doesn't send at the moment.
  List<Artist> get artists => const [];

  /// The blurhash of the artist image, or `null` for the default one.
  String? get blurhash => _blurhashValue;

  Future<Result<void>> _load() async {
    final result = await _catalog.artist(
      artist.id,
      market: _settings.settings.market,
    );
    switch (result) {
      case Error(:final error):
        return Result.error(error);
      case Ok(:final value):
        _albums = value.albums;
        _otherAlbums = value.otherReleases;
        _tracks = value.tracks;
        if (artist.image.isNotEmpty) {
          try {
            _blurhashValue = await _blurhash.encodeUrl(artist.image);
          } on Exception {
            _blurhashValue = null;
          }
        }
        _showBody = true;
        notifyListeners();
        await _history.addViewedArtist(artist.id);
        return const Result.ok(null);
    }
  }

  @override
  void dispose() {
    load.dispose();
    super.dispose();
  }
}
