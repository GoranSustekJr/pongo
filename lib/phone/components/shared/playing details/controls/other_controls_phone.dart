import 'package:flutter/cupertino.dart';
import 'package:pongo/exports.dart';

import 'track_info_button.dart';

class OtherControlsPhone extends StatelessWidget {
  final bool lyricsOn;
  final String trackId;
  final Function() downloadTrack;
  const OtherControlsPhone(
      {super.key,
      required this.lyricsOn,
      required this.trackId,
      required this.downloadTrack});

  @override
  Widget build(BuildContext context) {
    final audioServiceHandler =
        Provider.of<AudioHandler>(context) as AudioServiceHandler;
    return StreamBuilder(
        stream: audioServiceHandler.loopModeStream,
        builder: (context, loopMode) {
          return AnimatedOpacity(
            duration: const Duration(milliseconds: 450),
            opacity: lyricsOn ? 0 : 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                iconButton(
                  audioServiceHandler.audioPlayer.loopMode.name == "one"
                      ? CupertinoIcons.repeat_1
                      : CupertinoIcons.repeat,
                  audioServiceHandler.audioPlayer.loopMode.name != "all" &&
                          audioServiceHandler.audioPlayer.loopMode.name != "one"
                      ? Colors.white.withAlpha(150)
                      : Colors.white,
                  () {
                    if (audioServiceHandler.audioPlayer.loopMode.name ==
                        "one") {
                      audioServiceHandler
                          .setRepeatMode(AudioServiceRepeatMode.all);
                    } else if (audioServiceHandler.audioPlayer.loopMode.name ==
                        "all") {
                      audioServiceHandler
                          .setRepeatMode(AudioServiceRepeatMode.none);
                    } else if (audioServiceHandler.audioPlayer.loopMode.name ==
                        "off") {
                      audioServiceHandler
                          .setRepeatMode(AudioServiceRepeatMode.one);
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
                  AppIcons.musicQueue,
                  Colors.white,
                  () {
                    /* showModalBottomSheet(
                        backgroundColor: Col.transp,
                        isScrollControlled: true,
                        context: context,
                        builder: (context) => QueuePhone()); */
                  },
                ),
              ],
            ),
          );
        });
  }
}
