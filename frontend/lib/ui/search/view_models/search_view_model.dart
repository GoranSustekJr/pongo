import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/repositories/catalog/catalog_repository.dart';
import '../../../data/repositories/settings/settings_repository.dart';
import '../../../domain/models/catalog/album.dart';
import '../../../domain/models/catalog/artist.dart';
import '../../../domain/models/catalog/playlist.dart';
import '../../../domain/models/catalog/track.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';

/// Search results for the latest query.
class SearchViewModel extends ChangeNotifier {
  /// Creates a view model that also runs the queries from [searchRequests].
  SearchViewModel({
    required this._catalog,
    required this._settings,
    required Stream<String> searchRequests,
  }) {
    _requests = searchRequests.listen(search);
  }

  final CatalogRepository _catalog;
  final SettingsRepository _settings;
  late final StreamSubscription<String> _requests;

  String _query = '';
  List<Track> _tracks = const [];
  List<Artist> _artists = const [];
  List<Album> _albums = const [];
  List<Playlist> _playlists = const [];

  /// The query of the results.
  String get query => _query;

  /// Matching tracks.
  List<Track> get tracks => _tracks;

  /// Matching artists.
  List<Artist> get artists => _artists;

  /// Matching albums.
  List<Album> get albums => _albums;

  /// Matching playlists.
  List<Playlist> get playlists => _playlists;

  /// Searches the catalog; an empty query clears the results.
  ///
  /// Unlike a [Command], a new search may start while one is running, and
  /// the older one's results are dropped.
  Future<Result<void>> search(String query) async {
    _query = query;
    if (query.isEmpty) {
      _tracks = const [];
      _artists = const [];
      _albums = const [];
      _playlists = const [];
      notifyListeners();
      return const Result.ok(null);
    }

    final result = await _catalog.search(
      query,
      market: _settings.settings.market,
    );
    // A newer search or a cancel happened meanwhile.
    if (_query != query) return const Result.ok(null);
    switch (result) {
      case Ok(:final value):
        _tracks = value.tracks;
        _artists = value.artists;
        _albums = value.albums;
        _playlists = value.playlists;
        notifyListeners();
        return const Result.ok(null);
      case Error(:final error):
        return Result.error(error);
    }
  }

  @override
  void dispose() {
    unawaited(_requests.cancel());
    super.dispose();
  }
}
