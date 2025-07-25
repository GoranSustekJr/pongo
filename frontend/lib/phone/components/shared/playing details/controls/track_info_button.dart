import 'package:flutter/cupertino.dart';
import 'package:pongo/exports.dart';

trackInfoButton(context, Track track, bool favourite, Function() download,
    Function() refreshFavourite) {
  return /* kIsApple
      ?  */
      PullDownButton(
    itemBuilder: (context) => [
      PullDownMenuItem(
        title: AppLocalizations.of(context).download,
        icon: CupertinoIcons.cloud_download,
        onTap: () {
          download();
        },
      ),
      const PullDownMenuDivider(),
      PullDownMenuItem(
        title: AppLocalizations.of(context).addtoplaylist,
        icon: AppIcons.musicAlbums,
        onTap: () {
          final audioServiceHandler =
              Provider.of<AudioHandler>(context, listen: false)
                  as AudioServiceHandler;
          final MediaItem? mediaItem = audioServiceHandler.mediaItem.value;
          if (mediaItem != null) {
            OpenPlaylist().show(
              context,
              PlaylistHandler(
                type: PlaylistHandlerType.online,
                function: PlaylistHandlerFunction.addToPlaylist,
                track: [
                  PlaylistHandlerOnlineTrack(
                    id: mediaItem.id.split('.')[2],
                    name: mediaItem.title,
                    artist: mediaItem.artist != null
                        ? (jsonDecode(mediaItem.extras!["artists"]) as List)
                            .map((e) => e as Map<String, dynamic>)
                            .toList()
                        : [],
                    cover: mediaItem.artUri.toString(),
                    albumTrack: mediaItem.album != null
                        ? AlbumTrack(
                            id: mediaItem.extras!["album"].split("..Ææ..")[0],
                            name: mediaItem.album!,
                            releaseDate: mediaItem.extras!["released"],
                            images: mediaItem.artUri != null
                                ? [
                                    AlbumImagesTrack(
                                        url: mediaItem.artUri!.toString(),
                                        height: null,
                                        width: null)
                                  ]
                                : [],
                          )
                        : null,
                    playlistHandlerCoverType:
                        !mediaItem.artUri.toString().contains('file:///')
                            ? PlaylistHandlerCoverType.url
                            : PlaylistHandlerCoverType.bytes,
                  )
                ],
              ),
            );
          }
        },
      ),
      const PullDownMenuDivider.large(),
      PullDownMenuItem(
        title: favourite
            ? AppLocalizations.of(context).unlike
            : AppLocalizations.of(context).like,
        icon: favourite ? AppIcons.heartFill : AppIcons.heart,
        onTap: () async {
          await Favourites().add(
              context,
              Favourite(
                id: -1,
                stid: track.id.split('.')[2],
                title: track.name,
                artistTrack: track.artists,
                albumTrack: track.album,
                image: track.album != null
                    ? calculateBestImageForTrack(track.album!.images)
                    : null,
              ));
          refreshFavourite();
        },
      ),
      const PullDownMenuDivider.large(),
      PullDownMenuItem(
        onTap: () async {
          CustomButton ok = await haltAlert(context);
          if (ok == CustomButton.positiveButton) {
            currentTrackHeight.value = 0;
            final audioServiceHandler =
                Provider.of<AudioHandler>(context, listen: false)
                    as AudioServiceHandler;

            await audioServiceHandler.halt();
          }
        },
        title: AppLocalizations.of(context).halt,
        icon: AppIcons.halt,
        itemTheme: const PullDownMenuItemTheme(
          textStyle: TextStyle(
            overflow: TextOverflow.ellipsis,
            height: 1,
          ),
        ),
      ),
    ],
    position: PullDownMenuPosition.above,
    buttonBuilder: (context, showMenu) => iconButton(
      AppIcons.more,
      Colors.white,
      showMenu,
      edgeInsets: EdgeInsets.zero,
    ),
  );
  /* : SizedBox(
          key: key,
          width: 50,
          height: 50,
          child: IconButton(
            splashColor: Col.primary,
            icon: const Icon(AppIcons.more),
            onPressed: () {
              PopupMenu(
                context: context,
                config: MenuConfig(
                  itemWidth: 150,
                  backgroundColor: Col.primaryCard,
                  lineColor: Colors.greenAccent,
                  highlightColor: Colors.lightGreenAccent,
                  type: MenuType.list,
                ),
                items: [
                  PopUpMenuItem(
                      title: AppLocalizations.of(context).download,
                      image: const Icon(
                        AppIcons.download,
                        color: Colors.white,
                      )),
                  PopUpMenuItem(
                      title: AppLocalizations.of(context).addtoplaylist,
                      image: const Icon(
                        AppIcons.musicAlbums,
                        color: Colors.white,
                      )),
                  PopUpMenuItem(
                    title: "",
                    image: Row(
                      children: [
                        Text(AppLocalizations.of(context).like),
                        Icon(
                          favourite ? AppIcons.heartFill : AppIcons.heart,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ).show(widgetKey: key);
            },
          ),
        ); */
}
