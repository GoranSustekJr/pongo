import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pongo/core/audio/audio_service_handler.dart';
import 'package:pongo/core/constants/app_icons.dart';
import 'package:pongo/shared/widgets/phone/buttons/icon_text_button.dart';

/// Play and shuffle buttons of a track list, or a halt button while that list
/// is the one playing. Lists that support editing swap to [editActions].
class PlayShuffleHaltBar extends StatelessWidget {
  /// First two parts of the media item id when this list is playing
  final String playingId;
  final List missingTracks;
  final bool loadingShuffle;
  final Color color;
  final Function() play;
  final Function() shuffle;
  final Widget? frontWidget;
  final Widget? endWidget;
  final bool edit;
  final List<Widget>? editActions;

  const PlayShuffleHaltBar({
    super.key,
    required this.playingId,
    required this.missingTracks,
    required this.loadingShuffle,
    required this.color,
    required this.play,
    required this.shuffle,
    this.frontWidget,
    this.endWidget,
    this.edit = false,
    this.editActions,
  });

  @override
  Widget build(BuildContext context) {
    final audioServiceHandler =
        Provider.of<AudioHandler>(context) as AudioServiceHandler;
    final dimmed = color.withAlpha(125);
    final curve = editActions != null ? Curves.fastOutSlowIn : Curves.linear;

    TextStyle style(Color color) =>
        TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: color);

    return StreamBuilder(
      stream: audioServiceHandler.mediaItem.stream,
      builder: (context, mediaItemStream) {
        final item = mediaItemStream.data;
        final showPlay = item == null ||
            playingId != '${item.id.split('.')[0]}.${item.id.split('.')[1]}';
        final playColor = loadingShuffle ? dimmed : color;
        final shuffleColor =
            missingTracks.isNotEmpty || loadingShuffle ? dimmed : color;

        final Widget buttons = AnimatedSwitcher(
          key: const ValueKey(false),
          duration: const Duration(milliseconds: 300),
          switchInCurve: curve,
          switchOutCurve: curve,
          child: showPlay
              ? Row(
                  key: const ValueKey(true),
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (frontWidget != null) frontWidget!,
                    iconTextButton(AppIcons.play, "Play", style(playColor),
                        play, playColor,
                        padding: EdgeInsets.zero),
                    iconTextButton(AppIcons.shuffle, " Shuffle",
                        style(shuffleColor), shuffle, shuffleColor,
                        padding: EdgeInsets.zero),
                    if (endWidget != null) endWidget!,
                  ],
                )
              : Row(
                  key: const ValueKey(false),
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (frontWidget != null) frontWidget!,
                    iconTextButton(AppIcons.halt, " Halt", style(color),
                        () async {
                      await audioServiceHandler.halt();
                    }, color, padding: EdgeInsets.zero),
                    if (endWidget != null) endWidget!,
                  ],
                ),
        );

        if (editActions == null) return buttons;

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: curve,
          switchOutCurve: curve,
          child: edit
              ? Row(
                  key: const ValueKey(true),
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: editActions!,
                )
              : buttons,
        );
      },
    );
  }
}
