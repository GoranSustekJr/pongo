import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'controls.dart';

class TrackControlsPhone extends StatelessWidget {
  final MediaItem currentMediaItem;
  final bool lyricsOn;
  final bool showQueue;
  final bool syncLyrics;
  final bool lyricsExist;
  final Function() changeLyricsOn;
  final Function() changeShowQueue;
  final Function(String) showAlbum;
  final Function(String) showArtist;
  const TrackControlsPhone({
    super.key,
    required this.currentMediaItem,
    required this.lyricsOn,
    required this.changeLyricsOn,
    required this.showQueue,
    required this.changeShowQueue,
    required this.showAlbum,
    required this.showArtist,
    required this.syncLyrics,
    required this.lyricsExist,
  });

  @override
  Widget build(BuildContext context) {
    // double x = 1.5;
    double x = 7.5;
    Size size = MediaQuery.of(context).size;
    final audioServiceHandler =
        Provider.of<AudioHandler>(context) as AudioServiceHandler;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 600),
      curve: Curves.decelerate,
      bottom: (lyricsOn && lyricsExist) || showQueue
          ? -50 - 50 - 30 - 50 + MediaQuery.of(context).viewPadding.bottom + 30
          : (size.height -
                      (size.width - 60) -
                      380 -
                      MediaQuery.of(context).padding.top -
                      30 -
                      15) /
                  2 -
              70,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        pressedOpacity: 1,
        onPressed: () {},
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          width: size.width,
          height: 400,
          decoration: BoxDecoration(
            gradient: ((lyricsOn && lyricsExist) && syncLyrics) ||
                    (showQueue && !useBlur.value)
                ? LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      if ((showQueue && !useBlur.value && !lyricsOn))
                        Col.realBackground.withAlpha(200),
                      if (lyricsOn && syncLyrics) Colors.black.withAlpha(100),
                      if ((showQueue && !useBlur.value && !lyricsOn))
                        Col.realBackground.withAlpha(200),
                      if (lyricsOn && syncLyrics) Colors.black.withAlpha(100),
                      if ((showQueue && !useBlur.value && !lyricsOn))
                        Col.realBackground.withAlpha(200),
                      if (lyricsOn && syncLyrics) Colors.black.withAlpha(100),
                      if ((showQueue && !useBlur.value && !lyricsOn))
                        Col.realBackground.withAlpha(200),
                      if (lyricsOn && syncLyrics) Colors.black.withAlpha(100),
                      if (showQueue && !useBlur.value && !lyricsOn)
                        Col.realBackground.withAlpha(50),
                      if (lyricsOn && syncLyrics) Colors.transparent,
                    ],
                  )
                : null,
          ),
          child: Stack(
            children: [
              AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: showQueue ? 1 : 0,
                child: LiquidGlass(
                    blur: kIsApple ? AppConstants().liquidGlassBlur : 0,
                    opacity: kIsApple ? 0.2 : 0,
                    tint: kIsApple
                        ? ((lyricsOn && lyricsExist) && syncLyrics)
                            ? Col.transp
                            : Colors.white
                        : Col.transp,
                    borderRadius: kIsApple
                        ? const BorderRadius.all(Radius.circular(28))
                        : BorderRadius.zero,
                    child: Container()),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                      sigmaX: kIsApple
                          ? 0
                          : ((lyricsOn && lyricsExist) && syncLyrics) ||
                                  !useBlur.value
                              ? 0.1
                              : x,
                      sigmaY: kIsApple
                          ? 0
                          : ((lyricsOn && lyricsExist) && syncLyrics) ||
                                  !useBlur.value
                              ? 0.1
                              : x),
                  //blendMode: BlendMode.src,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 15,
                      right: 15,
                      top: 10,
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      switchInCurve: Curves.fastOutSlowIn,
                      switchOutCurve: Curves.fastEaseInToSlowEaseOut,
                      child: StreamBuilder(
                          key: ValueKey(currentMediaItem.id),
                          stream: audioServiceHandler.playbackState,
                          builder: (context, playbackState) {
                            return Column(
                              children: [
                                // razh(50),
                                TitleArtistVisualizerPhone(
                                  name: currentMediaItem.title,
                                  stid: currentMediaItem.id.split('.')[2],
                                  artistJson:
                                      currentMediaItem.extras!["artists"],
                                  playbackState: playbackState,
                                  smallImage:
                                      (lyricsOn && lyricsExist) || showQueue,
                                  mix: currentMediaItem.extras!["mix"] ??
                                      false ||
                                          RegExp(r'Mix #\d{1,2}')
                                              .hasMatch(currentMediaItem.title),
                                  showArtist: showArtist,
                                ),
                                TrackProgressPhone(
                                  album: currentMediaItem.album!,
                                  albumId: currentMediaItem.extras!["album"]
                                      .split("..Ææ..")[0],
                                  duration: currentMediaItem.duration,
                                  showAlbum: showAlbum,
                                ),
                                PlayControlPhone(
                                  mediaItem: currentMediaItem,
                                  playbackState: playbackState,
                                ),
                                const VolumeControlPhone(),
                                OtherControlsPhone(
                                  lyricsOn: lyricsOn,
                                  lyricsExist: lyricsExist,
                                  showQueue: showQueue,
                                  track: Track(
                                    id: currentMediaItem.id,
                                    name: currentMediaItem.title,
                                    artists: (jsonDecode(currentMediaItem
                                            .extras!["artists"]) as List)
                                        .map((artistMap) => ArtistTrack.fromMap(
                                            artistMap as Map<String, dynamic>))
                                        .toList(),
                                    album: currentMediaItem.album != null
                                        ? AlbumTrack(
                                            id: currentMediaItem.album!,
                                            name: currentMediaItem
                                                .extras!["album"]
                                                .split('..Ææ..')[1],
                                            releaseDate: currentMediaItem
                                                .extras!["released"],
                                            images: currentMediaItem.artUri !=
                                                    null
                                                ? [
                                                    AlbumImagesTrack(
                                                        url: currentMediaItem
                                                            .artUri!
                                                            .toString(),
                                                        height: null,
                                                        width: null)
                                                  ]
                                                : [],
                                          )
                                        : null,
                                  ),
                                  downloadTrack: () async {
                                    await Download().single(currentMediaItem);
                                  },
                                  changeLyricsOn: changeLyricsOn,
                                  changeShowQueue: changeShowQueue,
                                ),
                              ],
                            );
                          }),
                    ),
                  ),
                ),
              ),
            ],
          ),
          /*   ],
          ), */
        ),
      ),
    );
  }
}
