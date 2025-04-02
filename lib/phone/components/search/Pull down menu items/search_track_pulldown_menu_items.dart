import 'package:pongo/exports.dart';

List<PullDownMenuEntry> searchTrackPulldownMenuItems(
  BuildContext context,
  Track track,
  String id,
  bool favourite,
  Function(String) doesNotExist,
  Function(String) doesNowExist,
) {
  return kIsApple
      ? [
          PullDownMenuItem(
            onTap: () async {
              await Download().single(track);
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
                    track: [
                      PlaylistHandlerOnlineTrack(
                        id: track.id,
                        name: track.name,
                        artist: track.artists
                            .map((artist) =>
                                {"id": artist.id, "name": artist.name})
                            .toList(),
                        cover: calculateWantedResolutionForTrack(
                            track.album != null
                                ? track.album!.images
                                : track.album!.images,
                            150,
                            150),
                        albumTrack: track.album,
                        playlistHandlerCoverType: PlaylistHandlerCoverType.url,
                      )
                    ],
                  ));
            },
            title: AppLocalizations.of(context).addtoplaylist,
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
              await AddToQueue().addTypeTrackFirst(
                  context, track, id, doesNotExist, doesNowExist);
            },
            title: AppLocalizations.of(context).firsttoqueue,
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
              await AddToQueue().addTypeTrackLast(
                  context, track, id, doesNotExist, doesNowExist);
            },
            title: AppLocalizations.of(context).lasttoqueue,
            icon: AppIcons.lastToQueue,
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
            title: favourite
                ? AppLocalizations.of(context).unlike
                : AppLocalizations.of(context).like,
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
