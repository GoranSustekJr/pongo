import 'package:flutter/material.dart';
import 'package:flutter_desktop_context_menu/flutter_desktop_context_menu.dart';

import '../../../../domain/models/catalog/track.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/view_models/track_actions_view_model.dart';

Menu recommendedTrackPulldownMenuItemsDesktop(
  BuildContext context,
  Track track,
  String id,
  bool favourite,
) {
  return Menu(
    items: [
      MenuItem(
        label: AppLocalizations.of(context).download,
        onClick: (menuItem) async {
          await context.trackActions.download(track);
        },
      ),
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
          await context.trackActions.addNext(track, collectionId: id);
        },
      ),
      MenuItem(
        label: AppLocalizations.of(context).lasttoqueue,
        onClick: (menuItem) async {
          await context.trackActions.addLast(track, collectionId: id);
        },
      ),
      MenuItem.separator(),
      MenuItem(
        label: favourite
            ? AppLocalizations.of(context).unlike
            : AppLocalizations.of(context).like,
        onClick: (menuItem) async {
          await context.trackActions.toggleFavourite(track);
        },
      ),
    ],
  );
}
