// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/cupertino.dart';
import 'package:pongo/exports.dart';
import 'track_info_button.dart';

class OtherControlsPhone extends StatefulWidget {
  final bool lyricsOn;
  final bool showQueue;
  final Track track;
  final Function() downloadTrack;
  final Function() changeLyricsOn;
  final Function() changeShowQueue;

  const OtherControlsPhone({
    super.key,
    required this.lyricsOn,
    required this.track,
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
    favouriteStatusFuture = DatabaseHelper()
        .favouriteTrackAlreadyExists(widget.track.id.split('.')[2]);
  }

  void refreshFavouriteStatus() {
    setState(() {
      favouriteStatusFuture = DatabaseHelper()
          .favouriteTrackAlreadyExists(widget.track.id.split('.')[2]);
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
                audioServiceHandler.audioPlayer.loopMode.name == "one"
                    ? AppIcons.repeatOne
                    : AppIcons.repeat,
                audioServiceHandler.audioPlayer.loopMode.name == "off"
                    ? Colors.white.withAlpha(150)
                    : Colors.white,
                () {
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
                        AppLocalizations.of(notificationsContext.value!)
                            .sleepalarmisenabled);
                  }
                },
              ),
              FutureBuilder<bool>(
                future: DatabaseHelper()
                    .favouriteTrackAlreadyExists(widget.track.id.split('.')[2]),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Icon(CupertinoIcons.exclamationmark_circle),
                    );
                  } else {
                    bool isFavourite = snapshot.data ?? false;

                    return trackInfoButton(
                      context,
                      widget.track,
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
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
