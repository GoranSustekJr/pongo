import 'package:flutter/cupertino.dart';
import 'package:pongo/desktop/macos/views/lyrics/lyrics_desktop.dart';
import 'package:pongo/desktop/macos/views/lyrics/play_control_desktop.dart';
import 'package:pongo/desktop/macos/views/lyrics/track_progress_desktop.dart';
import 'package:pongo/exports.dart';
import 'package:pongo/shared/widgets/ui/image/image_desktop.dart';

class FullScreenBodyMacos extends StatelessWidget {
  final bool showLyrics;
  final MediaItemManager mediaItemManager;
  final MediaItem mediaItem;
  final AudioServiceHandler audioServiceHandler;
  final String artistJson;
  final Size size;
  final Function() changeShowLyrics;
  const FullScreenBodyMacos({
    super.key,
    required this.mediaItem,
    required this.audioServiceHandler,
    required this.artistJson,
    required this.mediaItemManager,
    required this.size,
    required this.changeShowLyrics,
    required this.showLyrics,
  });

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Stack(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: showLyrics
              ? LyricsDesktop(
                  plainLyrics: mediaItemManager.plainLyrics.split('\n'),
                  syncedLyrics: [
                    ...mediaItemManager.syncedLyrics.split('\n'),
                  ],
                  fullscreenPlaying: true,
                  lyricsOn: mediaItemManager.lyricsOn,
                  useSyncedLyrics: true,
                  syncTimeDelay: mediaItemManager.syncTimeDelay,
                  stid: mediaItem.id.split('.')[2],
                  onChangeUseSyncedLyrics:
                      mediaItemManager.toggleUseSyncedLyrics,
                  plus: mediaItemManager.increaseSyncTimeDelay,
                  minus: mediaItemManager.decreaseSyncTimeDelay,
                  resetSyncTimeDelay: mediaItemManager.resetSyncTimeDelay,
                )
              : const SizedBox(),
        ),
        Column(
          children: [
            Expanded(child: Container()),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                razw(20),
                TrackImageDesktop(
                    lyricsOn: showLyrics,
                    image: mediaItem.artUri.toString(),
                    stid: currentStid.value,
                    fullscreenPlay: true,
                    audioServiceHandler: audioServiceHandler),
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: SizedBox(
                    width: showLyrics
                        ? size.width * 1 / 4 - 20 - 150
                        : size.height * 0.8 > 685
                            ? size.width - ((size.height * 0.8 - 60) - 190) - 40
                            : (size.height * 0.8 - 60) - 130 <
                                    (size.width * 0.8 - 200) / 2
                                ? size.width -
                                    ((size.height * 0.8 - 60) - 130) -
                                    40
                                : size.width -
                                    ((size.width * 0.8 - 200) / 2) -
                                    40,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.fastEaseInToSlowEaseOut,
                          style: TextStyle(
                            fontSize: showLyrics ? 20 : 40,
                            fontWeight:
                                showLyrics ? FontWeight.w600 : FontWeight.w900,
                            color: Colors.white.withAlpha(220),
                          ),
                          child: Text(
                            mediaItem.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.fastEaseInToSlowEaseOut,
                          style: TextStyle(
                            fontSize: showLyrics ? 12.5 : 20,
                            fontWeight:
                                showLyrics ? FontWeight.w400 : FontWeight.w500,
                            color: Colors.white.withAlpha(150),
                          ),
                          child: Text(
                            jsonDecode(artistJson)
                                .map((artist) => artist["name"])
                                .toList()
                                .join(', '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            razh(20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: DesktopTrackProgress(
                fullscreen: true,
                album: mediaItem.album!,
                duration: mediaItem.duration,
                showAlbum: (_) {},
              ),
            ),
            Row(
              children: [
                razw(20),
                SizedBox(
                  width: 40,
                  child: CupertinoButton(
                    onPressed: changeShowLyrics,
                    child: ValueListenableBuilder(
                        valueListenable: currentStid,
                        builder: (context, _, __) {
                          return ValueListenableBuilder(
                              valueListenable: navigationBarIndex,
                              builder: (context, _, __) {
                                return Icon(
                                  showLyrics
                                      ? AppIcons.lyricsFill
                                      : AppIcons.lyrics,
                                  size: 20,
                                  color: mediaItem.id.split('.')[2] ==
                                          currentStid.value
                                      ? Colors.white
                                      : Colors.white.withAlpha(150),
                                );
                              });
                        }),
                  ),
                ),
                razw(150),
                Expanded(
                  child: Container(),
                ),
                StreamBuilder(
                    stream: audioServiceHandler.loopModeStream,
                    builder: (context, loopMode) {
                      return CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          if (audioServiceHandler.activeSleepAlarm == -1) {
                            if (audioServiceHandler.audioPlayer.loopMode.name ==
                                "all") {
                              audioServiceHandler
                                  .setRepeatMode(AudioServiceRepeatMode.none);
                            } else if (audioServiceHandler
                                    .audioPlayer.loopMode.name ==
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
                                AppLocalizations.of(
                                        notificationsContext.value!)!
                                    .sleepalarmisenabled);
                          }
                        },
                        child: Icon(
                          audioServiceHandler.audioPlayer.loopMode.name == "one"
                              ? AppIcons.repeatOne
                              : AppIcons.repeat,
                          color:
                              audioServiceHandler.audioPlayer.loopMode.name ==
                                      "off"
                                  ? Colors.white.withAlpha(150)
                                  : Colors.white,
                          size: 20,
                        ),
                      );
                    }),
                razw(10),
                StreamBuilder(
                    stream: audioServiceHandler.playbackState,
                    builder: (context, playbackState) {
                      return PlayControl(
                        mediaItem: mediaItem,
                        onTap: (_) {},
                        thisTrackPlaying:
                            currentStid.value == mediaItem.id.split('.')[2],
                        playbackState: playbackState,
                      );
                    }),
                razw(10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(60),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(60),
                      color: kIsDesktop && !kIsMacOS
                          ? const MacosColor.fromRGBO(
                              40, 40, 40, 0.8) // Add transparency here
                          : Col.transp,
                    ),
                    child: ValueListenableBuilder(
                        valueListenable: queueAllowShuffle,
                        builder: (context, _, __) {
                          return CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () async {
                              if (queueAllowShuffle.value) {
                                if (audioServiceHandler
                                    .audioPlayer.shuffleModeEnabled) {
                                  await audioServiceHandler.setShuffleMode(
                                      AudioServiceShuffleMode.none);
                                } else {
                                  await audioServiceHandler.setShuffleMode(
                                      AudioServiceShuffleMode.all);
                                }
                              }
                            },
                            child: StreamBuilder(
                                stream: audioServiceHandler
                                    .audioPlayer.shuffleModeEnabledStream,
                                builder: (context, snapshot) {
                                  bool enabled = snapshot.data ?? false;
                                  return Icon(
                                    AppIcons.shuffle,
                                    color: enabled
                                        ? Colors.white
                                        : Colors.white.withAlpha(150),
                                    size: 20,
                                  );
                                }),
                          );
                        }),
                  ),
                ),
                Expanded(
                  child: Container(),
                ),
                StreamBuilder(
                    stream: audioServiceHandler.volumeStream,
                    builder: (context, snapshot) {
                      double volume = snapshot.data ?? 0.0;

                      int iconKey;
                      if (volume == 0) {
                        iconKey = 0;
                      } else if (volume > 0 && volume <= 0.33) {
                        iconKey = 1;
                      } else if (volume > 0.33 && volume <= 0.67) {
                        iconKey = 2;
                      } else {
                        iconKey = 3;
                      }
                      return Row(
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 150),
                            transitionBuilder:
                                (Widget child, Animation<double> animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: ScaleTransition(
                                    scale: animation, child: child),
                              );
                            },
                            child: Icon(
                              key: ValueKey<int>(iconKey),
                              iconKey == 0
                                  ? CupertinoIcons.volume_off
                                  : iconKey == 1
                                      ? CupertinoIcons.speaker_1_fill
                                      : iconKey == 2
                                          ? CupertinoIcons.speaker_2_fill
                                          : CupertinoIcons.speaker_3_fill,
                              size: 15,
                              color: Colors.white,
                            ),
                          ),
                          razw(5),
                          SizedBox(
                            width: 100,
                            child: Tooltip(
                              message: AppLocalizations.of(context)!
                                  .doublecliktoadjustvolume,
                              child: MacosSlider(
                                color: CupertinoColors.white,
                                thumbColor: Colors.white,
                                //activeColor: CupertinoColors.inactiveGray,
                                value: volume,
                                onChanged: (volume) async {
                                  await audioServiceHandler.setVolume(volume);
                                },
                              ),
                            ),
                          ),
                          razw(5),
                          const Icon(
                            CupertinoIcons.volume_up,
                            size: 15,
                            color: Colors.white,
                          ),
                        ],
                      );
                    }),
                razw(10),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: iconButton(
                      CupertinoIcons.fullscreen_exit, Colors.white, () {
                    fullscreenPlaying.value = false;
                  }, edgeInsets: EdgeInsets.zero),
                ),
                razw(20),
              ],
            ),
            razh(size.height * 0.1),
          ],
        ),
      ],
    );
  }
}
