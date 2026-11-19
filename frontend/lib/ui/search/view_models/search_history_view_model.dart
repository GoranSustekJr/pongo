import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/repositories/history/history_repository.dart';

/// The user's past searches.
class SearchHistoryViewModel extends ChangeNotifier {
  /// Creates a view model and loads the history, and loads it again
  /// whenever `libraryChanges` notifies.
  SearchHistoryViewModel({required this._history, this._libraryChanges}) {
    _libraryChanges?.addListener(_reload);
    load();
  }

  final HistoryRepository _history;
  final Listenable? _libraryChanges;

  List<String> _searches = const [];

  /// Past queries, latest first.
  List<String> get searches => _searches;

  /// Reloads the history.
  Future<void> load() async {
    _searches = await _history.searches();
    notifyListeners();
  }

  /// Records [query] as the latest search.
  Future<void> add(String query) async {
    await _history.addSearch(query);
    await load();
  }

  /// Forgets [query].
  Future<void> remove(String query) async {
    await _history.removeSearch(query);
    await load();
  }

  /// Forgets every search.
  Future<void> clear() async {
    await _history.clearSearches();
    await load();
  }

  void _reload() => unawaited(load());

  @override
  void dispose() {
    _libraryChanges?.removeListener(_reload);
    super.dispose();
  }
}
