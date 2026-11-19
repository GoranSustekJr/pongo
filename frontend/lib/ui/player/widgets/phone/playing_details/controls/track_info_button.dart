import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:kr_pull_down_button/pull_down_button.dart';

import '../../../../../../data/repositories/player/media_items.dart';
import '../../../../../../domain/models/catalog/track.dart';
import '../../../../../../domain/models/playlists/playlist_handler.dart';
import '../../../../../../l10n/app_localizations.dart';
import '../../../../../core/app_icons.dart';
import '../../../../../core/ui/phone/buttons/icon_button.dart';
import '../../../../../core/view_models/track_actions_view_model.dart';
import '../../../../../playlists/view_models/open_playlist.dart';
import '../../../../../shell/view_models/shell_view_model.dart';
import '../../../../view_models/player_view_model.dart';
import '../../alerts/halt_alert.dart';

PullDownButton trackInfoButton(
  BuildContext context,
  Track track,
  bool favourite,
  Function() download,
  Function() refreshFavourite,
) {
  return /* kIsApple
      ?  */ PullDownButton(
    itemBuilder: (context) => [
      PullDownMenuItem(
        title: AppLocalizations.of(context).download,
        icon: CupertinoIcons.cloud_download,
        onTap: () {
          download();
        },
      ),
      const PullDownMenuDivider(),
      PullDownMenuItem(
        title: AppLocalizations.of(context).addtoplaylist,
        icon: AppIcons.musicAlbums,
        onTap: () {
          final player = context.player;
          final MediaItem? mediaItem = player.currentItem.value;
          if (mediaItem != null) {
            OpenPlaylist().show(
              context,
              PlaylistHandler(
                type: PlaylistHandlerType.online,
                function: PlaylistHandlerFunction.addToPlaylist,
                track: [
                  PlaylistHandlerOnlineTrack(
                    id: mediaItem.stid,
                    name: mediaItem.title,
                    artist: mediaItem.artistRefs,
                    cover: (mediaItem.artUri?.toString() ?? ''),
                    albumTrack: mediaItem.toTrack().album,
                    playlistHandlerCoverType:
                        !(mediaItem.artUri?.toString() ?? '').contains(
                          'file:///',
                        )
                        ? PlaylistHandlerCoverType.url
                        : PlaylistHandlerCoverType.bytes,
                  ),
                ],
              ),
            );
          }
        },
      ),
      const PullDownMenuDivider.large(),
      PullDownMenuItem(
        title: favourite
            ? AppLocalizations.of(context).unlike
            : AppLocalizations.of(context).like,
        icon: favourite ? AppIcons.heartFill : AppIcons.heart,
        onTap: () async {
          final item = context.player.currentItem.value;
          if (item != null) {
            await context.trackActions.toggleFavourite(item.toTrack());
          }
          refreshFavourite();
        },
      ),
      const PullDownMenuDivider.large(),
      PullDownMenuItem(
        onTap: () async {
          final CustomButton ok = await haltAlert(context);
          if (ok == CustomButton.positiveButton && context.mounted) {
            context.shell.currentTrackHeight.value = 0;
            final player = context.player;

            await player.halt();
          }
        },
        title: AppLocalizations.of(context).halt,
        icon: AppIcons.halt,
        itemTheme: const PullDownMenuItemTheme(
          textStyle: TextStyle(overflow: TextOverflow.ellipsis, height: 1),
        ),
      ),
    ],
    position: PullDownMenuPosition.above,
    buttonBuilder: (context, showMenu) => iconButton(
      AppIcons.more,
      Colors.white,
      showMenu,
      edgeInsets: EdgeInsets.zero,
    ),
  );
  /* : SizedBox(
          key: key,
          width: 50,
          height: 50,
          child: IconButton(
            splashColor: Col.primary,
            icon: const Icon(AppIcons.more),
            onPressed: () {
              PopupMenu(
                context: context,
                config: MenuConfig(
                  itemWidth: 150,
                  backgroundColor: context.colors.primaryCard,
                  lineColor: Colors.greenAccent,
                  highlightColor: Colors.lightGreenAccent,
                  type: MenuType.list,
                ),
                items: [
                  PopUpMenuItem(
                      title: AppLocalizations.of(context).download,
                      image: const Icon(
                        AppIcons.download,
                        color: Colors.white,
                      )),
                  PopUpMenuItem(
                      title: AppLocalizations.of(context).addtoplaylist,
                      image: const Icon(
                        AppIcons.musicAlbums,
                        color: Colors.white,
                      )),
                  PopUpMenuItem(
                    title: "",
                    image: Row(
                      children: [
                        Text(AppLocalizations.of(context).like),
                        Icon(
                          favourite ? AppIcons.heartFill : AppIcons.heart,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ).show(widgetKey: key);
            },
          ),
        ); */
}
