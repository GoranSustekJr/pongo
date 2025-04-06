import 'package:flutter/cupertino.dart';
import '../../../exports.dart';

class TitleBarMacos extends StatelessWidget {
  final MediaItem currentMediaItem;
  final bool queue;
  final Function() showQueue;
  const TitleBarMacos(
      {super.key,
      required this.currentMediaItem,
      required this.queue,
      required this.showQueue});

  @override
  Widget build(BuildContext context) {
    final audioServiceHandler =
        Provider.of<AudioHandler>(context) as AudioServiceHandler;
    return Row(
      children: [
        Tooltip(
          message: AppLocalizations.of(context).lyrics,
          child: SizedBox(
            width: 40,
            child: CupertinoButton(
              child: ValueListenableBuilder(
                  valueListenable: currentStid,
                  builder: (context, _, __) {
                    return ValueListenableBuilder(
                        valueListenable: navigationBarIndex,
                        builder: (context, _, __) {
                          return Icon(
                            navigationBarIndex.value == 6
                                ? AppIcons.lyricsFill
                                : AppIcons.lyrics,
                            size: 20,
                            color: currentMediaItem.id.split('.')[2] ==
                                    currentStid.value
                                ? Colors.white
                                : Colors.white.withAlpha(150),
                          );
                        });
                  }),
              onPressed: () {
                if (navigationBarIndex.value != 2) {
                  navigationBarIndex.value = 6;
                }
                if (currentMediaItem.id.split('.')[2] != currentStid.value) {
                  currentStid.value = currentMediaItem.id.split('.')[2];
                }
              },
            ),
          ),
        ),
        razw(12),
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
                        child: ScaleTransition(scale: animation, child: child),
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
                      message:
                          AppLocalizations.of(context).doublecliktoadjustvolume,
                      child: MacosSlider(
                        color: Colors.white,
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
        razw(8),
        Tooltip(
          message: AppLocalizations.of(context).queue,
          child: SizedBox(
            width: 30,
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 15),
              onPressed: showQueue,
              child: Icon(
                queue ? AppIcons.musicQueueFill : AppIcons.musicQueue,
                size: 20,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
