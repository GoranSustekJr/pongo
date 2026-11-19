import 'package:flutter/material.dart';

import '../../../../../domain/models/catalog/track.dart';
import '../../../../core/themes/colors.dart';
import '../../../../core/ui/phone/trailing.dart';
import '../../../../player/view_models/player_view_model.dart';
import '../../../../search/widgets/phone/search_result_tile.dart';
import '../../../view_models/recommendations_view_model.dart';
import '../recommended_tile.dart';

Widget homeSectionTitle(String title) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Builder(
        builder: (context) => Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            color: context.colors.text,
          ),
        ),
      ),
    ),
  );
}

Future<void> playRecommendedTrack(PlayerViewModel player, Track track) =>
    player.playSingle(track, collectionId: 'recommended.single');

class RecommendationsTrackRow extends StatelessWidget {
  final List<Track> tracks;
  final RecommendationsViewModel dataManager;
  final PlayerViewModel player;
  const RecommendationsTrackRow({
    super.key,
    required this.tracks,
    required this.dataManager,
    required this.player,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: RecommendedTile.height,
      width: MediaQuery.of(context).size.width,
      child: ValueListenableBuilder(
        valueListenable: player.fetchingTracks,
        builder: (context, _, _) => ListView.builder(
          padding: const EdgeInsets.only(left: 10, right: 10),
          itemCount: tracks.length,
          scrollDirection: Axis.horizontal,
          itemBuilder: (context, index) {
            final track = tracks[index];
            final loading = player.fetchingTracks.value.contains(track.id);
            return RecommendedTile(
              data: track,
              showLoading: loading,
              type: TileType.track,
              onTap: () => playRecommendedTrack(player, track),
              trailing: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: loading
                    ? const CircularProgressIndicator.adaptive(
                        key: ValueKey(true),
                      )
                    : StreamBuilder(
                        key: const ValueKey(false),
                        stream: player.currentItemStream,
                        builder: (context, snapshot) {
                          final String id = snapshot.data != null
                              ? snapshot.data!.id.split('.')[2]
                              : '';

                          return id == track.id
                              ? StreamBuilder(
                                  stream: player.playingStream,
                                  builder: (context, playingStream) {
                                    return Trailing(
                                      forceWhite: false,
                                      show: !loading,
                                      showThis: id == track.id,
                                      trailing: const Padding(
                                        padding: EdgeInsets.only(right: 10),
                                        child:
                                            CircularProgressIndicator.adaptive(
                                              key: ValueKey(true),
                                            ),
                                      ),
                                    );
                                  },
                                )
                              : const SizedBox();
                        },
                      ),
              ),
            );
          },
        ),
      ),
    );
  }
}
