import 'package:flutter/material.dart';

import 'package:pongo/features/player/presentation/phone/play_shuffle_halt_bar.dart';
import 'package:pongo/shared/models/catalog/playlist.dart';

class PlayShuffleHaltPlaylist extends StatelessWidget {
  final Playlist playlist;
  final List missingTracks;
  final bool loadingShuffle;
  final Function() play;
  final Function() shuffle;
  const PlayShuffleHaltPlaylist({
    super.key,
    required this.playlist,
    required this.missingTracks,
    required this.loadingShuffle,
    required this.play,
    required this.shuffle,
  });

  @override
  Widget build(BuildContext context) {
    return PlayShuffleHaltBar(
      playingId: "online.playlist:${playlist.id}",
      missingTracks: missingTracks,
      loadingShuffle: loadingShuffle,
      color: Colors.white,
      play: play,
      shuffle: shuffle,
    );
  }
}
