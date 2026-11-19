import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pongo/core/constants/app_icons.dart';
import 'package:pongo/core/state/globals.dart';
import 'package:pongo/features/recommendations/data/recommendations_data_manager.dart';
import 'package:pongo/features/recommendations/presentation/phone/recommendations_body_phone.dart';
import 'package:pongo/l10n/app_localizations.dart';
import 'package:pongo/shared/widgets/phone/buttons/icon_button.dart';
import 'package:pongo/shared/widgets/phone/shimmer/recommended_shimmer.dart';

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
