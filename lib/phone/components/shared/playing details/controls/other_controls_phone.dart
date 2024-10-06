import 'package:flutter/cupertino.dart';
import 'package:pongo/exports.dart';
import 'track_info_button.dart';

class OtherControlsPhone extends StatefulWidget {
  final bool lyricsOn;
  final bool showQueue;
  final String trackId;
  final Function() downloadTrack;
  final Function() changeLyricsOn;
  final Function() changeShowQueue;

  const OtherControlsPhone({
    super.key,
    required this.lyricsOn,
    required this.trackId,
    required this.downloadTrack,
    required this.changeLyricsOn,
    required this.showQueue,
    required this.changeShowQueue,
  });

  @override
  _OtherControlsPhoneState createState() => _OtherControlsPhoneState();
}

class _OtherControlsPhoneState extends State<OtherControlsPhone> {
  late Future<bool> favouriteStatusFuture;

  @override
  void initState() {
    super.initState();
    favouriteStatusFuture =
        DatabaseHelper().favouriteTrackAlreadyExists(widget.trackId);
  }

  void refreshFavouriteStatus() {
    setState(() {
      favouriteStatusFuture =
          DatabaseHelper().favouriteTrackAlreadyExists(widget.trackId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final audioServiceHandler =
        Provider.of<AudioHandler>(context) as AudioServiceHandler;
    return StreamBuilder(
      stream: audioServiceHandler.loopModeStream,
      builder: (context, loopMode) {
        return AnimatedOpacity(
          duration: const Duration(milliseconds: 450),
          opacity: widget.lyricsOn || widget.showQueue ? 0 : 1,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              iconButton(
                widget.lyricsOn ? AppIcons.lyricsFill : AppIcons.lyrics,
                Colors.white,
                widget.changeLyricsOn,
              ),
              iconButton(
                CupertinoIcons.repeat,
                audioServiceHandler.audioPlayer.loopMode.name != "all"
                    ? Colors.white.withAlpha(150)
                    : Colors.white,
                () {
                  if (audioServiceHandler.audioPlayer.loopMode.name == "all") {
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
              FutureBuilder<bool>(
                future: favouriteStatusFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Icon(CupertinoIcons.exclamationmark_circle),
                    );
                  } else {
                    bool isFavourite = snapshot.data ?? false;

                    return trackInfoButton(
                      context,
                      widget.trackId,
                      isFavourite,
                      widget.downloadTrack,
                      refreshFavouriteStatus,
                    );
                  }
                },
              ),
              iconButton(
                widget.showQueue
                    ? AppIcons.musicQueueFill
                    : AppIcons.musicQueue,
                Colors.white,
                () {
                  widget.changeShowQueue();
                  print(audioServiceHandler.audioPlayer.effectiveIndices);
                  print(audioServiceHandler.playlist.sequence);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
