import 'package:flutter/material.dart';

import '../../../../domain/models/catalog/album.dart';
import '../../../../domain/models/catalog/track.dart';
import '../../../../utils/platform.dart';
import '../../../core/app_icons.dart';
import '../../../core/ui/phone/trailing.dart';
import '../../../player/view_models/player_view_model.dart';
import '../../../playlists/widgets/phone/playlist_song_tile.dart';

class AlbumBodyPhone extends StatefulWidget {
  final Album album;
  final List<Track> tracks;
  final List missingTracks;
  final List<String> loading;
  final Function(int) play;
  const AlbumBodyPhone({
    super.key,
    required this.album,
    required this.tracks,
    required this.missingTracks,
    required this.loading,
    required this.play,
  });

  @override
  State<AlbumBodyPhone> createState() => _AlbumBodyPhoneState();
}

class _AlbumBodyPhoneState extends State<AlbumBodyPhone> {
  @override
  Widget build(BuildContext context) {
    final player = context.player;
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(top: kIsDesktop ? 5 : 35, left: 0, right: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ListView.builder(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 10,
              ),
              itemCount: widget.tracks.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return PlaylistSongTile(
                  track: widget.tracks[index],
                  first: index == 0,
                  last: index == widget.tracks.length - 1,
                  exists: !widget.missingTracks.contains(
                    widget.tracks[index].id,
                  ),
                  function: () async {
                    await context.player.playCollectionTrack(
                      collectionId: 'online.album:${widget.album.id}',
                      stid: widget.tracks[index].id,
                      index: index,
                      playCollection: () async => widget.play(index),
                    );
                  },
                  trailing: Padding(
                    padding: const EdgeInsets.only(right: 15),
                    child: SizedBox(
                      height: 40,
                      width: 20,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: widget.loading.contains(widget.tracks[index].id)
                            ? const Icon(
                                key: ValueKey(true),
                                AppIcons.loading,
                                color: Colors.white,
                              )
                            : StreamBuilder(
                                key: const ValueKey(false),
                                stream: player.currentItemStream,
                                builder: (context, snapshot) {
                                  final String id = snapshot.data != null
                                      ? snapshot.data!.id
                                      : '';

                                  return Trailing(
                                    forceWhite: true,
                                    show: !widget.loading.contains(
                                      widget.tracks[index].id,
                                    ),
                                    showThis:
                                        id ==
                                            'online.album:${widget.album.id}.${widget.tracks[index].id}' &&
                                        player.currentIndex == index,
                                    trailing: const Padding(
                                      padding: EdgeInsets.only(right: 10),
                                      child: Icon(
                                        key: ValueKey(true),
                                        AppIcons.loading,
                                        color: Colors.white,
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
