import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../../../core/ui/blurhash/blurhash.dart';
import '../../../../shell/view_models/shell_view_model.dart';
import '../../../view_models/player_view_model.dart';
import '../../now_playing_provider.dart';
import 'lyrics_body_macos.dart';

class LyricsMacos extends StatefulWidget {
  const LyricsMacos({super.key});

  @override
  State<LyricsMacos> createState() => _LyricsMacosState();
}

class _LyricsMacosState extends State<LyricsMacos> {
  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return NowPlayingProvider(
      builder: (context, nowPlaying) {
        return nowPlaying.currentMediaItem != null
            ? ValueListenableBuilder(
                valueListenable: context.shell.navigationBarIndex,
                builder: (context, index, child) {
                  return MacosScaffold(
                    children: [
                      ContentArea(
                        builder: (context, scrollController) {
                          return SizedBox(
                            height: size.height,
                            width: size.width - 180,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 400),
                              child: Stack(
                                key: ValueKey(nowPlaying.blurhash),
                                children: [
                                  Blurhash(
                                    sigmaX: 0,
                                    sigmaY: 0,
                                    blurhash: nowPlaying.blurhash,
                                    child: const SizedBox(),
                                  ),
                                  Container(
                                    color: Colors.black.withAlpha(65),
                                    child: AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 400,
                                      ),
                                      child: Align(
                                        alignment: Alignment.topLeft,
                                        child: AnimatedSwitcher(
                                          duration: const Duration(
                                            milliseconds: 400,
                                          ),
                                          child: index == 6
                                              ? LyricsBodyMacos(
                                                  key: const ValueKey(true),
                                                  size: size,
                                                  mix:
                                                      nowPlaying
                                                              .currentMediaItem !=
                                                          null
                                                      ? nowPlaying
                                                                .currentMediaItem!
                                                                .extras!['mix'] ??
                                                            false ||
                                                                RegExp(
                                                                  r'Mix #\d{1,2}',
                                                                ).hasMatch(
                                                                  nowPlaying
                                                                      .currentMediaItem!
                                                                      .title,
                                                                )
                                                      : false,
                                                  mediaItem: nowPlaying
                                                      .currentMediaItem!,
                                                  player: context.player,
                                                  artistJson: nowPlaying
                                                      .currentMediaItem!
                                                      .extras!['artists'],
                                                  nowPlaying: nowPlaying,
                                                )
                                              : const SizedBox(
                                                  key: ValueKey(false),
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              )
            : const SizedBox();
      },
    );
  }
}
