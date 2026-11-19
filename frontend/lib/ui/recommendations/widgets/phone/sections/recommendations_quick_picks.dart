import 'package:flutter/cupertino.dart';

import '../../../../../domain/models/catalog/track.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../utils/image_resolution.dart';
import '../../../../core/app_icons.dart';
import '../../../../core/themes/colors.dart';
import '../../../../core/ui/image/image_compatible.dart';
import '../../../../core/ui/phone/liquid_glass_background.dart';
import '../../../../core/ui/space.dart';
import '../../../../player/view_models/player_view_model.dart';
import '../../../view_models/recommendations_view_model.dart';
import 'recommendations_track_row.dart';

/// The greeting and the shortcuts to the most recent tracks at the top of home.
class RecommendationsQuickPicks extends StatelessWidget {
  static const count = 6;

  final RecommendationsViewModel dataManager;
  final PlayerViewModel player;
  const RecommendationsQuickPicks({
    super.key,
    required this.dataManager,
    required this.player,
  });

  String _greeting(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return l10n.goodmorning;
    if (hour >= 12 && hour < 18) return l10n.goodafternoon;
    return l10n.goodevening;
  }

  Widget _tile(BuildContext context, Track track) {
    final image = track.album != null
        ? imageUrlForSize(track.album!.images, 300, 300)
        : '';
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => playRecommendedTrack(player, track),
      child: GlassSurface(
        blur: 0,
        tint: context.colors.text,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 56,
              child: image == ''
                  ? Icon(AppIcons.blankTrack, color: context.colors.icon)
                  : ImageCompatible(image: image),
            ),
            razw(10),
            Expanded(
              child: Text(
                track.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: context.colors.text,
                ),
              ),
            ),
            razw(8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tracks = dataManager.history.take(count).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            _greeting(context),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
              color: context.colors.text,
            ),
          ),
        ),
        razh(tracks.isEmpty ? 20 : 14),
        if (tracks.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: GridView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisExtent: 56,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: tracks.length,
              itemBuilder: (context, index) => _tile(context, tracks[index]),
            ),
          ),
          razh(30),
        ],
      ],
    );
  }
}
