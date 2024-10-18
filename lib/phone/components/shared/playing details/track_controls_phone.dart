import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'controls.dart';

class TrackControlsPhone extends StatelessWidget {
  final MediaItem currentMediaItem;
  final bool lyricsOn;
  final bool showQueue;
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
          ? -50 - 50
          : (size.height -
                      (size.width - 60) -
                      380 -
                      MediaQuery.of(context).padding.top) /
                  2 -
              70,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        pressedOpacity: 1,
        onPressed: () {},
        child: SizedBox(
          width: size.width,
          height: 400, //450, // 330
          child: /* Stack(
            children: [ */
              /*  Positioned(
                bottom: 0,
                child: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: x, sigmaY: x),
                    child: SizedBox(
                      width: size.width,
                      height: 50,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                child: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: x, sigmaY: x),
                    child: SizedBox(
                      width: size.width,
                      height: 100,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                child: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: x, sigmaY: x),
                    child: SizedBox(
                      width: size.width,
                      height: 150,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                child: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: x, sigmaY: x),
                    child: SizedBox(
                      width: size.width,
                      height: 200,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                child: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: x, sigmaY: x),
                    child: SizedBox(
                      width: size.width,
                      height: 250,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                child: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: x, sigmaY: x),
                    child: SizedBox(
                      width: size.width,
                      height: 300,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                child: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: x, sigmaY: x),
                    child: SizedBox(
                      width: size.width,
                      height: 350,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                child: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: x, sigmaY: x),
                    child: SizedBox(
                      width: size.width,
                      height: 400,
                    ),
                  ),
                ),
              ), */
              ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: x, sigmaY: x),
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
                              onTap: (_) {},
                            ),
                            const VolumeControlPhone(),
                            OtherControlsPhone(
                              lyricsOn: lyricsOn,
                              showQueue: showQueue,
                              trackId: currentMediaItem.id,
                              downloadTrack: () {},
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
