import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/library/downloads_repository.dart';
import '../../../data/repositories/library/favourites_repository.dart';
import '../../../data/repositories/player/player_repository.dart';
import '../../../domain/models/catalog/track.dart';
import '../../../domain/models/library/favourite.dart';
import '../../../utils/image_resolution.dart';
import '../../../utils/result.dart';
import '../app_icons.dart';
import '../messages/app_message.dart';
import '../messages/message_center.dart';

/// The actions of a track's menu, shared by every list of tracks.
class TrackActionsViewModel extends ChangeNotifier {
  /// Creates a view model.
  TrackActionsViewModel({
    required this._favourites,
    required this._downloads,
    required this._player,
    required this._messages,
  });

  final FavouritesRepository _favourites;
  final DownloadsRepository _downloads;
  final PlayerRepository _player;
  final MessageCenter _messages;

  /// Whether the track with [stid] is a favourite.
  Future<bool> isFavourite(String stid) => _favourites.isFavourite(stid);

  /// Likes [track], or unlikes it if it's already a favourite.
  ///
  /// Listeners are notified so favourite markers can refresh.
  Future<void> toggleFavourite(Track track) async {
    final favourite = await _favourites.toggle(
      Favourite(
        id: -1,
        stid: track.id,
        title: track.name,
        artistTrack: track.artists,
        albumTrack: track.album,
        image: track.album == null ? null : bestImageUrl(track.album!.images),
      ),
    );
    _messages.show(
      favourite
          ? InfoMessage(
              title: (l10n) => l10n.successful,
              body: (l10n) => l10n.trackisnowafavourite,
              icon: AppIcons.heartFill,
            )
          : InfoMessage(
              title: (l10n) => l10n.successful,
              body: (l10n) => l10n.trackremovedfromfavourites,
              icon: CupertinoIcons.heart_slash,
            ),
    );
    notifyListeners();
  }

  /// Saves [track] to the device; [cover] overrides its album image.
  Future<void> download(Track track, {String? cover}) async {
    final result = await _downloads.download(track, cover: cover);
    _messages.show(switch (result) {
      Ok(value: DownloadOutcome.downloaded) => InfoMessage(
        title: (l10n) => l10n.successful,
        body: (l10n) => l10n.successfullydownloadedthetrack,
        icon: AppIcons.download,
      ),
      Ok(value: DownloadOutcome.alreadyDownloaded) => InfoMessage(
        title: (l10n) => l10n.notification,
        body: (l10n) => l10n.trackalreadydownloaded,
        icon: AppIcons.download,
      ),
      Error() => WarningMessage((l10n) => l10n.downloadfailed),
    });
    notifyListeners();
  }

  /// The IDs in [stids] of tracks that aren't downloaded yet.
  Future<List<String>> missingDownloads(List<String> stids) =>
      _downloads.missing(stids);

  /// Plays [track] after the current one.
  Future<void> addNext(Track track, {required String collectionId}) async {
    await _player.addNext(track, collectionId: collectionId);
    _warnIfShuffling();
  }

  /// Plays [track] after the rest of the queue.
  Future<void> addLast(Track track, {required String collectionId}) async {
    await _player.addLast(track, collectionId: collectionId);
    _warnIfShuffling();
  }

  void _warnIfShuffling() {
    if (_player.shuffleEnabled) {
      _messages.show(WarningMessage((l10n) => l10n.shufflemodeison));
    }
  }
}

/// Access to the [TrackActionsViewModel] from widgets.
extension TrackActionsContext on BuildContext {
  /// The shared track actions.
  TrackActionsViewModel get trackActions => read<TrackActionsViewModel>();
}
