import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../../../../data/repositories/player/media_items.dart';
import '../../../../../domain/models/playlists/playlist_handler.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../utils/platform.dart';
import '../../../../core/app_icons.dart';
import '../../../../core/themes/colors.dart';
import '../../../../core/ui/phone/buttons/icon_button.dart';
import '../../../../core/ui/space.dart';
import '../../../../core/view_models/track_actions_view_model.dart';
import '../../../../playlists/view_models/open_playlist.dart';
import '../../../../shell/view_models/shell_view_model.dart';
import '../../../view_models/player_view_model.dart';
import '../../phone/alerts/halt_alert.dart';

// The queue's catalog tracks for the playlist editor
List<PlaylistHandlerOnlineTrack> _queueTracks(BuildContext context) => [
  for (final item in context.player.queue.value)
    if (item.toTrack() case final track)
      PlaylistHandlerOnlineTrack(
        id: track.id,
        name: track.name,
        artist: track.artists,
        cover: item.artUri?.toString() ?? '',
        albumTrack: track.album,
        playlistHandlerCoverType:
            (item.artUri?.toString() ?? '').contains('file:///')
            ? PlaylistHandlerCoverType.bytes
            : PlaylistHandlerCoverType.url,
      ),
];

// Saves the queue as a new online playlist
void _saveAsPlaylist(BuildContext context) {
  final tracks = _queueTracks(context);
  if (tracks.isEmpty) return;
  OpenPlaylist().show(
    context,
    PlaylistHandler(
      type: PlaylistHandlerType.online,
      function: PlaylistHandlerFunction.createPlaylist,
      track: tracks,
    ),
  );
}

// Downloads the queue into an offline playlist
Future<void> _download(BuildContext context) async {
  final tracks = _queueTracks(context);
  if (tracks.isEmpty) return;
  final toDownload = await context.trackActions.missingDownloads([
    for (final track in tracks) track.id,
  ]);
  if (!context.mounted) return;
  OpenPlaylist().show(
    context,
    PlaylistHandler(
      type: PlaylistHandlerType.offline,
      function: PlaylistHandlerFunction.addToPlaylist,
      toDownload: toDownload,
      track: tracks,
    ),
  );
}

class QueueButtonsMacos extends StatelessWidget {
  final bool edit;
  final Function(bool) changeEditQueue;
  final Function() removeItemsFromQueue;
  final Function() clearSelectedQueueIndexes;
  final Function() closeQueue;
  const QueueButtonsMacos({
    super.key,
    required this.edit,
    required this.changeEditQueue,
    required this.removeItemsFromQueue,
    required this.clearSelectedQueueIndexes,
    required this.closeQueue,
  });

  @override
  Widget build(BuildContext context) {
    final player = context.player;
    return SizedBox(
      height: 40,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Tooltip(
            message: AppLocalizations.of(context).shuffle,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(60),
                color: kIsDesktop && !kIsMacOS
                    ? const MacosColor.fromRGBO(
                        40,
                        40,
                        40,
                        0.8,
                      ) // Add transparency here
                    : Col.transp,
              ),
              child: ValueListenableBuilder(
                valueListenable: context.player.canShuffle,
                builder: (context, _, _) {
                  return CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () async {
                      if (context.player.canShuffle.value) {
                        if (player.shuffleEnabled) {
                          await player.setShuffle(enabled: false);
                        } else {
                          await player.setShuffle(enabled: true);
                        }
                      }
                    },
                    child: StreamBuilder(
                      stream: player.shuffleEnabledStream,
                      builder: (context, snapshot) {
                        final bool enabled = snapshot.data ?? false;
                        return Icon(
                          AppIcons.shuffle,
                          color: enabled
                              ? Colors.white
                              : Colors.white.withAlpha(150),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
          dividerVertical(30, 1, 7.5),
          Tooltip(
            message: edit
                ? AppLocalizations.of(context).cancel
                : AppLocalizations.of(context).edit,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(60),
                color: kIsDesktop && !kIsMacOS
                    ? const MacosColor.fromRGBO(
                        40,
                        40,
                        40,
                        0.8,
                      ) // Add transparency here
                    : Col.transp,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: edit
                    ? iconButton(AppIcons.x, Colors.white, () {
                        changeEditQueue(false);
                        clearSelectedQueueIndexes();
                      }, edgeInsets: EdgeInsets.zero)
                    : iconButton(AppIcons.edit, Colors.white, () {
                        changeEditQueue(true);
                      }, edgeInsets: EdgeInsets.zero),
              ),
            ),
          ),
          dividerVertical(30, 1, 7.5),
          Tooltip(
            message: edit
                ? AppLocalizations.of(context).delete
                : AppLocalizations.of(context).addtrackstoyoutplaylist,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(60),
                color: kIsDesktop && !kIsMacOS
                    ? const MacosColor.fromRGBO(
                        40,
                        40,
                        40,
                        0.8,
                      ) // Add transparency here
                    : Col.transp,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: edit
                    ? iconButton(
                        AppIcons.trash,
                        Colors.white,
                        removeItemsFromQueue,
                        edgeInsets: EdgeInsets.zero,
                      )
                    : iconButton(
                        AppIcons.musicAlbums,
                        Colors.white,
                        () => _saveAsPlaylist(context),
                        edgeInsets: EdgeInsets.zero,
                      ),
              ),
            ),
          ),
          dividerVertical(30, 1, 7.5),
          Tooltip(
            message: AppLocalizations.of(context).download,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(60),
                color: kIsDesktop && !kIsMacOS
                    ? const MacosColor.fromRGBO(
                        40,
                        40,
                        40,
                        0.8,
                      ) // Add transparency here
                    : Col.transp,
              ),
              child: iconButton(
                AppIcons.download,
                Colors.white,
                () => _download(context),
                edgeInsets: EdgeInsets.zero,
              ),
            ),
          ),
          dividerVertical(30, 1, 7.5),
          Tooltip(
            message: AppLocalizations.of(context).halt,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(60),
                color: kIsDesktop && !kIsMacOS
                    ? const MacosColor.fromRGBO(
                        40,
                        40,
                        40,
                        0.8,
                      ) // Add transparency here
                    : Col.transp,
              ),
              child: iconButton(AppIcons.halt, Colors.white, () async {
                final CustomButton ok = await haltAlert(context);

                if (ok == CustomButton.positiveButton && context.mounted) {
                  context.shell.currentTrackHeight.value = 0;
                  final player = context.player;

                  closeQueue();

                  await player.halt();
                }
              }, edgeInsets: EdgeInsets.zero),
            ),
          ),
        ],
      ),
    );
  }
}
