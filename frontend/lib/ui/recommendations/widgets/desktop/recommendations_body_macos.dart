import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pongo/core/audio/audio_service_handler.dart';
import 'package:pongo/features/recommendations/data/recommendations_data_manager.dart';
import 'package:pongo/features/recommendations/presentation/phone/sections/recommendations_categories.dart';
import 'package:pongo/features/recommendations/presentation/phone/sections/recommendations_history.dart';
import 'package:pongo/l10n/app_localizations.dart';

class RecommendationsBodyMacos extends StatelessWidget {
  final RecommendationsDataManager dataManager;
  const RecommendationsBodyMacos({super.key, required this.dataManager});

  @override
  Widget build(BuildContext context) {
    final audioServiceHandler =
        Provider.of<AudioHandler>(context, listen: true) as AudioServiceHandler;
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
              onRefresh: dataManager.init,
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
                      if (dataManager.history.isNotEmpty)
                        RecommendationsHistory(
                            dataManager: dataManager,
                            audioServiceHandler: audioServiceHandler),
                      if (dataManager.categories.isNotEmpty ||
                          dataManager.newReleases.isNotEmpty)
                        RecommendationsCategories(
                          dataManager: dataManager,
                          audioServiceHandler: audioServiceHandler,
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
                      fontSize: 17.5, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
    );
  }
}
