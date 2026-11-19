import 'package:flutter/foundation.dart';

import '../../../data/repositories/history/history_repository.dart';

/// The user's past searches.
class SearchHistoryViewModel extends ChangeNotifier {
  /// Creates a view model and loads the history.
  SearchHistoryViewModel({required this._history}) {
    load();
  }

  final HistoryRepository _history;

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
}
