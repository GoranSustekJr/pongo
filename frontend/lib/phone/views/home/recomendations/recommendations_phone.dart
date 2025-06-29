import 'package:pongo/exports.dart';
import 'package:pongo/phone/components/shared/shimmer/recommended_shimmer.dart';

class RecommendationsPhone extends StatefulWidget {
  const RecommendationsPhone({super.key});

  @override
  State<RecommendationsPhone> createState() => _RecommendationsPhoneState();
}

class _RecommendationsPhoneState extends State<RecommendationsPhone> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RecommendationsDataManager(context),
      child: Consumer<RecommendationsDataManager>(
          builder: (context, dataManager, child) {
        return AnimatedSwitcher(
          duration: Duration(milliseconds: animations ? 250 : 0),
          child: dataManager.failed
              ? SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(AppLocalizations.of(context).error),
                        iconButton(
                            AppIcons.repeat, Colors.white, dataManager.init),
                      ],
                    ),
                  ),
                )
              : dataManager.showBody
                  ? RecommendationsBodyPhone(dataManager: dataManager)
                  : RecommendedShimmer(
                      history: dataManager.historyEnabled,
                      categories: dataManager.categoriesEnabled,
                    ),
        );
      }),
    );
  }
}
