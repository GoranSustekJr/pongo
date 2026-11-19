import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';

import '../../../../../domain/models/catalog/playlist.dart';
import '../../../../../domain/models/catalog/track.dart';
import '../../../../../utils/platform.dart';
import '../../../../core/app_icons.dart';
import '../../../../core/ui/phone/trailing.dart';
import '../../../../core/ui/space.dart';
import '../../../../player/view_models/player_view_model.dart';
import '../playlist_song_tile.dart';

class PlaylistBodyPhone extends StatelessWidget {
  final Playlist playlist;
  final List<Track> tracks;
  final List missingTracks;
  final List<String> loading;
  final MediaItem? mediaItem;
  final Function(int) play;
  const PlaylistBodyPhone({
    super.key,
    required this.playlist,
    required this.tracks,
    required this.missingTracks,
    required this.loading,
    required this.play,
    required this.mediaItem,
  });

  @override
  Widget build(BuildContext context) {
    final String id = mediaItem != null ? mediaItem!.id : '';
    final player = context.player;
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(top: kIsDesktop ? 5 : 35, left: 0, right: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ListView.builder(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom,
              ),
              itemCount: tracks.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return PlaylistSongTile(
                  track: tracks[index],
                  first: index == 0,
                  last: index == tracks.length - 1,
                  exists: !missingTracks.contains(tracks[index].id),
                  function: () async {
                    await context.player.playCollectionTrack(
                      collectionId: 'online.playlist:${playlist.id}',
                      stid: tracks[index].id,
                      index: index,
                      playCollection: () async => play(index),
                    );
                  },
                  trailing: Padding(
                    padding: const EdgeInsets.only(right: 15),
                    child: SizedBox(
                      height: 40,
                      width: 20,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: loading.contains(tracks[index].id)
                            ? const Icon(
                                key: ValueKey(true),
                                AppIcons.loading,
                                color: Colors.white,
                              )
                            : Trailing(
                                forceWhite: true,
                                show: !loading.contains(tracks[index].id),
                                showThis:
                                    id ==
                                        'online.playlist:${playlist.id}.${tracks[index].id}' &&
                                    player.currentIndex == index,
                                trailing: const Icon(
                                  key: ValueKey(true),
                                  AppIcons.loading,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                );
              },
            ),
            razh(15),
          ],
        ),
      ),
    );
  }
}
