import 'package:pongo/exports.dart';
import 'package:pongo/phone/views/home/recomendations/recommendations%20body/recommendations_categories.dart';
import 'package:pongo/phone/views/home/recomendations/recommendations%20body/recommendations_history.dart';

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
                  AppLocalizations.of(context)!.recommendationsdisabled,
                  style: const TextStyle(
                      fontSize: 17.5, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
    );
  }
}
