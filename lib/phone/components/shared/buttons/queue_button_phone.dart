import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:pongo/exports.dart';
import 'package:pongo/phone/components/queue/pull%20down%20menus/queue_edit_pull_down_menu_items.dart';
import 'package:pongo/phone/components/queue/pull%20down%20menus/queue_more_pull_down_menu_items.dart';
import 'package:pongo/phone/widgets/special/liquid_glass_background.dart';
import 'package:pongo/phone/widgets/special/liquid_glass_render.dart';

class QueueButtonPhone extends StatelessWidget {
  final bool showQueue;
  final bool lyricsOn;
  final bool editQueue;
  final bool lyricsExist;
  final Function() changeShowQueue;
  final Function() changeEditQueue;
  final Function() removeItemsFromQueue;
  final Function() changeLyricsOn;
  final Function() saveAsPlaylist;
  final Function() download;
  const QueueButtonPhone({
    super.key,
    required this.showQueue,
    required this.changeShowQueue,
    required this.editQueue,
    required this.lyricsOn,
    required this.changeEditQueue,
    required this.removeItemsFromQueue,
    required this.changeLyricsOn,
    required this.saveAsPlaylist,
    required this.download,
    required this.lyricsExist,
  });

  @override
  Widget build(BuildContext context) {
    final audioServiceHandler =
        Provider.of<AudioHandler>(context) as AudioServiceHandler;
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12.5,
      child: Container(
        width: MediaQuery.of(context).size.width - 20,
        height: 40,
        decoration: BoxDecoration(
            color: useBlur.value
                ? Col.transp
                : Col.realBackground.withAlpha(AppConstants().noBlur),
            borderRadius: BorderRadius.circular(60)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(60),
          child: liquidGlassLayer(
            child: liquidGlass(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                    sigmaX: useBlur.value && !kIsApple ? 10 : 0,
                    sigmaY: useBlur.value && !kIsApple ? 10 : 0),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(60),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(60),
                          color: kIsDesktop
                              ? const MacosColor.fromRGBO(
                                  40, 40, 40, 0.8) // Add transparency here
                              : Col.transp,
                        ),
                        child: iconButton(
                            lyricsOn ? AppIcons.lyricsFill : AppIcons.lyrics,
                            Colors.white.withAlpha(lyricsExist ? 255 : 175),
                            changeLyricsOn,
                            edgeInsets: EdgeInsets.zero),
                      ),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(60),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(60),
                          color: kIsDesktop
                              ? const MacosColor.fromRGBO(
                                  40, 40, 40, 0.8) // Add transparency here
                              : Col.transp,
                        ),
                        child: ValueListenableBuilder(
                            valueListenable: queueAllowShuffle,
                            builder: (context, _, __) {
                              return kIsApple
                                  ? CupertinoButton(
                                      padding: EdgeInsets.zero,
                                      onPressed: () async {
                                        if (queueAllowShuffle.value) {
                                          if (audioServiceHandler
                                              .audioPlayer.shuffleModeEnabled) {
                                            await audioServiceHandler
                                                .setShuffleMode(
                                                    AudioServiceShuffleMode
                                                        .none);
                                          } else {
                                            await audioServiceHandler
                                                .setShuffleMode(
                                                    AudioServiceShuffleMode
                                                        .all);
                                          }
                                        }
                                      },
                                      child: StreamBuilder(
                                          stream: audioServiceHandler
                                              .audioPlayer
                                              .shuffleModeEnabledStream,
                                          builder: (context, snapshot) {
                                            bool enabled =
                                                snapshot.data ?? false;
                                            return Icon(
                                              AppIcons.shuffle,
                                              color: enabled
                                                  ? Colors.white
                                                  : Colors.white.withAlpha(150),
                                            );
                                          }),
                                    )
                                  : IconButton(
                                      style: IconButton.styleFrom(
                                          splashFactory:
                                              InkRipple.splashFactory,
                                          overlayColor: Col.text.withAlpha(50)),
                                      onPressed: () async {
                                        if (queueAllowShuffle.value) {
                                          if (audioServiceHandler
                                              .audioPlayer.shuffleModeEnabled) {
                                            await audioServiceHandler
                                                .setShuffleMode(
                                                    AudioServiceShuffleMode
                                                        .none);
                                          } else {
                                            await audioServiceHandler
                                                .setShuffleMode(
                                                    AudioServiceShuffleMode
                                                        .all);
                                          }
                                        }
                                      },
                                      icon: StreamBuilder(
                                          stream: audioServiceHandler
                                              .audioPlayer
                                              .shuffleModeEnabledStream,
                                          builder: (context, snapshot) {
                                            bool enabled =
                                                snapshot.data ?? false;
                                            return Icon(
                                              AppIcons.shuffle,
                                              color: enabled
                                                  ? Colors.white
                                                  : Colors.white.withAlpha(150),
                                            );
                                          }),
                                    );
                            }),
                      ),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(60),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(60),
                          color: kIsDesktop
                              ? const MacosColor.fromRGBO(
                                  40, 40, 40, 0.8) // Add transparency here
                              : Col.transp,
                        ),
                        child: iconButton(
                          showQueue
                              ? AppIcons.musicQueueFill
                              : AppIcons.musicQueue,
                          Colors.white,
                          changeShowQueue,
                          edgeInsets: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(60),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(60),
                          color: kIsDesktop
                              ? const MacosColor.fromRGBO(
                                  40, 40, 40, 0.8) // Add transparency here
                              : Col.transp,
                        ),
                        child:
                            iconButton(AppIcons.halt, Colors.white, () async {
                          CustomButton ok = await haltAlert(context);
                          if (ok == CustomButton.positiveButton) {
                            currentTrackHeight.value = 0;
                            final audioServiceHandler =
                                Provider.of<AudioHandler>(context,
                                    listen: false) as AudioServiceHandler;

                            await audioServiceHandler.halt();
                          }
                        }, edgeInsets: EdgeInsets.zero),
                      ),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(60),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(60),
                          color: kIsDesktop
                              ? const MacosColor.fromRGBO(
                                  40, 40, 40, 0.8) // Add transparency here
                              : Col.transp,
                        ),
                        child: PullDownButton(
                          offset: const Offset(10, 10),
                          position: PullDownMenuPosition.automatic,
                          itemBuilder: (context) => editQueue
                              ? queueEditPullDownMenuItems(
                                  context,
                                  changeEditQueue,
                                  removeItemsFromQueue,
                                  download,
                                )
                              : queueMorePullDownMenuItems(
                                  context,
                                  changeEditQueue,
                                  saveAsPlaylist,
                                  download,
                                ),
                          buttonBuilder: (context, showMenu) => iconButton(
                            CupertinoIcons.ellipsis,
                            Colors.white,
                            showMenu,
                            edgeInsets: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
