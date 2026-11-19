import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../../../domain/models/catalog/track.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/app_icons.dart';
import '../../../core/ui/space.dart';
import '../../../core/view_models/track_actions_view_model.dart';

List<MacosPulldownMenuEntry> searchTrackPulldownMenuItemsMacos(
  BuildContext context,
  Track track,
  String id,
  bool favourite,
) {
  return [
    MacosPulldownMenuItem(
      title: SizedBox(
        width: 150,
        height: 70,
        child: Row(
          children: [
            const Icon(AppIcons.download, color: Colors.white),
            razw(10),
            Expanded(
              child: Text(
                AppLocalizations.of(context).download,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
      onTap: () async {
        await context.trackActions.download(track);
      },
    ),
    const MacosPulldownMenuDivider(),
    MacosPulldownMenuItem(
      title: SizedBox(
        width: 150,
        height: 70,
        child: Row(
          children: [
            const Icon(AppIcons.musicAlbums, color: Colors.white),
            razw(10),
            Expanded(
              child: Text(
                AppLocalizations.of(context).addtoplaylist,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
      onTap: () {
        //TODO: Add to playlist
      },
    ),
    const MacosPulldownMenuDivider(),
    MacosPulldownMenuItem(
      title: SizedBox(
        width: 150,
        height: 70,
        child: Row(
          children: [
            const Icon(AppIcons.firstToQueue, color: Colors.white),
            razw(10),
            Expanded(
              child: Text(
                AppLocalizations.of(context).firsttoqueue,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
      onTap: () async {
        await context.trackActions.addNext(track, collectionId: id);
      },
    ),
    MacosPulldownMenuItem(
      title: SizedBox(
        width: 150,
        height: 70,
        child: Row(
          children: [
            const Icon(AppIcons.lastToQueue, color: Colors.white),
            razw(10),
            Expanded(
              child: Text(
                AppLocalizations.of(context).lasttoqueue,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
      onTap: () async {
        await context.trackActions.addLast(track, collectionId: id);
      },
    ),
    const MacosPulldownMenuDivider(),
    MacosPulldownMenuItem(
      title: SizedBox(
        width: 150,
        height: 70,
        child: Row(
          children: [
            Icon(
              favourite ? AppIcons.heartFill : AppIcons.heart,
              color: Colors.white,
            ),
            razw(10),
            Expanded(
              child: Text(
                favourite
                    ? AppLocalizations.of(context).unlike
                    : AppLocalizations.of(context).like,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
      onTap: () async {
        await context.trackActions.toggleFavourite(track);

        // The UI will not auto-refresh since there is no stateful management
        // here
      },
    ),
  ];
}
