import 'package:pongo/exports.dart';

List<PullDownMenuEntry> searchTrackPulldownMenuItemsApple(
  BuildContext context,
  Track track,
  String id,
  bool favourite,
  Function(String) doesNotExist,
  Function(String) doesNowExist,
) {
  return [
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
                      .map((artist) => {"id": artist.id, "name": artist.name})
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
        await AddToQueue()
            .addTypeTrackFirst(context, track, id, doesNotExist, doesNowExist);
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
        await AddToQueue()
            .addTypeTrackLast(context, track, id, doesNotExist, doesNowExist);
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
  ];
}

// Android
List<Widget> searchTrackPulldownMenuItemsAndroid(
  BuildContext context,
  Track track,
  String id,
  bool favourite,
  Function(String) doesNotExist,
  Function(String) doesNowExist,
) {
  TextStyle textStyle = TextStyle(
      overflow: TextOverflow.ellipsis,
      color: Col.text,
      fontSize: 18,
      fontWeight: FontWeight.w400);
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
                color: Col.text,
                size: 18,
              )
            ],
          ),
        ),
        () async {
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
          StarMenuOverlay.dispose();

          // The UI will not auto-refresh since there is no stateful management here
        },
      ),
    ),

    Container(
      width: 200,
      height: 5,
      color: Col.onIcon,
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
                AppLocalizations.of(context).lasttoqueue,
                style: textStyle,
                maxLines: 1,
              ),
            ),
            Icon(
              AppIcons.lastToQueue,
              color: Col.text,
              size: 18,
            )
          ],
        ),
      ),
      () async {
        await AddToQueue()
            .addTypeTrackLast(context, track, id, doesNotExist, doesNowExist);
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
            Icon(
              AppIcons.firstToQueue,
              color: Col.text,
              size: 18,
            )
          ],
        ),
      ),
      () async {
        await AddToQueue()
            .addTypeTrackFirst(context, track, id, doesNotExist, doesNowExist);
        StarMenuOverlay.dispose();
      },
    ),

    Container(
      width: 200,
      height: 5,
      color: Col.onIcon,
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
                AppLocalizations.of(context).addtoplaylist,
                style: textStyle,
                maxLines: 1,
              ),
            ),
            Icon(
              AppIcons.musicAlbums,
              color: Col.text,
              size: 18,
            )
          ],
        ),
      ),
      () {
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
                      .map((artist) => {"id": artist.id, "name": artist.name})
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
              Icon(
                AppIcons.download,
                color: Col.text,
                size: 18,
              )
            ],
          ),
        ),
        () async {
          await Download().single(track);
          StarMenuOverlay.dispose();
        },
      ),
    ),
  ];
}
