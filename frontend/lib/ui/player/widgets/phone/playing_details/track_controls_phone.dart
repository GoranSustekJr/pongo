import 'dart:ui';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../../data/repositories/player/media_items.dart';
import '../../../../../utils/platform.dart';
import '../../../../app/view_models/app_settings_view_model.dart';
import '../../../../core/themes/colors.dart';
import '../../../../core/ui/phone/liquid_glass_background.dart';
import '../../../../core/ui/phone/liquid_glass_render.dart';
import '../../../../core/view_models/track_actions_view_model.dart';
import '../../../view_models/player_view_model.dart';
import 'controls/other_controls_phone.dart';
import 'controls/play_control_phone.dart';
import 'controls/title_artist_visualizer_phone.dart';
import 'controls/track_progress_phone.dart';
import 'controls/volume_control_phone.dart';

class TrackControlsPhone extends StatelessWidget {
  final MediaItem currentMediaItem;
  final bool lyricsOn;
  final bool showQueue;
  final bool syncLyrics;
  final bool lyricsExist;
  final Function() changeLyricsOn;
  final Function() changeShowQueue;
  final Function(String) showAlbum;
  final Function(String) showArtist;
  const TrackControlsPhone({
    super.key,
    required this.currentMediaItem,
    required this.lyricsOn,
    required this.changeLyricsOn,
    required this.showQueue,
    required this.changeShowQueue,
    required this.showAlbum,
    required this.showArtist,
    required this.syncLyrics,
    required this.lyricsExist,
  });

  @override
  Widget build(BuildContext context) {
    // double x = 1.5;
    const double x = 7.5;
    final Size size = MediaQuery.of(context).size;
    final player = context.player;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 600),
      curve: Curves.decelerate,
      bottom: (lyricsOn && lyricsExist) || showQueue
          ? -50 - 50 - 30 - 50 + MediaQuery.of(context).viewPadding.bottom + 30
          : (size.height -
                        (size.width - 60) -
                        380 -
                        MediaQuery.of(context).padding.top -
                        30 -
                        15) /
                    2 -
                70,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        pressedOpacity: 1,
        onPressed: () {},
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          width: size.width,
          height: 400,
          decoration: BoxDecoration(
            gradient:
                ((lyricsOn && lyricsExist) && syncLyrics) ||
                    (showQueue && !context.readSettings.useBlur)
                ? LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      if ((showQueue &&
                          !context.readSettings.useBlur &&
                          !lyricsOn))
                        context.colors.realBackground.withAlpha(200),
                      if (lyricsOn && syncLyrics) Colors.black.withAlpha(100),
                      if ((showQueue &&
                          !context.readSettings.useBlur &&
                          !lyricsOn))
                        context.colors.realBackground.withAlpha(200),
                      if (lyricsOn && syncLyrics) Colors.black.withAlpha(100),
                      if ((showQueue &&
                          !context.readSettings.useBlur &&
                          !lyricsOn))
                        context.colors.realBackground.withAlpha(200),
                      if (lyricsOn && syncLyrics) Colors.black.withAlpha(100),
                      if ((showQueue &&
                          !context.readSettings.useBlur &&
                          !lyricsOn))
                        context.colors.realBackground.withAlpha(200),
                      if (lyricsOn && syncLyrics) Colors.black.withAlpha(100),
                      if (showQueue &&
                          !context.readSettings.useBlur &&
                          !lyricsOn)
                        context.colors.realBackground.withAlpha(50),
                      if (lyricsOn && syncLyrics) Colors.transparent,
                    ],
                  )
                : null,
          ),
          child: Stack(
            children: [
              AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: showQueue && !lyricsOn ? 1 : 0,
                child: liquidGlassLayer(
                  child: liquidGlass(
                    radius: 28,
                    child: liquidGlassBackground(
                      enabled: context.readSettings.useLiquidGlass,
                      child: Container(),
                    ),
                  ),
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: kIsApple
                        ? 0
                        : ((lyricsOn && lyricsExist) && syncLyrics) ||
                              !context.readSettings.useBlur
                        ? 0.1
                        : x,
                    sigmaY: kIsApple
                        ? 0
                        : ((lyricsOn && lyricsExist) && syncLyrics) ||
                              !context.readSettings.useBlur
                        ? 0.1
                        : x,
                  ),
                  //blendMode: BlendMode.src,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 15,
                      right: 15,
                      top: 10,
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      switchInCurve: Curves.fastOutSlowIn,
                      switchOutCurve: Curves.fastEaseInToSlowEaseOut,
                      child: StreamBuilder(
                        key: ValueKey(currentMediaItem.id),
                        stream: player.playbackState,
                        builder: (context, playbackState) {
                          return Column(
                            children: [
                              // razh(50),
                              TitleArtistVisualizerPhone(
                                name: currentMediaItem.title,
                                stid: currentMediaItem.id.split('.')[2],
                                artistJson: currentMediaItem.extras!['artists'],
                                playbackState: playbackState,
                                smallImage:
                                    (lyricsOn && lyricsExist) || showQueue,
                                mix:
                                    currentMediaItem.extras!['mix'] ??
                                    false ||
                                        RegExp(r'Mix #\d{1,2}')
                                            .hasMatch(currentMediaItem.title),
                                showArtist: showArtist,
                              ),
                              TrackProgressPhone(
                                album: currentMediaItem.album ?? '',
                                albumId: currentMediaItem.albumId,
                                duration: currentMediaItem.duration,
                                showAlbum: showAlbum,
                              ),
                              PlayControlPhone(
                                mediaItem: currentMediaItem,
                                playbackState: playbackState,
                              ),
                              const VolumeControlPhone(),
                              OtherControlsPhone(
                                lyricsOn: lyricsOn,
                                lyricsExist: lyricsExist,
                                showQueue: showQueue,
                                track: currentMediaItem.toTrack(),
                                downloadTrack: () async {
                                  await context.trackActions.download(
                                    currentMediaItem.toTrack(),
                                    cover: currentMediaItem.artUri?.toString(),
                                  );
                                },
                                changeLyricsOn: changeLyricsOn,
                                changeShowQueue: changeShowQueue,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          /*   ],
          ), */
        ),
      ),
    );
  }
}
