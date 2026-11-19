import 'package:flutter/material.dart';

import '../../../../core/app_icons.dart';
import '../../../../core/themes/colors.dart';
import '../../../../core/ui/phone/buttons/icon_button.dart';
import '../../../../player/widgets/phone/play_shuffle_halt_bar.dart';

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
      playingId: 'library.favourites',
      missingTracks: missingTracks,
      loadingShuffle: loadingShuffle,
      color: context.colors.icon,
      play: play,
      shuffle: shuffle,
      frontWidget: frontWidget,
      endWidget: endWidget,
      edit: edit,
      editActions: [
        iconButton(
          AppIcons.download,
          context.colors.icon,
          download,
          edgeInsets: EdgeInsets.zero,
        ),
        iconButton(
          AppIcons.musicAlbums,
          context.colors.icon,
          addToPlaylist,
          edgeInsets: EdgeInsets.zero,
        ),
        iconButton(
          AppIcons.heartSlash,
          context.colors.icon,
          unfavourite,
          edgeInsets: EdgeInsets.zero,
        ),
        iconButton(
          AppIcons.cancel,
          context.colors.icon,
          stopEdit,
          edgeInsets: EdgeInsets.zero,
        ),
      ],
    );
  }
}
