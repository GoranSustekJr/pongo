import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:pongo/shared/utils/API%20requests/download.dart';
import 'controls.dart';

class TrackControlsPhone extends StatelessWidget {
  final MediaItem currentMediaItem;
  final bool lyricsOn;
  final bool showQueue;
  final bool syncLyrics;
  final Function() changeLyricsOn;
  final Function() changeShowQueue;
  final Function(String) showAlbum;
  const TrackControlsPhone({
    super.key,
    required this.currentMediaItem,
    required this.lyricsOn,
    required this.changeLyricsOn,
    required this.showQueue,
    required this.changeShowQueue,
    required this.showAlbum,
    required this.syncLyrics,
  });

  @override
  Widget build(BuildContext context) {
    // double x = 1.5;
    double x = 7.5;
    Size size = MediaQuery.of(context).size;
    final audioServiceHandler =
        Provider.of<AudioHandler>(context) as AudioServiceHandler;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 750),
      curve: Curves.decelerate,
      bottom: lyricsOn || showQueue
          ? -50 - 50 - 30
          : (size.height -
                      (size.width - 60) -
                      380 -
                      MediaQuery.of(context).padding.top -
                      30) /
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
            gradient: lyricsOn && syncLyrics
                ? LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withAlpha(100),
                      Colors.black.withAlpha(100),
                      Colors.black.withAlpha(100),
                      Colors.black.withAlpha(100),
                      Colors.transparent,
                    ],
                  )
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                  sigmaX: lyricsOn && syncLyrics ? 0.1 : x,
                  sigmaY: lyricsOn && syncLyrics ? 0.1 : x),
              blendMode: BlendMode.src,
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
                              artist: currentMediaItem.artist!,
                              playbackState: playbackState,
                            ),
                            TrackProgressPhone(
                              album: currentMediaItem.album!,
                              released: currentMediaItem.extras!["released"]!,
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
                              showQueue: showQueue,
                              trackId: currentMediaItem.id,
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
          /*   ],
          ), */
        ),
      ),
    );
  }
}
