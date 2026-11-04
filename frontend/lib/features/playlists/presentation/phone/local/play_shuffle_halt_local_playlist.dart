import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kr_pull_down_button/pull_down_button.dart';

import 'package:pongo/features/player/presentation/phone/play_shuffle_halt_bar.dart';
import 'package:pongo/core/constants/app_icons.dart';
import 'package:pongo/core/constants/platform.dart';
import 'package:pongo/l10n/app_localizations.dart';
import 'package:pongo/shared/widgets/phone/buttons/icon_button.dart';

class PlayShuffleHaltLocalPlaylist extends StatelessWidget {
  final int lpid;
  final List missingTracks;
  final bool allSelected;
  final bool loadingShuffle;
  final bool edit;
  final Widget frontWidget;
  final Widget endWidget;
  final Function() play;
  final Function() shuffle;
  final Function() stopEdit;
  final Function() remove;
  final Function() addToPlaylist;
  final Function() show;
  final Function() hide;
  final Function() selectAll;
  const PlayShuffleHaltLocalPlaylist({
    super.key,
    required this.lpid,
    required this.missingTracks,
    required this.loadingShuffle,
    required this.edit,
    required this.frontWidget,
    required this.endWidget,
    required this.play,
    required this.shuffle,
    required this.stopEdit,
    required this.remove,
    required this.addToPlaylist,
    required this.show,
    required this.hide,
    required this.allSelected,
    required this.selectAll,
  });

  @override
  Widget build(BuildContext context) {
    return PlayShuffleHaltBar(
      playingId: "local.playlist:${lpid}",
      missingTracks: missingTracks,
      loadingShuffle: loadingShuffle,
      color: Colors.white,
      play: play,
      shuffle: shuffle,
      frontWidget: frontWidget,
      endWidget: endWidget,
      edit: edit,
      editActions: [
        iconButton(
          allSelected ? AppIcons.checkmark : AppIcons.uncheckmark,
          Colors.white,
          selectAll,
          edgeInsets: EdgeInsets.zero,
        ),
        iconButton(
          AppIcons.musicAlbums,
          Colors.white,
          () {
            addToPlaylist();
          },
          edgeInsets: EdgeInsets.zero,
        ),
        if (kIsApple)
          PullDownButton(
            itemBuilder: (context) {
              return [
                PullDownMenuItem(
                  onTap: show,
                  title: AppLocalizations.of(context).show,
                  icon: AppIcons.unhideFill,
                ),
                const PullDownMenuDivider(),
                PullDownMenuItem(
                  onTap: hide,
                  title: AppLocalizations.of(context).hide,
                  icon: AppIcons.hideFill,
                ),
              ];
            },
            position: PullDownMenuPosition.automatic,
            buttonBuilder: (context, showMenu) => CupertinoButton(
              onPressed: showMenu,
              padding: EdgeInsets.zero,
              child: const Icon(
                AppIcons.hide,
                color: Colors.white,
              ),
            ),
          ),
        iconButton(
          AppIcons.trash,
          Colors.white,
          () {
            remove();
          },
          edgeInsets: EdgeInsets.zero,
        ),
        iconButton(
          AppIcons.cancel,
          Colors.white,
          stopEdit,
          edgeInsets: EdgeInsets.zero,
        )
      ],
    );
  }
}
