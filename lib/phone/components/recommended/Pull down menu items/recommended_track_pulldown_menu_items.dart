import 'package:flutter/cupertino.dart';
import 'package:pongo/exports.dart';
import 'package:pongo/shared/functions/favourites/favourites.dart';
import 'package:pongo/shared/functions/open%20playlist/open_playlist.dart';
import 'package:spotify_api/spotify_api.dart' as sp;

List<Widget> recommendedTrackCupertinoContextMenuActions(
  BuildContext context,
  Track track,
  String id,
  Function(String) doesNotExist,
  Function(String) doesNowExist,
) {
  print(track.artists[0].name);
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
          // Add to Playlist
          CupertinoContextMenuAction(
            onPressed: () {
              print("DFHFAKJFHADK");
              OpenPlaylist().open(
                context,
                id: track.id,
                cover: calculateWantedResolutionForTrack(
                    track.album != null
                        ? track.album!.images
                        : track.album!.images,
                    55,
                    55),
                title: track.name,
                artist: track.artists
                    .map((artist) => artist.name)
                    .toList()
                    .join(', '),
              );
              Navigator.of(context, rootNavigator: true).pop();
              // TODO: Add playlist function
            },
            trailingIcon: AppIcons.musicAlbums,
            child: Text(
              AppLocalizations.of(context)!.addtoplaylist,
              maxLines: 1,
            ),
          ),
          const PullDownMenuDivider.large(),
          // Add First to Queue
          CupertinoContextMenuAction(
            onPressed: () async {
              await AddToQueue().addTypeTrackFirst(
                  context, track, id, doesNotExist, doesNowExist);
              Navigator.of(context, rootNavigator: true).pop();
            },
            trailingIcon: AppIcons.firstToQueue,
            child: Text(
              AppLocalizations.of(context)!.firsttoqueue,
              maxLines: 1,
            ),
          ),
          // Add Last to Queue
          CupertinoContextMenuAction(
            onPressed: () async {
              await AddToQueue().addTypeTrackLast(
                  context, track, id, doesNotExist, doesNowExist);
              Navigator.of(context, rootNavigator: true).pop();
            },
            trailingIcon: AppIcons.lastToQueue,
            child: Text(
              AppLocalizations.of(context)!.lasttoqueue,
              maxLines: 1,
            ),
          ),
          const PullDownMenuDivider.large(),
          FutureBuilder<bool>(
            future: DatabaseHelper().favouriteTrackAlreadyExists(track.id),
            builder: (context, snapshot) {
              final isFavorite = snapshot.data ?? false;

              if (snapshot.connectionState == ConnectionState.waiting) {
                return CupertinoContextMenuAction(
                  onPressed: () {},
                  trailingIcon: AppIcons.heart,
                  child: Text(
                    AppLocalizations.of(context)!.like,
                    maxLines: 1,
                  ),
                );
              }

              return CupertinoContextMenuAction(
                onPressed: () async {
                  await Favourites().add(context, track.id);
                  doesNowExist("");

                  doesNowExist("");

                  Navigator.of(context, rootNavigator: true).pop();
                },
                trailingIcon: isFavorite ? AppIcons.heartFill : AppIcons.heart,
                child: Text(
                  isFavorite
                      ? AppLocalizations.of(context)!.unlike
                      : AppLocalizations.of(context)!.like,
                  maxLines: 1,
                ),
              );
            },
          ),
        ]
      : [];
}
