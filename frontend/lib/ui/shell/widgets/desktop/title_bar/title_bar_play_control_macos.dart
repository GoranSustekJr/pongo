import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:provider/provider.dart';

import '../../../../../data/repositories/player/media_items.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../core/app_icons.dart';
import '../../../../core/messages/app_message.dart';
import '../../../../core/messages/message_center.dart';
import '../../../../core/ui/phone/buttons/icon_button_forward.dart';
import '../../../../core/view_models/track_actions_view_model.dart';
import '../../../../player/view_models/player_view_model.dart';
import '../../../../player/widgets/desktop/play_pause_mini.dart';

class TitleBarPlayControlMacos extends StatelessWidget {
  final MediaItem currentMediaItem;
  final Function() play;
  const TitleBarPlayControlMacos({
    super.key,
    required this.currentMediaItem,
    required this.play,
  });

  @override
  Widget build(BuildContext context) {
    final player = context.player;
    return Row(
      children: [
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
                      WarningMessage((l10n) => l10n.sleepalarmisenabled),
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
                  size: 17,
                ),
              );
            },
          ),
        ),
        iconButtonForward(CupertinoIcons.backward_fill, () async {
          await player.skipToPrevious();
        }, height: 25),
        playPauseMini(player.isPlaying, play),
        iconButtonForward(CupertinoIcons.forward_fill, () async {
          await player.skipToNext();
        }, height: 25),
        MacosPulldownButton(
          itemHeight: 30,
          icon: CupertinoIcons.ellipsis_circle,
          items: [
            MacosPulldownMenuItem(
              title: SizedBox(
                width: 150,
                height: 70,
                child: Row(
                  children: [
                    const MacosIcon(AppIcons.download, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context).download,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1, // Ensure single line with ellipsis
                      ),
                    ),
                  ],
                ),
              ),
              onTap: () => debugPrint('Tags...'),
            ),
            const MacosPulldownMenuDivider(),
            MacosPulldownMenuItem(
              title: SizedBox(
                width: 150,
                child: Row(
                  children: [
                    const MacosIcon(AppIcons.musicAlbums, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context).addtoplaylist,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
              onTap: () => debugPrint('Tags...'),
            ),
            const MacosPulldownMenuDivider(),
            MacosPulldownMenuItem(
              title: FutureBuilder(
                future: context.watch<TrackActionsViewModel>().isFavourite(
                  currentMediaItem.id.split('.')[2],
                ),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Icon(CupertinoIcons.exclamationmark_circle),
                    );
                  } else {
                    final bool isFavourite = snapshot.data ?? false;

                    return SizedBox(
                      width: 150,
                      child: Row(
                        children: [
                          MacosIcon(
                            isFavourite ? AppIcons.heartFill : AppIcons.heart,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isFavourite
                                  ? AppLocalizations.of(context).unlike
                                  : AppLocalizations.of(context).like,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
              onTap: () async {
                await context.trackActions.toggleFavourite(
                  currentMediaItem.toTrack(),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
