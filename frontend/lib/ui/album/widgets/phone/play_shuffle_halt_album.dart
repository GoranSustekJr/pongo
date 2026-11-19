import 'package:flutter/material.dart';

import 'package:pongo/features/player/presentation/phone/play_shuffle_halt_bar.dart';
import 'package:pongo/shared/models/catalog/album.dart';

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
      playingId: "online.album:${album.id}",
      missingTracks: missingTracks,
      loadingShuffle: loadingShuffle,
      color: Colors.white,
      play: play,
      shuffle: shuffle,
    );
  }
}
