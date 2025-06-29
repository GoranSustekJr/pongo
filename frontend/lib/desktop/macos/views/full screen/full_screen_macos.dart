import 'package:pongo/desktop/macos/views/full%20screen/full_screen_body_macos.dart';
import 'package:pongo/exports.dart';

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
    notificationsContext.value = context;
    //initFullScreen();
  }

  void initFullScreen() async {
    if (kIsDesktop && !kIsMacOS) {
      bool isFullScren = await windowManager.isFullScreen();
      setState(() {
        isFullScren = isFullScren;
      });

      if (!isFullScren) {
        windowManager.setFullScreen(true);
      }
    } else {
      SystemChannels.platform.invokeMethod('SystemNavigator.pop');
    }
  }

  @override
  void dispose() {
    fullscreenPlaying.value = false;
    if (!isFullScreen && !kIsMacOS) {
      // If was not fullscreen => return back
      windowManager.setFullScreen(false);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return MacosWindow(
      child: ChangeNotifierProvider(
        create: (_) => MediaItemManager(
          Provider.of<AudioHandler>(context) as AudioServiceHandler,
          context,
        ),
        child: Consumer<MediaItemManager>(
          builder: (context, mediaItemManager, child) {
            return mediaItemManager.currentMediaItem != null
                ? MacosScaffold(
                    children: [
                      ContentArea(
                        builder: (context, scrollController) {
                          return SizedBox(
                            height: size.height,
                            width: size.width,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 400),
                              child: mediaItemManager.currentMediaItem != null
                                  ? Stack(
                                      key: const ValueKey(true),
                                      children: [
                                        AnimatedSwitcher(
                                          duration:
                                              const Duration(milliseconds: 500),
                                          switchInCurve: Curves.fastOutSlowIn,
                                          switchOutCurve:
                                              Curves.fastEaseInToSlowEaseOut,
                                          child: BlurHashh(
                                            key: ValueKey(
                                                "${mediaItemManager.blurhash}${mediaItemManager.currentMediaItemId}"),
                                            hash: mediaItemManager.blurhash,
                                          ),
                                        ),
                                        AnimatedSwitcher(
                                          duration:
                                              const Duration(milliseconds: 500),
                                          switchInCurve: Curves.fastOutSlowIn,
                                          switchOutCurve:
                                              Curves.fastEaseInToSlowEaseOut,
                                          child: Container(
                                            key: ValueKey(mediaItemManager
                                                .currentMediaItem),
                                            color: Colors.black.withAlpha(65),
                                            child: AnimatedSwitcher(
                                              duration: const Duration(
                                                  milliseconds: 400),
                                              child: Align(
                                                  alignment: Alignment.topLeft,
                                                  child: FullScreenBodyMacos(
                                                    showLyrics: showLyrics,
                                                    size: size,
                                                    mix: mediaItemManager
                                                                .currentMediaItem !=
                                                            null
                                                        ? mediaItemManager
                                                                    .currentMediaItem!
                                                                    .extras![
                                                                "mix"] ??
                                                            false ||
                                                                RegExp(r'Mix #\d{1,2}').hasMatch(
                                                                    mediaItemManager
                                                                        .currentMediaItem!
                                                                        .title)
                                                        : false,
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
                                                    changeShowLyrics: () {
                                                      setState(() {
                                                        showLyrics =
                                                            !showLyrics;
                                                      });
                                                    },
                                                  )),
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : const SizedBox(
                                      key: ValueKey(false),
                                    ),
                            ),
                          );
                        },
                      )
                    ],
                  )
                : const SizedBox();
          },
        ),
      ),
    );
  }
}
