import 'package:flutter/material.dart';

import '../../../../domain/models/catalog/album.dart';
import '../../../player/widgets/phone/play_shuffle_halt_bar.dart';

class PlayShuffleHaltAlbum extends StatelessWidget {
  final Album album;
  final List missingTracks;
  final bool loadingShuffle;
  final Function() play;
  final Function() shuffle;
  const PlayShuffleHaltAlbum({
    super.key,
    required this.album,
    required this.missingTracks,
    required this.loadingShuffle,
    required this.play,
    required this.shuffle,
  });

  @override
  Widget build(BuildContext context) {
    return PlayShuffleHaltBar(
      playingId: 'online.album:${album.id}',
      missingTracks: missingTracks,
      loadingShuffle: loadingShuffle,
      color: Colors.white,
      play: play,
      shuffle: shuffle,
    );
  }
}
