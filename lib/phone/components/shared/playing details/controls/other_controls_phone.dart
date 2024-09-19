import 'package:flutter/cupertino.dart';
import 'package:pongo/exports.dart';

import 'track_info_button.dart';

class OtherControlsPhone extends StatelessWidget {
  final bool lyricsOn;
  final bool showQueue;
  final String trackId;
  final Function() downloadTrack;
  final Function() changeLyricsOn;
  final Function() changeShowQueue;
  const OtherControlsPhone(
      {super.key,
      required this.lyricsOn,
      required this.trackId,
      required this.downloadTrack,
      required this.changeLyricsOn,
      required this.showQueue,
      required this.changeShowQueue});

  @override
  Widget build(BuildContext context) {
    final audioServiceHandler =
        Provider.of<AudioHandler>(context) as AudioServiceHandler;
    return StreamBuilder(
        stream: audioServiceHandler.loopModeStream,
        builder: (context, loopMode) {
          return AnimatedOpacity(
            duration: const Duration(milliseconds: 450),
            opacity: lyricsOn || showQueue ? 0 : 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                iconButton(lyricsOn ? AppIcons.lyricsFill : AppIcons.lyrics,
                    Colors.white, changeLyricsOn),
                iconButton(
                  CupertinoIcons.repeat,
                  audioServiceHandler.audioPlayer.loopMode.name != "all"
                      ? Colors.white.withAlpha(150)
                      : Colors.white,
                  () {
                    if (audioServiceHandler.audioPlayer.loopMode.name ==
                        "all") {
                      audioServiceHandler
                          .setRepeatMode(AudioServiceRepeatMode.none);
                    } else if (audioServiceHandler.audioPlayer.loopMode.name ==
                        "off") {
                      audioServiceHandler
                          .setRepeatMode(AudioServiceRepeatMode.all);
                    }
                    print(audioServiceHandler.audioPlayer.loopMode.name);
                  },
                ),
                trackInfoButton(
                  context,
                  trackId,
                  downloadTrack,
                ),
                iconButton(
                  showQueue ? AppIcons.musicQueueFill : AppIcons.musicQueue,
                  Colors.white,
                  () {
                    changeShowQueue();
                    final audioServiceHandler =
                        Provider.of<AudioHandler>(context, listen: false)
                            as AudioServiceHandler;

                    print(audioServiceHandler.audioPlayer.effectiveIndices);
                    print(audioServiceHandler.playlist.sequence);
                  },
                ),
              ],
            ),
          );
        });
  }
}
