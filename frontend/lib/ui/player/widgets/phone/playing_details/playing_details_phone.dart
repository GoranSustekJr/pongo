import 'package:flutter/material.dart';

import '../../../../app/view_models/app_settings_view_model.dart';
import '../../../../core/ui/blurhash/blurhash.dart';
import '../../../../shell/view_models/shell_view_model.dart';
import '../../../view_models/player_view_model.dart';
import '../../now_playing_provider.dart';
import '../lyrics/lyrics_button_phone.dart';
import '../lyrics/lyrics_phone.dart';
import '../queue/queue_phone.dart';
import 'track_controls_phone.dart';
import 'track_image_phone.dart';

class PlayingDetailsPhone extends StatelessWidget {
  final Function(String) showAlbum;
  final Function(String) showArtist;
  const PlayingDetailsPhone({
    super.key,
    required this.showAlbum,
    required this.showArtist,
  });

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return NowPlayingProvider(
      builder: (context, nowPlaying) {
        return nowPlaying.currentMediaItem != null
            ? ValueListenableBuilder(
                valueListenable: context.shell.currentTrackHeight,
                builder: (context, index, child) {
                  return AnimatedSwitcher(
                    key: ValueKey(context.shell.currentTrackHeight),
                    duration: Duration(
                      milliseconds: context.readSettings.useAnimations
                          ? 250
                          : 0,
                    ),
                    child: context.shell.currentTrackHeight.value != 0
                        ? Stack(
                            key: const ValueKey(true),
                            children: [
                              Container(color: Colors.black),
                              AnimatedSwitcher(
                                duration: const Duration(
                                  milliseconds: 500,
                                ), // 5000 for dynamic blurhash
                                switchInCurve: Curves.fastOutSlowIn,
                                switchOutCurve: Curves.fastEaseInToSlowEaseOut,
                                child: BlurHashh(
                                  key: ValueKey(nowPlaying.blurhash),
                                  hash: nowPlaying.blurhash,
                                ),
                              ),
                              Container(color: Colors.black.withAlpha(65)),
                              LyricsPhone(
                                plainLyrics: nowPlaying.plainLyrics.split('\n'),
                                syncedLyrics: [
                                  ...nowPlaying.syncedLyrics.split('\n'),
                                ],
                                lyricsOn:
                                    nowPlaying.lyricsOn &&
                                    nowPlaying.lyricsExist,
                                useSyncedLyrics: nowPlaying.useSyncedLyric,
                                syncTimeDelay: nowPlaying.syncTimeDelay,
                              ),
                              if (!nowPlaying.lyricsOn)
                                SizedBox(
                                  height: size.height,
                                  width: size.width,
                                  child: const Text(''),
                                ),
                              QueuePhone(
                                //  key: queueKey,
                                showQueue: nowPlaying.showQueue,
                                lyricsOn: nowPlaying.lyricsOn,
                                lyricsExist: nowPlaying.lyricsExist,
                                changeShowQueue: nowPlaying.toggleShowQueue,
                                changeLyricsOn: nowPlaying.toggleLyricsOn,
                              ),
                              LyricsButtonPhone(
                                stid: nowPlaying.currentMediaItem!.id.split(
                                  '.',
                                )[2],
                                syncTimeDelay: nowPlaying.syncTimeDelay,
                                lyricsOn:
                                    nowPlaying.lyricsOn &&
                                    nowPlaying.lyricsExist,
                                useSynced: nowPlaying.useSyncedLyric,
                                changeLyricsOn: nowPlaying.toggleLyricsOn,
                                changeUseSynced:
                                    nowPlaying.toggleUseSyncedLyrics,
                                resetSyncTimeDelay:
                                    nowPlaying.resetSyncTimeDelay,
                                saveSyncTimeDelay: nowPlaying.saveSyncTimeDelay,
                                plus: nowPlaying.increaseSyncTimeDelay,
                                minus: nowPlaying.decreaseSyncTimeDelay,
                              ),
                              TrackControlsPhone(
                                currentMediaItem: nowPlaying.currentMediaItem!,
                                lyricsExist: nowPlaying.lyricsExist,
                                lyricsOn: nowPlaying.lyricsOn,
                                showQueue: nowPlaying.showQueue,
                                syncLyrics: nowPlaying.useSyncedLyric,
                                changeLyricsOn: nowPlaying.toggleLyricsOn,
                                changeShowQueue: nowPlaying.toggleShowQueue,
                                showAlbum: showAlbum,
                                showArtist: showArtist,
                              ),
                              TrackImagePhone(
                                lyricsOn:
                                    nowPlaying.lyricsOn &&
                                    nowPlaying.lyricsExist,
                                showQueue: nowPlaying.showQueue,
                                player: context.player,
                                image: nowPlaying.currentMediaItem!.artUri
                                    .toString(),
                              ),
                            ],
                          )
                        : Container(
                            key: const ValueKey(false),
                            color: Colors.transparent,
                          ),
                  );
                },
              )
            : const SizedBox();
      },
    );
  }
}
