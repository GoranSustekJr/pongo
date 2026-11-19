import 'package:flutter/material.dart';

import 'package:pongo/features/player/presentation/phone/play_shuffle_halt_bar.dart';
import 'package:pongo/app/theme/colors.dart';
import 'package:pongo/core/constants/app_icons.dart';
import 'package:pongo/shared/widgets/phone/buttons/icon_button.dart';

class PlayShuffleHaltFavourites extends StatelessWidget {
  final List missingTracks;
  final bool loadingShuffle;
  final bool edit;
  final Widget frontWidget;
  final Widget endWidget;
  final Function() play;
  final Function() shuffle;
  final Function() stopEdit;
  final Function() unfavourite;
  final Function() addToPlaylist;
  final Function() download;
  const PlayShuffleHaltFavourites({
    super.key,
    required this.missingTracks,
    required this.loadingShuffle,
    required this.edit,
    required this.frontWidget,
    required this.endWidget,
    required this.play,
    required this.shuffle,
    required this.stopEdit,
    required this.unfavourite,
    required this.addToPlaylist,
    required this.download,
  });

  @override
  Widget build(BuildContext context) {
    return PlayShuffleHaltBar(
      playingId: "library.favourites",
      missingTracks: missingTracks,
      loadingShuffle: loadingShuffle,
      color: Col.icon,
      play: play,
      shuffle: shuffle,
      frontWidget: frontWidget,
      endWidget: endWidget,
      edit: edit,
      editActions: [
        iconButton(
          AppIcons.download,
          Col.icon,
          () {
            download();
          },
          edgeInsets: EdgeInsets.zero,
        ),
        iconButton(
          AppIcons.musicAlbums,
          Col.icon,
          () {
            addToPlaylist();
          },
          edgeInsets: EdgeInsets.zero,
        ),
        iconButton(
          AppIcons.heartSlash,
          Col.icon,
          () {
            unfavourite();
          },
          edgeInsets: EdgeInsets.zero,
        ),
        iconButton(
          AppIcons.cancel,
          Col.icon,
          stopEdit,
          edgeInsets: EdgeInsets.zero,
        )
      ],
    );
  }
}
