import 'package:flutter/material.dart';

import '../../../../../domain/models/catalog/track.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../core/ui/space.dart';
import '../../../../player/view_models/player_view_model.dart';
import '../../../view_models/recommendations_view_model.dart';
import 'recommendations_track_row.dart';

class RecommendationsHistory extends StatelessWidget {
  final RecommendationsViewModel dataManager;
  final PlayerViewModel player;

  /// Tracks already shown elsewhere on the page.
  final int skip;
  const RecommendationsHistory({
    super.key,
    required this.dataManager,
    required this.player,
    this.skip = 0,
  });

  @override
  Widget build(BuildContext context) {
    final tracks = dataManager.history.skip(skip).toList();
    if (tracks.isEmpty) return const SizedBox();

    Widget row(Iterable<Track> rowTracks) => RecommendationsTrackRow(
      tracks: rowTracks.toList(),
      dataManager: dataManager,
      player: player,
    );

    return Column(
      children: [
        homeSectionTitle(AppLocalizations.of(context).lastlistenedto),
        razh(10),
        row(tracks.take(25)),
        if (tracks.length > 25) razh(10),
        if (tracks.length > 25) row(tracks.skip(25)),
        razh(30),
      ],
    );
  }
}
