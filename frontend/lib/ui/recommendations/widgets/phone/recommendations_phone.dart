import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../app/view_models/app_settings_view_model.dart';
import '../../../core/app_icons.dart';
import '../../../core/ui/phone/buttons/icon_button.dart';
import '../../../core/ui/phone/shimmer/recommended_shimmer.dart';
import '../../view_models/recommendations_view_model.dart';
import 'recommendations_body_phone.dart';

class RecommendationsPhone extends StatefulWidget {
  const RecommendationsPhone({super.key});

  @override
  State<RecommendationsPhone> createState() => _RecommendationsPhoneState();
}

class _RecommendationsPhoneState extends State<RecommendationsPhone> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => RecommendationsViewModel(
        catalog: context.read(),
        history: context.read(),
        settings: context.read(),
      ),
      child: Consumer<RecommendationsViewModel>(
        builder: (context, dataManager, child) {
          return AnimatedSwitcher(
            duration: Duration(
              milliseconds: context.readSettings.useAnimations ? 250 : 0,
            ),
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
                            AppIcons.repeat,
                            Colors.white,
                            dataManager.load.execute,
                          ),
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
        },
      ),
    );
  }
}
