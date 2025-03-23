import 'package:pongo/desktop/widgets/title%20bar/title_bar_other_control_macos.dart';
import 'package:pongo/desktop/widgets/title%20bar/title_bar_play_control_macos.dart';
import 'package:pongo/desktop/widgets/title%20bar/title_bar_title_macos.dart';
import 'package:pongo/exports.dart';

TitleBar titleBarMacos(BuildContext context,
    AudioServiceHandler audioServiceHandler, bool queue, Function() showQueue) {
  return TitleBar(
    height: 60,
    decoration: const BoxDecoration(color: Col.transp),
    padding: const EdgeInsets.symmetric(vertical: 7.5),
    title: StreamBuilder(
        stream: audioServiceHandler.playbackState.stream,
        builder: (context, AsyncSnapshot<PlaybackState> playbackState) {
          return StreamBuilder(
            stream: audioServiceHandler.mediaItem.stream,
            builder: (context, AsyncSnapshot<MediaItem?> snapshot) {
              // Function to handle play/pause actions
              play() {
                if (playbackState.data?.playing ?? false) {
                  audioServiceHandler.pause();
                } else {
                  audioServiceHandler.play();
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
                                showQueue: showQueue),
                            Expanded(
                              child: Container(),
                            ),
                            TitleBarTitleMacos(
                                currentMediaItem: currentMediaItem),
                            Expanded(
                              child: Container(),
                            ),
                            TitleBarPlayControlMacos(
                                currentMediaItem: currentMediaItem, play: play),
                          ],
                        ),
                      ),
              );
            },
          );
        }),
  );
}
