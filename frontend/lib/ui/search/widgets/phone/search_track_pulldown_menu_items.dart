import 'package:flutter/material.dart';
import 'package:kr_pull_down_button/pull_down_button.dart';
import 'package:star_menu/star_menu.dart';

import '../../../../domain/models/catalog/track.dart';
import '../../../../domain/models/playlists/playlist_handler.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/app_icons.dart';
import '../../../core/themes/colors.dart';
import '../../../core/ui/phone/inkwell.dart';
import '../../../core/view_models/track_actions_view_model.dart';
import '../../../playlists/view_models/open_playlist.dart';

List<PullDownMenuEntry> searchTrackPulldownMenuItemsApple(
  BuildContext context,
  Track track,
  String id,
  bool favourite,
) {
  return [
    PullDownMenuItem(
      onTap: () async {
        await context.trackActions.download(track);
      },
      title: AppLocalizations.of(context).download,
      icon: AppIcons.download,
    ),
    const PullDownMenuDivider.large(),
    PullDownMenuItem(
      onTap: () {
        OpenPlaylist().show(
          context,
          PlaylistHandler(
            type: PlaylistHandlerType.online,
            function: PlaylistHandlerFunction.addToPlaylist,
            track: [onlineHandlerTrack(track)],
          ),
        );
      },
      title: AppLocalizations.of(context).addtoplaylist,
      icon: AppIcons.musicAlbums,
      itemTheme: const PullDownMenuItemTheme(
        textStyle: TextStyle(overflow: TextOverflow.ellipsis, height: 1),
      ),
    ),
    const PullDownMenuDivider.large(),
    PullDownMenuItem(
      onTap: () async {
        await context.trackActions.addNext(track, collectionId: id);
      },
      title: AppLocalizations.of(context).firsttoqueue,
      icon: AppIcons.firstToQueue,
      itemTheme: const PullDownMenuItemTheme(
        textStyle: TextStyle(overflow: TextOverflow.ellipsis, height: 1),
      ),
    ),
    const PullDownMenuDivider(),
    PullDownMenuItem(
      onTap: () async {
        await context.trackActions.addLast(track, collectionId: id);
      },
      title: AppLocalizations.of(context).lasttoqueue,
      icon: AppIcons.lastToQueue,
      itemTheme: const PullDownMenuItemTheme(
        textStyle: TextStyle(overflow: TextOverflow.ellipsis, height: 1),
      ),
    ),
    const PullDownMenuDivider.large(),
    PullDownMenuItem(
      onTap: () async {
        await context.trackActions.toggleFavourite(track);
      },
      title: favourite
          ? AppLocalizations.of(context).unlike
          : AppLocalizations.of(context).like,
      icon: favourite ? AppIcons.heartFill : AppIcons.heart,
      itemTheme: const PullDownMenuItemTheme(
        textStyle: TextStyle(overflow: TextOverflow.ellipsis, height: 1),
      ),
    ),
  ];
}

// Android
List<Widget> searchTrackPulldownMenuItemsAndroid(
  BuildContext context,
  Track track,
  String id,
  bool favourite,
) {
  final TextStyle textStyle = TextStyle(
    overflow: TextOverflow.ellipsis,
    color: context.colors.text,
    fontSize: 18,
    fontWeight: FontWeight.w400,
  );
  return [
    //const PullDownMenuDivider.large(),

    //const PullDownMenuDivider(),

    // const PullDownMenuDivider.large(),
    ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(7.5)),
      child: inkWell(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7.5),
          height: 40,
          width: 200,
          decoration: const BoxDecoration(),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  favourite
                      ? AppLocalizations.of(context).unlike
                      : AppLocalizations.of(context).like,
                  style: textStyle,
                ),
              ),
              Icon(
                favourite ? AppIcons.heartFill : AppIcons.heart,
                color: context.colors.text,
                size: 18,
              ),
            ],
          ),
        ),
        () async {
          await context.trackActions.toggleFavourite(track);
          StarMenuOverlay.dispose();
        },
      ),
    ),

    Container(width: 200, height: 5, color: context.colors.onIcon),
    inkWell(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 7.5),
        height: 40,
        width: 200,
        decoration: const BoxDecoration(),
        child: Row(
          children: [
            Expanded(
              child: Text(
                AppLocalizations.of(context).lasttoqueue,
                style: textStyle,
                maxLines: 1,
              ),
            ),
            Icon(AppIcons.lastToQueue, color: context.colors.text, size: 18),
          ],
        ),
      ),
      () async {
        await context.trackActions.addLast(track, collectionId: id);
        StarMenuOverlay.dispose();
      },
    ),

    inkWell(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 7.5),
        height: 40,
        width: 200,
        decoration: const BoxDecoration(),
        child: Row(
          children: [
            Expanded(
              child: Text(
                AppLocalizations.of(context).firsttoqueue,
                style: textStyle,
                maxLines: 1,
              ),
            ),
            Icon(AppIcons.firstToQueue, color: context.colors.text, size: 18),
          ],
        ),
      ),
      () async {
        await context.trackActions.addNext(track, collectionId: id);
        StarMenuOverlay.dispose();
      },
    ),

    Container(width: 200, height: 5, color: context.colors.onIcon),
    inkWell(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 7.5),
        height: 40,
        width: 200,
        decoration: const BoxDecoration(),
        child: Row(
          children: [
            Expanded(
              child: Text(
                AppLocalizations.of(context).addtoplaylist,
                style: textStyle,
                maxLines: 1,
              ),
            ),
            Icon(AppIcons.musicAlbums, color: context.colors.text, size: 18),
          ],
        ),
      ),
      () {
        OpenPlaylist().show(
          context,
          PlaylistHandler(
            type: PlaylistHandlerType.online,
            function: PlaylistHandlerFunction.addToPlaylist,
            track: [onlineHandlerTrack(track)],
          ),
        );
        StarMenuOverlay.dispose();
      },
    ),

    ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(7.5)),
      child: inkWell(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7.5),
          height: 40,
          width: 200,
          decoration: const BoxDecoration(),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  AppLocalizations.of(context).download,
                  style: textStyle,
                  maxLines: 1,
                ),
              ),
              Icon(AppIcons.download, color: context.colors.text, size: 18),
            ],
          ),
        ),
        () async {
          await context.trackActions.download(track);
          StarMenuOverlay.dispose();
        },
      ),
    ),
  ];
}
