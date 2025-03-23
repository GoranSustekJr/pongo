import 'package:pongo/desktop/macos/views/search/recommendations/recommendations_body_macos.dart';
import 'package:pongo/exports.dart';
import 'package:pongo/phone/components/shared/shimmer/recommended_shimmer.dart';

class RecommendationsMacos extends StatelessWidget {
  const RecommendationsMacos({super.key});

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return ChangeNotifierProvider(
      create: (_) => RecommendationsDataManager(context),
      child: Consumer<RecommendationsDataManager>(
        builder: (context, dataManager, child) {
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: dataManager.failed
                ? SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(AppLocalizations.of(context)!.error),
                          iconButton(
                              AppIcons.repeat, Colors.white, dataManager.init),
                        ],
                      ),
                    ),
                  )
                : dataManager.showBody
                    ? SizedBox(
                        height: size.height, // Constrain height
                        width: size.width,
                        child: Scaffold(
                          extendBody: true,
                          extendBodyBehindAppBar: true,
                          backgroundColor: Col.transp,
                          body: RecommendationsBodyMacos(
                              dataManager: dataManager),
                        ),
                      )
                    : /*  const SizedBox(
                          child: Center(
                            child: Text("data"),
                          ),
                        ) */
                    SizedBox(
                        height: size.height,
                        width: size.width,
                        child: Scaffold(
                          extendBody: true,
                          extendBodyBehindAppBar: true,
                          backgroundColor: Col.transp,
                          body: RecommendedShimmer(
                            history: dataManager.historyEnabled,
                            categories: dataManager.categoriesEnabled,
                          ),
                        ),
                      ),
          );
        },
      ),
    );
  }
}
