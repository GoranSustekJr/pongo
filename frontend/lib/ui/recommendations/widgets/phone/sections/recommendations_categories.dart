import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../../routing/navigation.dart';
import '../../../../../utils/platform.dart';
import '../../../../album/widgets/phone/album_phone.dart';
import '../../../../core/ui/image/image_compatible.dart';
import '../../../../core/ui/space.dart';
import '../../../../player/view_models/player_view_model.dart';
import '../../../../search/widgets/phone/search_result_tile.dart';
import '../../../../shell/view_models/shell_view_model.dart';
import '../../../view_models/recommendations_view_model.dart';
import '../recommended_tile.dart';
import 'recommendations_track_row.dart';

class RecommendationsCategories extends StatelessWidget {
  final RecommendationsViewModel dataManager;
  final PlayerViewModel player;

  /// Shown between the new releases and the genres.
  final Widget? middle;

  const RecommendationsCategories({
    super.key,
    required this.dataManager,
    required this.player,
    this.middle,
  });

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Column(
      children: [
        if (dataManager.newReleases.isNotEmpty) ...[
          homeSectionTitle(AppLocalizations.of(context).newreleases),
          razh(10),
        ],
        if (dataManager.newReleases.isNotEmpty)
          SizedBox(
            height: RecommendedTile.height,
            width: MediaQuery.of(context).size.width,
            child: ListView.builder(
              padding: const EdgeInsets.only(left: 10, right: 10),
              itemCount: dataManager.newReleases.length,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                return RecommendedTile(
                  data: dataManager.newReleases[index],
                  type: TileType.album,
                  showLoading: false,
                  onTap: () {
                    if (kIsMobile) {
                      Navigations().nextScreen(
                        context,
                        AlbumPhone(
                          album: dataManager.newReleases[index],
                          context: context,
                        ),
                      );
                    } else {
                      showMacosSheet(
                        context: context,
                        builder: (contextt) => AlbumPhone(
                          album: dataManager.newReleases[index],
                          context: contextt,
                        ),
                        routeSettings: const RouteSettings(),
                      );
                    }
                  },
                );
              },
            ),
          ),
        if (dataManager.newReleases.isNotEmpty) razh(30),
        ?middle,
        if (dataManager.categories.isNotEmpty) ...[
          homeSectionTitle(AppLocalizations.of(context).genres),
          razh(10),
        ],
        if (dataManager.categories.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7.5),
            child: GridView.builder(
              padding: const EdgeInsets.only(
                top: 0,
                // bottom: MediaQuery.of(context).padding.bottom + 10,
              ),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: kIsDesktop
                    ? size.width > 1200
                          ? 4
                          : 3
                    : 2,
                childAspectRatio: 120 / 80,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
              ),
              itemCount: dataManager.categories.length,
              itemBuilder: (context, index) {
                final Widget child = Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: ImageCompatible(
                          image: dataManager
                              .categories[index]
                              .categoryIcons[0]
                              .url,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withValues(alpha: 0),
                                Colors.black.withValues(alpha: 0.7),
                              ],
                              stops: const [0.4, 1.0],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 12,
                        right: 12,
                        bottom: 10,
                        child: Text(
                          dataManager.categories[index].name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
                return kIsApple
                    ? CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => context.shell.requestSearch(
                          dataManager.categories[index].name,
                        ),
                        child: child,
                      )
                    : CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => context.shell.requestSearch(
                          dataManager.categories[index].name,
                        ),
                        child: child,
                      );
              },
            ),
          ),
      ],
    );
  }
}
