import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:window_manager/legacy.dart';

import '../../../../../utils/platform.dart';
import '../../../../core/ui/blurhash/blurhash.dart';
import '../../../../shell/view_models/shell_view_model.dart';
import '../../../view_models/player_view_model.dart';
import '../../now_playing_provider.dart';
import 'full_screen_body_macos.dart';

class FullScreenMacos extends StatefulWidget {
  const FullScreenMacos({super.key});

  @override
  State<FullScreenMacos> createState() => _FullScreenMacosState();
}

class _FullScreenMacosState extends State<FullScreenMacos> {
  // Is already fullscreen
  bool isFullScreen = false;

  // Show lyrics
  bool showLyrics = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    //initFullScreen();
  }

  Future<void> initFullScreen() async {
    if (kIsDesktop && !kIsMacOS) {
      bool isFullScren = await windowManager.isFullScreen();
      setState(() {
        isFullScren = isFullScren;
      });

      if (!isFullScren) {
        unawaited(windowManager.setFullScreen(true));
      }
    } else {
      await SystemChannels.platform.invokeMethod('SystemNavigator.pop');
    }
  }

  @override
  void dispose() {
    context.shell.fullscreenPlaying.value = false;
    if (!isFullScreen && !kIsMacOS) {
      // If was not fullscreen => return back
      windowManager.setFullScreen(false);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return MacosWindow(
      child: NowPlayingProvider(
        builder: (context, nowPlaying) {
          return nowPlaying.currentMediaItem != null
              ? MacosScaffold(
                  children: [
                    ContentArea(
                      builder: (context, scrollController) {
                        return SizedBox(
                          height: size.height,
                          width: size.width,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            child: nowPlaying.currentMediaItem != null
                                ? Stack(
                                    key: const ValueKey(true),
                                    children: [
                                      AnimatedSwitcher(
                                        duration: const Duration(
                                          milliseconds: 500,
                                        ),
                                        switchInCurve: Curves.fastOutSlowIn,
                                        switchOutCurve:
                                            Curves.fastEaseInToSlowEaseOut,
                                        child: BlurHashh(
                                          key: ValueKey(
                                            '${nowPlaying.blurhash}${nowPlaying.currentMediaItemId}',
                                          ),
                                          hash: nowPlaying.blurhash,
                                        ),
                                      ),
                                      AnimatedSwitcher(
                                        duration: const Duration(
                                          milliseconds: 500,
                                        ),
                                        switchInCurve: Curves.fastOutSlowIn,
                                        switchOutCurve:
                                            Curves.fastEaseInToSlowEaseOut,
                                        child: Container(
                                          key: ValueKey(
                                            nowPlaying.currentMediaItem,
                                          ),
                                          color: Colors.black.withAlpha(65),
                                          child: AnimatedSwitcher(
                                            duration: const Duration(
                                              milliseconds: 400,
                                            ),
                                            child: Align(
                                              alignment: Alignment.topLeft,
                                              child: FullScreenBodyMacos(
                                                showLyrics: showLyrics,
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
                                                changeShowLyrics: () {
                                                  setState(() {
                                                    showLyrics = !showLyrics;
                                                  });
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : const SizedBox(key: ValueKey(false)),
                          ),
                        );
                      },
                    ),
                  ],
                )
              : const SizedBox();
        },
      ),
    );
  }
}
