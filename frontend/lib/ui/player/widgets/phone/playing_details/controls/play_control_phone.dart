import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../../core/ui/phone/buttons/icon_button_forward.dart';
import '../../../../view_models/player_view_model.dart';

class PlayControlPhone extends StatefulWidget {
  final AsyncSnapshot<PlaybackState> playbackState;
  final MediaItem mediaItem;
  const PlayControlPhone({
    super.key,
    required this.mediaItem,
    required this.playbackState,
  });

  @override
  State<PlayControlPhone> createState() => _PlayControlPhoneState();
}

class _PlayControlPhoneState extends State<PlayControlPhone> {
  @override
  Widget build(BuildContext context) {
    final player = context.player;
    bool playing = false;
    if (widget.playbackState.data != null) {
      playing = widget.playbackState.data!.playing;
    }

    final Widget child = AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: animation, child: child),
        );
      },
      child: Icon(
        (playing) ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill,
        key: ValueKey<bool>(playing),
        size: 55,
        color: Colors.white,
      ),
    );

    return SizedBox(
      height: 55,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        mainAxisSize: MainAxisSize.max,
        children: [
          iconButtonForward(CupertinoIcons.backward_fill, () async {
            await player.skipToPrevious();
          }),
          SizedBox(
            height: 60,
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              onPressed: () async {
                if (playing) {
                  await player.pause();
                } else {
                  await player.play();
                }
              },
              child: child,
            ),
          ),
          iconButtonForward(CupertinoIcons.forward_fill, () async {
            await player.skipToNext();
          }),
        ],
      ),
    );
  }
}
