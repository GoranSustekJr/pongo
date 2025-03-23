import 'package:pongo/desktop/macos/views/lyrics/lyrics_body_macos.dart';
import 'package:pongo/exports.dart';

class LyricsMacos extends StatefulWidget {
  const LyricsMacos({super.key});

  @override
  State<LyricsMacos> createState() => _LyricsMacosState();
}

class _LyricsMacosState extends State<LyricsMacos> {
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return ChangeNotifierProvider(
      create: (_) => MediaItemManager(
        Provider.of<AudioHandler>(context, listen: false)
            as AudioServiceHandler,
        context,
      ),
      child: Consumer<MediaItemManager>(
        builder: (context, mediaItemManager, child) {
          return mediaItemManager.currentMediaItem != null
              ? ValueListenableBuilder(
                  valueListenable: currentTrackHeight,
                  builder: (context, index, child) {
                    return MacosScaffold(
                      children: [
                        ContentArea(
                          builder: (context, scrollController) {
                            return StreamBuilder(
                                stream: mediaItemManager
                                    .audioServiceHandler.mediaItem.stream,
                                builder: (context, streamMediaItem) {
                                  return SizedBox(
                                    height: size.height,
                                    width: size.width - 180,
                                    child: AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 400),
                                      child: Stack(
                                        children: [
                                          Blurhash(
                                            sigmaX: 0,
                                            sigmaY: 0,
                                            blurhash: mediaItemManager.blurhash,
                                            child: const SizedBox(),
                                          ),
                                          Container(
                                            color: Colors.black.withAlpha(65),
                                            child: AnimatedSwitcher(
                                              duration: const Duration(
                                                  milliseconds: 400),
                                              child: Align(
                                                key: ValueKey<dynamic>(
                                                    mediaItemManager
                                                        .currentMediaItem),
                                                alignment: Alignment.topLeft,
                                                child: LyricsBodyMacos(
                                                  mediaItem: mediaItemManager
                                                      .currentMediaItem!,
                                                  audioServiceHandler:
                                                      mediaItemManager
                                                          .audioServiceHandler,
                                                  artistJson: mediaItemManager
                                                      .currentMediaItem!
                                                      .extras!["artists"],
                                                  mediaItemManager:
                                                      mediaItemManager,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                });
                          },
                        )
                      ],
                    );
                  })
              : const SizedBox();
        },
      ),
    );
  }
}
