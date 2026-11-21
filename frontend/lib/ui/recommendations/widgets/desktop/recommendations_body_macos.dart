import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../player/view_models/player_view_model.dart';
import '../../view_models/recommendations_view_model.dart';
import '../phone/sections/recommendations_categories.dart';
import '../phone/sections/recommendations_charts.dart';
import '../phone/sections/recommendations_history.dart';
import '../phone/sections/recommendations_quick_picks.dart';

class RecommendationsBodyMacos extends StatelessWidget {
  final RecommendationsViewModel dataManager;
  const RecommendationsBodyMacos({super.key, required this.dataManager});

  @override
  Widget build(BuildContext context) {
    final player = context.player;
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      child: dataManager.categoriesEnabled || dataManager.historyEnabled
          ? RefreshIndicator.adaptive(
              displacement: 25,
              edgeOffset: Scaffold.of(context).appBarMaxHeight == null
                  ? MediaQuery.of(context).padding.top +
                        AppBar().preferredSize.height
                  : Scaffold.of(context).appBarMaxHeight!,
              onRefresh: dataManager.load.execute,
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: Scaffold.of(context).appBarMaxHeight == null
                        ? MediaQuery.of(context).padding.top +
                              AppBar().preferredSize.height +
                              20
                        : Scaffold.of(context).appBarMaxHeight! + 20,
                    bottom: MediaQuery.of(context).padding.bottom + 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      RecommendationsQuickPicks(
                        dataManager: dataManager,
                        player: player,
                      ),
                      RecommendationsHistory(
                        dataManager: dataManager,
                        player: player,
                        skip: RecommendationsQuickPicks.count,
                      ),
                      RecommendationsCategories(
                        dataManager: dataManager,
                        player: player,
                        middle: RecommendationsCharts(
                          dataManager: dataManager,
                          player: player,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Text(
                  AppLocalizations.of(context).recommendationsdisabled,
                  style: const TextStyle(
                    fontSize: 17.5,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
    );
  }
}
