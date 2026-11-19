import 'package:flutter/foundation.dart';

import '../../../data/repositories/catalog/catalog_repository.dart';
import '../../../data/repositories/history/history_repository.dart';
import '../../../data/repositories/settings/settings_repository.dart';
import '../../../domain/models/catalog/album.dart';
import '../../../domain/models/catalog/artist.dart';
import '../../../domain/models/catalog/category.dart';
import '../../../domain/models/catalog/playlist.dart';
import '../../../domain/models/catalog/track.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';

/// The home screen's recommendations.
class RecommendationsViewModel extends ChangeNotifier {
  /// Creates a view model and loads the recommendations.
  RecommendationsViewModel({
    required this._catalog,
    required this._history,
    required this._settings,
  }) {
    load = Command0(_load)..execute();
  }

  final CatalogRepository _catalog;
  final HistoryRepository _history;
  final SettingsRepository _settings;

  /// Loads the recommendations.
  late final Command0<void> load;

  bool _showBody = false;
  bool _failed = false;
  bool _historyEnabled = true;
  bool _categoriesEnabled = true;
  List<SpCategory> _categories = const [];
  List<Track> _historyTracks = const [];
  List<Album> _newReleases = const [];
  List<Track> _topTracks = const [];
  List<Artist> _topArtists = const [];
  List<Playlist> _topPlaylists = const [];

  /// Whether loading finished, successfully or not.
  bool get showBody => _showBody;

  /// Whether loading failed.
  bool get failed => _failed;

  /// Whether the user wants recommendations from their history.
  bool get historyEnabled => _historyEnabled;

  /// Whether the user wants categories and charts.
  bool get categoriesEnabled => _categoriesEnabled;

  /// Browse categories.
  List<SpCategory> get categories => _categories;

  /// Tracks recommended from the play history.
  List<Track> get history => _historyTracks;

  /// New albums.
  List<Album> get newReleases => _newReleases;

  /// Chart tracks.
  List<Track> get topTracks => _topTracks;

  /// Chart artists.
  List<Artist> get topArtists => _topArtists;

  /// Chart playlists.
  List<Playlist> get topPlaylists => _topPlaylists;

  Future<Result<void>> _load() async {
    _failed = false;
    final settings = _settings.settings;
    _historyEnabled = settings.enableHistory;
    _categoriesEnabled = settings.enableCategories;

    if (_historyEnabled || _categoriesEnabled) {
      final result = await _catalog.homeFeed(
        history: await _history.playedTracks(limit: 50),
        market: settings.market,
        locale: settings.locale,
        categoryCount: settings.categoryCount,
        includeHistory: _historyEnabled,
        includeCategories: _categoriesEnabled,
      );
      switch (result) {
        case Ok(:final value):
          _historyTracks = value.history;
          _categories = value.categories;
          _newReleases = value.newReleases;
          _topTracks = value.topTracks;
          _topArtists = value.topArtists;
          _topPlaylists = value.topPlaylists;
        case Error():
          _failed = true;
      }
    }

    _showBody = true;
    notifyListeners();
    return const Result.ok(null);
  }

  @override
  void dispose() {
    load.dispose();
    super.dispose();
  }
}
