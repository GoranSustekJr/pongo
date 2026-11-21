import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../../routing/navigation.dart';
import '../../../../artist/widgets/phone/artist_phone.dart';
import '../../../../core/ui/space.dart';
import '../../../../player/view_models/player_view_model.dart';
import '../../../../playlists/widgets/phone/catalog/playlist_phone.dart';
import '../../../../search/widgets/phone/search_result_tile.dart';
import '../../../view_models/recommendations_view_model.dart';
import '../recommended_tile.dart';
import 'recommendations_track_row.dart';

class RecommendationsCharts extends StatelessWidget {
  final RecommendationsViewModel dataManager;
  final PlayerViewModel player;
  const RecommendationsCharts({
    super.key,
    required this.dataManager,
    required this.player,
  });

  Widget _row<T extends Object>(
    List<T> items,
    TileType type,
    Widget Function(BuildContext, T) page,
  ) {
    return Builder(
      builder: (context) {
        return SizedBox(
          height: RecommendedTile.height,
          width: MediaQuery.of(context).size.width,
          child: ListView.builder(
            padding: const EdgeInsets.only(left: 10, right: 10),
            itemCount: items.length,
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) => RecommendedTile(
              data: items[index],
              type: type,
              showLoading: false,
              onTap: () {
                Navigations().catalogScreen(
                  context,
                  (context) => page(context, items[index]),
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        if (dataManager.topTracks.isNotEmpty) ...[
          homeSectionTitle(l10n.toptracks),
          razh(10),
          RecommendationsTrackRow(
            tracks: dataManager.topTracks,
            dataManager: dataManager,
            player: player,
          ),
          razh(30),
        ],
        if (dataManager.topArtists.isNotEmpty) ...[
          homeSectionTitle(l10n.popularartists),
          razh(10),
          _row(
            dataManager.topArtists,
            TileType.artist,
            (context, artist) => ArtistPhone(context: context, artist: artist),
          ),
          razh(30),
        ],
        if (dataManager.topPlaylists.isNotEmpty) ...[
          homeSectionTitle(l10n.featuredplaylists),
          razh(10),
          _row(
            dataManager.topPlaylists,
            TileType.playlist,
            (context, playlist) =>
                PlaylistPhone(context: context, playlist: playlist),
          ),
          razh(30),
        ],
      ],
    );
  }
}
