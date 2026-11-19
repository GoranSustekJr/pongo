import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../../../core/themes/colors.dart';
import '../../../../player/view_models/player_view_model.dart';
import 'title_bar_other_control_macos.dart';
import 'title_bar_play_control_macos.dart';
import 'title_bar_title_macos.dart';

TitleBar titleBarMacos(
  BuildContext context,
  PlayerViewModel player,
  bool queue,
  Function() showQueue,
) {
  return TitleBar(
    height: 60,
    decoration: const BoxDecoration(color: Col.transp),
    padding: const EdgeInsets.symmetric(vertical: 7.5),
    title: StreamBuilder(
      stream: player.playbackState,
      builder: (context, AsyncSnapshot<PlaybackState> playbackState) {
        return StreamBuilder(
          stream: player.currentItemStream,
          builder: (context, AsyncSnapshot<MediaItem?> snapshot) {
            // Function to handle play/pause actions
            void play() {
              if (playbackState.data?.playing ?? false) {
                player.pause();
              } else {
                player.play();
              }
            }

            // Get the current media item
            final currentMediaItem = snapshot.data;

            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: currentMediaItem == null || playbackState.data == null
                  ? Container()
                  : ClipRRect(
                      key: ValueKey(currentMediaItem.id),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          TitleBarMacos(
                            currentMediaItem: currentMediaItem,
                            queue: queue,
                            showQueue: showQueue,
                          ),
                          Expanded(child: Container()),
                          TitleBarTitleMacos(
                            currentMediaItem: currentMediaItem,
                          ),
                          Expanded(child: Container()),
                          TitleBarPlayControlMacos(
                            currentMediaItem: currentMediaItem,
                            play: play,
                          ),
                        ],
                      ),
                    ),
            );
          },
        );
      },
    ),
  );
}
