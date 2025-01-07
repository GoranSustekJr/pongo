import 'package:pongo/exports.dart';

class TrackImagePhone extends StatelessWidget {
  final bool lyricsOn;
  final bool showQueue;
  final AudioServiceHandler audioServiceHandler;
  final String image;
  const TrackImagePhone({
    super.key,
    required this.lyricsOn,
    required this.image,
    required this.showQueue,
    required this.audioServiceHandler,
  });

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return AnimatedPositioned(
      duration: Duration(milliseconds: lyricsOn || showQueue ? 200 : 600),
      bottom: lyricsOn || showQueue
          ? size.height
          : size.height -
              (MediaQuery.of(context).padding.top + 30 + size.width - 60),
      curve: Curves.decelerate,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: size.width - 60,
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    switchInCurve: Curves.fastOutSlowIn,
                    switchOutCurve: Curves.fastEaseInToSlowEaseOut,
                    child: StreamBuilder<Object>(
                        key: ValueKey(image),
                        stream: audioServiceHandler.audioPlayer.playingStream,
                        builder: (context, snapshot) {
                          return Column(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  if (audioServiceHandler.audioPlayer.playing) {
                                    audioServiceHandler.pause();
                                  } else {
                                    audioServiceHandler.play();
                                  }
                                },
                                child: AnimatedScale(
                                  scale: audioServiceHandler.audioPlayer.playing
                                      ? 1.0
                                      : 0.85,
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.fastEaseInToSlowEaseOut,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: ColorFiltered(
                                      colorFilter: ColorFilter.mode(
                                        audioServiceHandler.audioPlayer.playing
                                            ? Colors.transparent
                                            : Colors.black.withAlpha(25),
                                        BlendMode.srcOver,
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(15),
                                        child: AnimatedOpacity(
                                          opacity:
                                              lyricsOn || showQueue ? 0 : 1,
                                          duration: const Duration(
                                              milliseconds: 1000),
                                          child: image != ""
                                              ? SizedBox(
                                                  height: size.width - 60,
                                                  width: size.width - 60,
                                                  child: ImageCompatible(
                                                    image: image,
                                                  ),
                                                )
                                              : SizedBox(
                                                  height: size.width - 60,
                                                  width: size.width - 60,
                                                  child: Center(
                                                    child: Icon(
                                                      AppIcons.blankTrack,
                                                      size: 50,
                                                    ),
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                          /*  }); */
                        }),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
