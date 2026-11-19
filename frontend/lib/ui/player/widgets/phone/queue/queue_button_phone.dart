import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:kr_pull_down_button/pull_down_button.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../../../../utils/platform.dart';
import '../../../../app/view_models/app_settings_view_model.dart';
import '../../../../core/app_icons.dart';
import '../../../../core/themes/colors.dart';
import '../../../../core/themes/dimens.dart';
import '../../../../core/ui/app_blur.dart';
import '../../../../core/ui/phone/buttons/icon_button.dart';
import '../../../../core/ui/phone/liquid_glass_background.dart';
import '../../../../core/ui/phone/liquid_glass_render.dart';
import '../../../../shell/view_models/shell_view_model.dart';
import '../../../view_models/player_view_model.dart';
import '../alerts/halt_alert.dart';
import 'queue_edit_pull_down_menu_items.dart';
import 'queue_more_pull_down_menu_items.dart';

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
    final player = context.player;
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12.5,
      child: Container(
        width: MediaQuery.of(context).size.width - 20,
        height: 40,
        decoration: BoxDecoration(
          color: context.readSettings.useBlur
              ? Col.transp
              : context.colors.realBackground.withAlpha(Dimens.noBlur),
          borderRadius: BorderRadius.circular(60),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(60),
          child: liquidGlassLayer(
            child: liquidGlass(
              child: liquidGlassBackground(
                enabled: context.readSettings.useLiquidGlass,
                child: BackdropFilter(
                  filter: nonAppleBlur(context, 10),
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
                                    40,
                                    40,
                                    40,
                                    0.8,
                                  ) // Add transparency here
                                : Col.transp,
                          ),
                          child: iconButton(
                            lyricsOn ? AppIcons.lyricsFill : AppIcons.lyrics,
                            Colors.white.withAlpha(lyricsExist ? 255 : 175),
                            changeLyricsOn,
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
                              return kIsApple
                                  ? CupertinoButton(
                                      padding: EdgeInsets.zero,
                                      onPressed: () async {
                                        if (context.player.canShuffle.value) {
                                          await player.setShuffle(
                                            enabled: !player.shuffleEnabled,
                                          );
                                        }
                                      },
                                      child: StreamBuilder(
                                        stream: player.shuffleEnabledStream,
                                        builder: (context, snapshot) {
                                          final bool enabled =
                                              snapshot.data ?? false;
                                          return Icon(
                                            AppIcons.shuffle,
                                            color: enabled
                                                ? Colors.white
                                                : Colors.white.withAlpha(150),
                                          );
                                        },
                                      ),
                                    )
                                  : IconButton(
                                      style: IconButton.styleFrom(
                                        splashFactory: InkRipple.splashFactory,
                                        overlayColor: context.colors.text
                                            .withAlpha(50),
                                      ),
                                      onPressed: () async {
                                        if (context.player.canShuffle.value) {
                                          await player.setShuffle(
                                            enabled: !player.shuffleEnabled,
                                          );
                                        }
                                      },
                                      icon: StreamBuilder(
                                        stream: player.shuffleEnabledStream,
                                        builder: (context, snapshot) {
                                          final bool enabled =
                                              snapshot.data ?? false;
                                          return Icon(
                                            AppIcons.shuffle,
                                            color: enabled
                                                ? Colors.white
                                                : Colors.white.withAlpha(150),
                                          );
                                        },
                                      ),
                                    );
                            },
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
                                    40,
                                    40,
                                    40,
                                    0.8,
                                  ) // Add transparency here
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
                                    40,
                                    40,
                                    40,
                                    0.8,
                                  ) // Add transparency here
                                : Col.transp,
                          ),
                          child: iconButton(
                            AppIcons.halt,
                            Colors.white,
                            () async {
                              final CustomButton ok = await haltAlert(context);
                              if (ok == CustomButton.positiveButton &&
                                  context.mounted) {
                                context.shell.currentTrackHeight.value = 0;
                                final player = context.player;

                                await player.halt();
                              }
                            },
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
                                    40,
                                    40,
                                    40,
                                    0.8,
                                  ) // Add transparency here
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
      ),
    );
  }
}
