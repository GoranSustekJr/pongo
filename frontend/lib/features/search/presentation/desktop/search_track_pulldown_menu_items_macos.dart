import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';

import 'package:pongo/core/constants/app_icons.dart';
import 'package:pongo/core/utils/calculate_image_resolution.dart';
import 'package:pongo/features/library/data/download_api.dart';
import 'package:pongo/features/library/data/favourites_actions.dart';
import 'package:pongo/features/library/models/favourite.dart';
import 'package:pongo/features/player/data/add_to_queue.dart';
import 'package:pongo/l10n/app_localizations.dart';
import 'package:pongo/shared/models/catalog/track.dart';
import 'package:pongo/shared/widgets/space.dart';

List<MacosPulldownMenuEntry> searchTrackPulldownMenuItemsMacos(
  context,
  Track track,
  String id,
  bool favourite,
  Function(String) doesNotExist,
  Function(String) doesNowExist,
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
              )
            ],
          )),
      onTap: () async {
        await DownloadApi().single(track);
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
              )
            ],
          )),
      onTap: () async {
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
              )
            ],
          )),
      onTap: () async {
        await AddToQueue()
            .addTypeTrackFirst(context, track, id, doesNotExist, doesNowExist);
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
              )
            ],
          )),
      onTap: () async {
        await AddToQueue()
            .addTypeTrackLast(context, track, id, doesNotExist, doesNowExist);
      },
    ),
    const MacosPulldownMenuDivider(),
    MacosPulldownMenuItem(
      title: SizedBox(
          width: 150,
          height: 70,
          child: Row(
            children: [
              Icon(favourite ? AppIcons.heartFill : AppIcons.heart,
                  color: Colors.white),
              razw(10),
              Expanded(
                child: Text(
                  favourite
                      ? AppLocalizations.of(context).unlike
                      : AppLocalizations.of(context).like,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              )
            ],
          )),
      onTap: () async {
        await Favourites().add(
            context,
            Favourite(
              id: -1,
              stid: track.id,
              title: track.name,
              artistTrack: track.artists,
              albumTrack: track.album,
              image: track.album != null
                  ? calculateBestImageForTrack(track.album!.images)
                  : null,
            ));
        doesNotExist("");
        doesNowExist("");

        // The UI will not auto-refresh since there is no stateful management here
      },
    ),
  ];
}
