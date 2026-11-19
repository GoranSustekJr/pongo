import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:provider/provider.dart';

import '../../../../../data/repositories/player/media_items.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../utils/platform.dart';
import '../../../../core/app_icons.dart';
import '../../../../core/messages/app_message.dart';
import '../../../../core/messages/message_center.dart';
import '../../../../core/themes/colors.dart';
import '../../../../core/ui/image/image_desktop.dart';
import '../../../../core/ui/phone/buttons/icon_button.dart';
import '../../../../core/ui/space.dart';
import '../../../../shell/view_models/shell_view_model.dart';
import '../../../view_models/now_playing_view_model.dart';
import '../../../view_models/player_view_model.dart';
import '../lyrics/lyrics_desktop.dart';
import '../lyrics/play_control_desktop.dart';
import '../lyrics/track_progress_desktop.dart';

class FullScreenBodyMacos extends StatelessWidget {
  final bool showLyrics;
  final NowPlayingViewModel nowPlaying;
  final MediaItem mediaItem;
  final PlayerViewModel player;
  final bool mix;
  final String artistJson;
  final Size size;
  final Function() changeShowLyrics;
  const FullScreenBodyMacos({
    super.key,
    required this.mediaItem,
    required this.player,
    required this.artistJson,
    required this.nowPlaying,
    required this.size,
    required this.changeShowLyrics,
    required this.showLyrics,
    required this.mix,
  });

