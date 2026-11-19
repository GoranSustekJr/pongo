import 'package:figma_spring_curve/figma_spring_curve.dart';
import 'package:flutter/material.dart';

import '../../../../core/app_icons.dart';
import '../../../../core/themes/colors.dart';
import '../../../../core/ui/image/image_compatible.dart';
import '../../../view_models/player_view_model.dart';

class TrackImagePhone extends StatelessWidget {
  final bool lyricsOn;
  final bool showQueue;

  final PlayerViewModel player;
  final String image;
  const TrackImagePhone({
    super.key,
    required this.lyricsOn,
    required this.image,
    required this.showQueue,
    required this.player,
  });

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      bottom: lyricsOn || showQueue
          ? 50 -
                50 -
                30 -
                50 +
                MediaQuery.of(context).viewPadding.bottom +
                30 -
                (size.width / 2) +
                285
          : size.height -
                (MediaQuery.of(context).padding.top + 30 + size.width - 60),
      left: lyricsOn || showQueue ? -(size.width - 80) / 2 : null,
      curve: Curves.decelerate,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: size.width - 40,
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    lyricsOn || showQueue ? 5 : 15,
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    switchInCurve: Curves.fastOutSlowIn,
                    switchOutCurve: Curves.fastEaseInToSlowEaseOut,
                    child: StreamBuilder<Object>(
                      key: ValueKey(image),
                      stream: player.playingStream,
                      builder: (context, snapshot) {
                        return Column(
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (player.isPlaying) {
                                  player.pause();
                                } else {
                                  player.play();
                                }
                              },
                              child: AnimatedScale(
                                scale: lyricsOn || showQueue
                                    ? player.isPlaying
                                          ? 50 / (size.width - 40)
                                          : 50 / (size.width - 40) * 0.8
                                    : player.isPlaying
                                    ? 1.0
                                    : 0.85,
                                duration: const Duration(milliseconds: 500),
                                curve: FigmaSpringCurve(250, 20, 2),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    lyricsOn || showQueue ? 5 : 15,
                                  ),
                                  child: ColorFiltered(
                                    colorFilter: ColorFilter.mode(
                                      player.isPlaying
                                          ? Colors.transparent
                                          : Colors.black.withAlpha(25),
                                      BlendMode.srcOver,
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(
                                        lyricsOn || showQueue ? 5 : 15,
                                      ),
                                      child: image != '' && image != 'null'
                                          ? SizedBox(
                                              height: size.width - 40,
                                              width: size.width - 40,
                                              child: ImageCompatible(
                                                image: image,
                                              ),
                                            )
                                          : Container(
                                              height: size.width - 40,
                                              width: size.width - 40,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      lyricsOn || showQueue
                                                          ? 5
                                                          : 15,
                                                    ),
                                                color: context
                                                    .colors
                                                    .primaryCard
                                                    .withAlpha(150),
                                              ),
                                              child: Center(
                                                child: Icon(
                                                  AppIcons.blankTrack,
                                                  size: 50,
                                                ),
                                              ),
                                            ),
                                      //  ),
                                    ),
                                  ),
                                ),
                              ),
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
      ),
    );
  }
}
