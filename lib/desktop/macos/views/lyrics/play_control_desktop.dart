import 'package:flutter/cupertino.dart';
import 'package:pongo/phone/alerts/audio%20player/queue_alert.dart';
import '../../../../exports.dart';

class PlayControl extends StatefulWidget {
  final AsyncSnapshot<PlaybackState> playbackState;
  final MediaItem mediaItem;
  final Function(bool) onTap;
  final bool thisTrackPlaying;
  const PlayControl({
    super.key,
    required this.mediaItem,
    required this.onTap,
    required this.thisTrackPlaying,
    required this.playbackState,
  });

  @override
  State<PlayControl> createState() => _PlayControlState();
}

class _PlayControlState extends State<PlayControl> {
  @override
  Widget build(BuildContext context) {
    final audioServiceHandler =
        Provider.of<AudioHandler>(context) as AudioServiceHandler;
    bool playing = false;
    if (widget.playbackState.data != null) {
      playing = widget.playbackState.data!.playing;
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      mainAxisSize: MainAxisSize.max,
      children: [
        iconButtonForward(
          CupertinoIcons.backward_fill,
          () async {
            audioServiceHandler.skipToPrevious();
          },
        ),
        SizedBox(
          height: 60,
          child: CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            onPressed: () async {
              if (playing) {
                audioServiceHandler.pause();
              } else {
                audioServiceHandler.play();
              }
            },
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: animation,
                    child: child,
                  ),
                );
              },
              child: Icon(
                (playing)
                    ? CupertinoIcons.pause_fill
                    : CupertinoIcons.play_fill,
                key: ValueKey<bool>(playing),
                size: 55,
                color: Colors.white,
              ),
            ),
          ),
        ),
        iconButtonForward(
          CupertinoIcons.forward_fill,
          () async {
            audioServiceHandler.skipToNext();
          },
        ),
      ],
    );
  }
}
