import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/catalog/catalog_repository.dart';
import '../../../domain/models/catalog/album.dart';
import '../../../domain/models/catalog/artist.dart';
import '../../../domain/models/playlists/playlist_handler.dart';
import '../../../utils/result.dart';
import '../../core/messages/app_message.dart';
import '../../core/messages/message_center.dart';

/// State of the app's frame: tabs, search bar, player panel and overlays.
///
/// The values are listenables so each part of the frame rebuilds on its own.
class ShellViewModel extends ChangeNotifier {
  /// Creates the frame's state; [_catalog] resolves links from the player.
  ShellViewModel({required this._catalog, required this._messages});

  final CatalogRepository _catalog;
  final MessageCenter _messages;

  /// The selected tab.
  final navigationBarIndex = ValueNotifier(0);

  /// Whether the search bar is active.
  final searchBarIsSearching = ValueNotifier(false);

  /// Whether the bottom navigation bar is shown.
  final showBottomNavBar = ValueNotifier(true);

  /// Whether the search bar is shown.
  final showSearchBar = ValueNotifier(true);

  /// The height of the now playing panel, 0 when it's closed.
  final currentTrackHeight = ValueNotifier<double>(0);

  /// Whether the desktop app shows the full screen player.
  final fullscreenPlaying = ValueNotifier(false);

  /// The open playlist editor, or `null`.
  final playlistHandler = ValueNotifier<PlaylistHandler?>(null);

  /// Focus of the search field.
  final searchFocusNode = FocusNode();

  /// The navigator of the home tab, which shows catalog screens.
  final homeNavigatorKey = GlobalKey<NavigatorState>();

  /// The scroll offset the queue reopens at.
  double queueScrollOffset = 0;

  /// Whether a Shazam lookup is running.
  bool shazaming = false;

  /// Looks up the track with [stid] on Shazam and shows what it found.
  Future<void> shazam(String stid) async {
    if (shazaming) return;
    shazaming = true;
    final result = await _catalog.shazam(stid);
    shazaming = false;
    _messages.show(switch (result) {
      Ok(:final value) => ShazamMessage(
        title: value.title,
        subtitle: value.subtitle,
        imageUrl: value.coverArt,
      ),
      Error() => ErrorMessage(
        title: (l10n) => l10n.error,
        body: (l10n) => l10n.shazamfailed,
      ),
    });
  }

  final _searchRequests = StreamController<String>.broadcast();

  /// Queries to run in the search screen.
  Stream<String> get searchRequests => _searchRequests.stream;

  /// Shows the search screen with the results for [query].
  void requestSearch(String query) {
    currentTrackHeight.value = 0;
    navigationBarIndex.value = 0;
    _searchRequests.add(query);
    searchBarIsSearching.value = true;
  }

  /// Closes the player and shows the home tab, ready to open a screen there.
  void showHomeTab() {
    currentTrackHeight.value = 0;
    navigationBarIndex.value = 0;
  }

  /// The artist with [id] and [name], with its image, for opening its
  /// screen from the player.
  Future<Result<Artist>> artist({
    required String id,
    required String name,
  }) async {
    final image = await _catalog.artistImage(id);
    return switch (image) {
      Ok(:final value) => Result.ok(Artist(id: id, name: name, image: value)),
      Error(:final error) => Result.error(error),
    };
  }

  /// The album with [id], for opening its screen from the player.
  Future<Result<Album>> album(String id) => _catalog.album(id);

  @override
  void dispose() {
    for (final notifier in [
      navigationBarIndex,
      searchBarIsSearching,
      showBottomNavBar,
      showSearchBar,
      currentTrackHeight,
      fullscreenPlaying,
      playlistHandler,
    ]) {
      notifier.dispose();
    }
    searchFocusNode.dispose();
    unawaited(_searchRequests.close());
    super.dispose();
  }
}

/// Access to the [ShellViewModel] from widgets.
extension ShellContext on BuildContext {
  /// The app frame's state.
  ShellViewModel get shell => read<ShellViewModel>();
}
