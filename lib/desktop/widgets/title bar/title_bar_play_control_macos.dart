import 'package:flutter/cupertino.dart';
import 'package:pongo/desktop/widgets/play_pause_mini.dart';
import '../../../exports.dart';

class TitleBarPlayControlMacos extends StatelessWidget {
  final MediaItem currentMediaItem;
  final Function() play;
  const TitleBarPlayControlMacos(
      {super.key, required this.currentMediaItem, required this.play});

  @override
  Widget build(BuildContext context) {
    final audioServiceHandler =
        Provider.of<AudioHandler>(context) as AudioServiceHandler;
    return Row(
      children: [
        StreamBuilder(
            stream: audioServiceHandler.loopModeStream,
            builder: (context, loopMode) {
              return CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  if (audioServiceHandler.activeSleepAlarm == -1) {
                    if (audioServiceHandler.audioPlayer.loopMode.name ==
                        "all") {
                      audioServiceHandler
                          .setRepeatMode(AudioServiceRepeatMode.none);
                    } else if (audioServiceHandler.audioPlayer.loopMode.name ==
                        "off") {
                      audioServiceHandler
                          .setRepeatMode(AudioServiceRepeatMode.one);
                    } else {
                      audioServiceHandler
                          .setRepeatMode(AudioServiceRepeatMode.all);
                    }
                  } else {
                    Notifications().showWarningNotification(
                        notificationsContext.value!,
                        AppLocalizations.of(notificationsContext.value!)!
                            .sleepalarmisenabled);
                  }
                },
                child: Icon(
                  audioServiceHandler.audioPlayer.loopMode.name == "one"
                      ? AppIcons.repeatOne
                      : AppIcons.repeat,
                  color: audioServiceHandler.audioPlayer.loopMode.name == "off"
                      ? Colors.white.withAlpha(150)
                      : Colors.white,
                  size: 17,
                ),
              );
            }),
        iconButtonForward(
          CupertinoIcons.backward_fill,
          () async {
            await audioServiceHandler.skipToPrevious();
          },
          height: 25,
        ),
        playPauseMini(
          audioServiceHandler.audioPlayer.playing,
          () {
            play();
          },
        ),
        iconButtonForward(
          CupertinoIcons.forward_fill,
          () async {
            await audioServiceHandler.skipToNext();
          },
          height: 25,
        ),
        MacosPulldownButton(
          itemHeight: 30,
          icon: CupertinoIcons.ellipsis_circle,
          items: [
            MacosPulldownMenuItem(
              title: SizedBox(
                width: 150,
                height: 70,
                child: Row(
                  children: [
                    MacosIcon(
                      AppIcons.download,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.download,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1, // Ensure single line with ellipsis
                      ),
                    ),
                  ],
                ),
              ),
              onTap: () => debugPrint('Tags...'),
            ),
            const MacosPulldownMenuDivider(),
            MacosPulldownMenuItem(
              title: SizedBox(
                width: 150,
                child: Row(
                  children: [
                    const MacosIcon(
                      AppIcons.musicAlbums,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.addtoplaylist,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
              onTap: () => debugPrint('Tags...'),
            ),
            const MacosPulldownMenuDivider(),
            MacosPulldownMenuItem(
              title: FutureBuilder(
                  future: DatabaseHelper().favouriteTrackAlreadyExists(
                      currentMediaItem.id.split('.')[2]),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(
                        child: Icon(CupertinoIcons.exclamationmark_circle),
                      );
                    } else {
                      bool isFavourite = snapshot.data ?? false;

                      return SizedBox(
                        width: 150,
                        child: Row(
                          children: [
                            MacosIcon(
                              isFavourite ? AppIcons.heartFill : AppIcons.heart,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                isFavourite
                                    ? AppLocalizations.of(context)!.unlike
                                    : AppLocalizations.of(context)!.like,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  }),
              onTap: () async {
                await Favourites().add(
                    context,
                    Favourite(
                      id: -1,
                      stid: currentMediaItem.id.split('.')[2],
                      title: currentMediaItem.title,
                      artistTrack: (jsonDecode(
                                  currentMediaItem.extras?["artists"])
                              as List<dynamic>)
                          .map((artistJson) => ArtistTrack.fromMap(artistJson))
                          .toList(),
                      albumTrack: currentMediaItem.album != null
                          ? AlbumTrack(
                              id: currentMediaItem.album!.split('..Ææ..')[0],
                              name: currentMediaItem.album!.split('..Ææ..')[0],
                              images: [
                                AlbumImagesTrack(
                                    url: currentMediaItem.artUri.toString(),
                                    height: null,
                                    width: null)
                              ],
                              releaseDate: currentMediaItem.extras?["released"],
                            )
                          : null,
                      image: currentMediaItem.artUri.toString(),
                    ));
              },
            ),
          ],
        ),
      ],
    );
  }
}
