import 'package:pongo/exports.dart';
import 'package:spotify_api/spotify_api.dart' as sp;

List<PullDownMenuEntry> searchTrackPulldownMenuItems(
  BuildContext context,
  sp.Track track,
  String id,
  bool favourite,
  Function(String) doesNotExist,
  Function(String) doesNowExist,
) {
  return kIsApple
      ? [
          PullDownMenuItem(
            onTap: () {
              // TODO: Add download function
            },
            title: AppLocalizations.of(context)!.download,
            icon: AppIcons.download,
          ),
          const PullDownMenuDivider.large(),
          PullDownMenuItem(
            onTap: () {
              // TODO: Add download function
            },
            title: AppLocalizations.of(context)!.addtoplaylist,
            icon: AppIcons.musicAlbums,
            itemTheme: const PullDownMenuItemTheme(
              textStyle: TextStyle(
                overflow: TextOverflow.ellipsis,
                height: 1,
              ),
            ),
          ),
          const PullDownMenuDivider.large(),
          PullDownMenuItem(
            onTap: () async {
              await AddToQueue()
                  .addFirst(context, track, id, doesNotExist, doesNowExist);
            },
            title: AppLocalizations.of(context)!.firsttoqueue,
            icon: AppIcons.firstToQueue,
            itemTheme: const PullDownMenuItemTheme(
              textStyle: TextStyle(
                overflow: TextOverflow.ellipsis,
                height: 1,
              ),
            ),
          ),
          const PullDownMenuDivider(),
          PullDownMenuItem(
            onTap: () async {
              await AddToQueue()
                  .addLast(context, track, id, doesNotExist, doesNowExist);
            },
            title: AppLocalizations.of(context)!.lasttoqueue,
            icon: AppIcons.lastToQueue,
            itemTheme: const PullDownMenuItemTheme(
              textStyle: TextStyle(
                overflow: TextOverflow.ellipsis,
                height: 1,
              ),
            ),
          ),
          const PullDownMenuDivider(),
          PullDownMenuItem(
            onTap: () async {
              if (favourite) {
                await DatabaseHelper().removeFavouriteTrack(track.id);
                doesNotExist("");
              } else {
                await DatabaseHelper().insertFavouriteTrack(track.id);
                doesNowExist("");
              }
              // The UI will not auto-refresh since there is no stateful management here
              // You may need to manually update the parent widget's state
            },
            title: favourite
                ? AppLocalizations.of(context)!.unlike
                : AppLocalizations.of(context)!.like,
            icon: favourite ? AppIcons.heartFill : AppIcons.heart,
            itemTheme: const PullDownMenuItemTheme(
              textStyle: TextStyle(
                overflow: TextOverflow.ellipsis,
                height: 1,
              ),
            ),
          ),
        ]
      : [];
}