  @override
  Widget build(BuildContext context) {
    final artists = decodeArtistRefs(artistJson);
    final Size size = MediaQuery.of(context).size;
    return Stack(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: showLyrics && nowPlaying.syncedLyrics != ''
              ? LyricsDesktop(
                  plainLyrics: nowPlaying.plainLyrics.split('\n'),
                  syncedLyrics: [...nowPlaying.syncedLyrics.split('\n')],
                  fullscreenPlaying: true,
                  lyricsOn: nowPlaying.lyricsOn,
                  useSyncedLyrics: true,
                  syncTimeDelay: nowPlaying.syncTimeDelay,
                  stid: mediaItem.id.split('.')[2],
                  onChangeUseSyncedLyrics: nowPlaying.toggleUseSyncedLyrics,
                  plus: nowPlaying.increaseSyncTimeDelay,
                  minus: nowPlaying.decreaseSyncTimeDelay,
                  resetSyncTimeDelay: nowPlaying.resetSyncTimeDelay,
                  saveSyncTimeDelay: nowPlaying.saveSyncTimeDelay,
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
                  lyricsOn: showLyrics && nowPlaying.syncedLyrics != '',
                  image: (mediaItem.artUri?.toString() ?? ''),
                  stid: context.player.currentStid.value,
                  fullscreenPlay: true,
                  player: player,
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: SizedBox(
                    width: showLyrics && nowPlaying.syncedLyrics != ''
                        ? size.width * 1 / 4 - 20 - 150
                        : size.height * 0.8 > 685
                        ? size.width - ((size.height * 0.8 - 60) - 190) - 40
                        : (size.height * 0.8 - 60) - 130 <
                              (size.width * 0.8 - 200) / 2
                        ? size.width - ((size.height * 0.8 - 60) - 130) - 40
                        : size.width - ((size.width * 0.8 - 200) / 2) - 40,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.fastEaseInToSlowEaseOut,
                          style: TextStyle(
                            fontSize:
                                showLyrics && nowPlaying.syncedLyrics != ''
                                ? 20
                                : 40,
                            fontWeight:
                                showLyrics && nowPlaying.syncedLyrics != ''
                                ? FontWeight.w600
                                : FontWeight.w900,
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
                            fontSize:
                                showLyrics && nowPlaying.syncedLyrics != ''
                                ? 12.5
                                : 20,
                            fontWeight:
                                showLyrics && nowPlaying.syncedLyrics != ''
                                ? FontWeight.w400
                                : FontWeight.w500,
                            color: Colors.white.withAlpha(150),
                          ),
                          child: Text(
                            artists.map((artist) => artist.name).join(', '),
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
                album: mediaItem.album ?? '',
                duration: mediaItem.duration,
                showAlbum: (_) {},
              ),
            ),
            Row(
              children: [
                razw(20),
                Tooltip(
                  message: AppLocalizations.of(context).lyrics,
                  child: SizedBox(
                    width: 40,
                    child: CupertinoButton(
                      onPressed: changeShowLyrics,
                      padding: EdgeInsets.zero,
                      child: ValueListenableBuilder(
                        valueListenable: context.player.currentStid,
                        builder: (context, _, _) {
                          return ValueListenableBuilder(
                            valueListenable: context.shell.navigationBarIndex,
                            builder: (context, _, _) {
                              return Icon(
                                showLyrics
                                    ? AppIcons.lyricsFill
                                    : AppIcons.lyrics,
                                size: 20,
                                color:
                                    mediaItem.id.split('.')[2] ==
                                            context.player.currentStid.value &&
                                        nowPlaying.syncedLyrics != ''
                                    ? Colors.white
                                    : Colors.white.withAlpha(150),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
                Tooltip(
                  message: 'Shazam',
                  child: Container(
                    width: mix ? 27.5 : 0,
                    height: mix ? 22.5 : 0,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(60),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(200),
                          spreadRadius: 3,
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () async {
                        await context.shell.shazam(mediaItem.id.split('.')[2]);
                      },
                      child: Image.asset(
                        'assets/icons/shazam.png',
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                razw(127.5),
                Expanded(child: Container()),
                Tooltip(
                  message: AppLocalizations.of(context).repeat,
                  child: StreamBuilder(
                    stream: player.loopModeStream,
                    builder: (context, loopMode) {
                      return CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          if (player.activeSleepAlarm == -1) {
                            if (player.loopMode.name == 'all') {
                              player.setRepeatMode(AudioServiceRepeatMode.none);
                            } else if (player.loopMode.name == 'off') {
                              player.setRepeatMode(AudioServiceRepeatMode.one);
                            } else {
                              player.setRepeatMode(AudioServiceRepeatMode.all);
                            }
                          } else {
                            context.read<MessageCenter>().show(
                              WarningMessage(
                                (l10n) => l10n.sleepalarmisenabled,
                              ),
                            );
                          }
                        },
                        child: Icon(
                          player.loopMode.name == 'one'
                              ? AppIcons.repeatOne
                              : AppIcons.repeat,
                          color: player.loopMode.name == 'off'
                              ? Colors.white.withAlpha(150)
                              : Colors.white,
                          size: 20,
                        ),
                      );
                    },
                  ),
                ),
                razw(10),
                StreamBuilder(
                  stream: player.playbackState,
                  builder: (context, playbackState) {
                    return PlayControl(
                      mediaItem: mediaItem,
                      onTap: (_) {},
                      thisTrackPlaying:
                          context.player.currentStid.value ==
                          mediaItem.id.split('.')[2],
                      playbackState: playbackState,
                    );
                  },
                ),
                razw(10),
                Tooltip(
                  message: AppLocalizations.of(context).shuffle,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(60),
                      color: kIsDesktop && !kIsMacOS
                          ? const MacosColor.fromRGBO(
                              40,
                              40,
                              40,
                              0.8,
                            ) // Add transparency here
                          : Col.transp,
                    ),
                    child: ValueListenableBuilder(
                      valueListenable: context.player.canShuffle,
                      builder: (context, _, _) {
                        return CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () async {
                            if (context.player.canShuffle.value) {
                              if (player.shuffleEnabled) {
                                await player.setShuffle(enabled: false);
                              } else {
                                await player.setShuffle(enabled: true);
                              }
                            }
                          },
                          child: StreamBuilder(
                            stream: player.shuffleEnabledStream,
                            builder: (context, snapshot) {
                              final bool enabled = snapshot.data ?? false;
                              return Icon(
                                AppIcons.shuffle,
                                color: enabled
                                    ? Colors.white
                                    : Colors.white.withAlpha(150),
                                size: 20,
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Expanded(child: Container()),
                StreamBuilder(
                  stream: player.volumeStream,
                  builder: (context, snapshot) {
                    final double volume = snapshot.data ?? 0.0;

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
                                    scale: animation,
                                    child: child,
                                  ),
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
                            message: AppLocalizations.of(context)
                                .doublecliktoadjustvolume,
                            child: MacosSlider(
                              color: CupertinoColors.white,
                              thumbColor: Colors.white,
                              //activeColor: CupertinoColors.inactiveGray,
                              value: volume,
                              onChanged: (volume) async {
                                await player.setVolume(volume);
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
                  },
                ),
                razw(10),
                Tooltip(
                  message: AppLocalizations.of(context).exitfullscreen,
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: iconButton(
                      CupertinoIcons.fullscreen_exit,
                      Colors.white,
                      () {
                        context.shell.fullscreenPlaying.value = false;
                      },
                      edgeInsets: EdgeInsets.zero,
                    ),
                  ),
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
