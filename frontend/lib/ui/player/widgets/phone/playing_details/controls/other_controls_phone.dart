// ignore_for_file: library_private_types_in_public_api

import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../../domain/models/catalog/track.dart';
import '../../../../../core/app_icons.dart';
import '../../../../../core/messages/app_message.dart';
import '../../../../../core/messages/message_center.dart';
import '../../../../../core/ui/phone/buttons/icon_button.dart';
import '../../../../../core/view_models/track_actions_view_model.dart';
import '../../../../view_models/player_view_model.dart';
import 'track_info_button.dart';

class OtherControlsPhone extends StatefulWidget {
  final bool lyricsOn;
  final bool showQueue;
  final bool lyricsExist;
  final Track track;
  final Function() downloadTrack;
  final Function() changeLyricsOn;
  final Function() changeShowQueue;

  const OtherControlsPhone({
    super.key,
    required this.lyricsOn,
    required this.track,
    required this.downloadTrack,
    required this.changeLyricsOn,
    required this.showQueue,
    required this.changeShowQueue,
    required this.lyricsExist,
  });

  @override
  _OtherControlsPhoneState createState() => _OtherControlsPhoneState();
}

class _OtherControlsPhoneState extends State<OtherControlsPhone> {
  void refreshFavouriteStatus() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final player = context.player;
    return StreamBuilder(
      stream: player.loopModeStream,
      builder: (context, loopMode) {
        return AnimatedOpacity(
          duration: const Duration(milliseconds: 450),
          opacity: (widget.lyricsOn && widget.lyricsExist) || widget.showQueue
              ? 0
              : 1,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              iconButton(
                widget.lyricsOn ? AppIcons.lyricsFill : AppIcons.lyrics,
                Colors.white.withAlpha(widget.lyricsExist ? 255 : 150),
                widget.changeLyricsOn,
              ),
              iconButton(
                player.loopMode.name == 'one'
                    ? AppIcons.repeatOne
                    : AppIcons.repeat,
                player.loopMode.name == 'off'
                    ? Colors.white.withAlpha(150)
                    : Colors.white,
                () {
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
              ),
              FutureBuilder<bool>(
                future: context.watch<TrackActionsViewModel>().isFavourite(
                  widget.track.id,
                ),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Icon(CupertinoIcons.exclamationmark_circle),
                    );
                  } else {
                    final bool isFavourite = snapshot.data ?? false;

                    return trackInfoButton(
                      context,
                      widget.track,
                      isFavourite,
                      widget.downloadTrack,
                      refreshFavouriteStatus,
                    );
                  }
                },
              ),
              iconButton(
                widget.showQueue
                    ? AppIcons.musicQueueFill
                    : AppIcons.musicQueue,
                Colors.white,
                () {
                  widget.changeShowQueue();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
