import 'package:flutter/cupertino.dart';
import 'package:pongo/exports.dart';

class PlayPauseMini extends StatefulWidget {
  final AsyncSnapshot<PlaybackState> playbackState;
  final Function() function;
  const PlayPauseMini(
      {super.key, required this.function, required this.playbackState});

  @override
  State<PlayPauseMini> createState() => _PlayPauseMiniState();
}

class _PlayPauseMiniState extends State<PlayPauseMini> {
  @override
  Widget build(BuildContext context) {
    bool playing = false;
    if (widget.playbackState.data != null) {
      playing = widget.playbackState.data!.playing;
    }
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: widget.function,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: animation,
              child: child,
            ),
          );
        },
        child: playing
            ? const Icon(
                CupertinoIcons.pause_fill,
                key: ValueKey(true),
                size: 30,
                color: Colors.white,
              )
            : const Icon(
                CupertinoIcons.play_fill,
                key: ValueKey(false),
                size: 30,
                color: Colors.white,
              ),
      ),
    );
  }
}
/* playPauseMini(bool playing, Function() function) {
  return 
}
 */
