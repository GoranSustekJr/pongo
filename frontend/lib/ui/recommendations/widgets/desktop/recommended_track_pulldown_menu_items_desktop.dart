import 'package:flutter/material.dart';
import 'package:flutter_desktop_context_menu/flutter_desktop_context_menu.dart';

import 'package:pongo/core/utils/calculate_image_resolution.dart';
import 'package:pongo/features/library/data/download_api.dart';
import 'package:pongo/features/library/data/favourites_actions.dart';
import 'package:pongo/features/library/models/favourite.dart';
import 'package:pongo/features/player/data/add_to_queue.dart';
import 'package:pongo/l10n/app_localizations.dart';
import 'package:pongo/shared/models/catalog/track.dart';

Menu recommendedTrackPulldownMenuItemsDesktop(
  BuildContext context,
  Track track,
  String id,
  bool favourite,
  Function(String) doesNotExist,
  Function(String) doesNowExist,
) {
  return Menu(
    items: [
      MenuItem(
          label: AppLocalizations.of(context).download,
          onClick: (menuItem) async {
            await DownloadApi().single(track);
          }),
      MenuItem.separator(),
      MenuItem(
        label: AppLocalizations.of(context).addtoplaylist,
        onClick: (menuItem) {
          // TODO: Add too playlist
        },
      ),
      MenuItem.separator(),
      MenuItem(
          label: AppLocalizations.of(context).firsttoqueue,
          onClick: (menuItem) async {
            await AddToQueue().addTypeTrackFirst(
                context, track, id, doesNotExist, doesNowExist);
          }),
      MenuItem(
          label: AppLocalizations.of(context).lasttoqueue,
          onClick: (menuItem) async {
            await AddToQueue().addTypeTrackLast(
                context, track, id, doesNotExist, doesNowExist);
          }),
      MenuItem.separator(),
      MenuItem(
          label: favourite
              ? AppLocalizations.of(context).unlike
              : AppLocalizations.of(context).like,
          onClick: (menuItem) async {
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
            doesNowExist("");

            doesNowExist("");
          }),
    ],
  );
}
