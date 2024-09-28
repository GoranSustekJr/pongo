import 'package:flutter/cupertino.dart';
import 'package:pongo/exports.dart';
import 'package:spotify_api/spotify_api.dart' as sp;

List<Widget> recommendedTrackCupertinoContextMenuActions(
  BuildContext context,
  sp.Track track,
  String id,
  Function(String) doesNotExist,
  Function(String) doesNowExist,
) {
  return kIsApple
      ? [
          CupertinoContextMenuAction(
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop();
              // TODO: Add download function
            },
            trailingIcon: AppIcons.download,
            child: Text(
              AppLocalizations.of(context)!.download,
              maxLines: 1,
            ),
          ),
          //const PullDownMenuDivider(),
          CupertinoContextMenuAction(
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop();
              // TODO: Add download function
            },
            trailingIcon: AppIcons.musicAlbums,
            child: Text(
              AppLocalizations.of(context)!.addtoplaylist,
              maxLines: 1,
            ),
          ),
          const PullDownMenuDivider.large(),
          CupertinoContextMenuAction(
            onPressed: () async {
              await AddToQueue()
                  .addFirst(context, track, id, doesNotExist, doesNowExist);
              Navigator.of(context, rootNavigator: true).pop();
            },
            trailingIcon: AppIcons.firstToQueue,
            child: Text(
              AppLocalizations.of(context)!.firsttoqueue,
              maxLines: 1,
            ),
          ),
          //const PullDownMenuDivider(),
          CupertinoContextMenuAction(
            onPressed: () async {
              await AddToQueue()
                  .addLast(context, track, id, doesNotExist, doesNowExist);
              Navigator.of(context, rootNavigator: true).pop();
            },
            trailingIcon: AppIcons.lastToQueue,
            child: Text(
              AppLocalizations.of(context)!.lasttoqueue,
              maxLines: 1,
            ),
          ),
          const PullDownMenuDivider.large(),
          CupertinoContextMenuAction(
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop();
              // TODO: Add download function
            },
            trailingIcon: AppIcons.heart,
            child: Text(
              AppLocalizations.of(context)!.like,
              maxLines: 1,
            ),
          ),
        ]
      : [];
}
