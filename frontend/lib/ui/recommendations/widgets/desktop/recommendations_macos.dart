import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/app_icons.dart';
import '../../../core/themes/colors.dart';
import '../../../core/ui/phone/buttons/icon_button.dart';
import '../../../core/ui/phone/shimmer/recommended_shimmer.dart';
import '../../view_models/recommendations_view_model.dart';
import 'recommendations_body_macos.dart';

class RecommendationsMacos extends StatelessWidget {
  const RecommendationsMacos({super.key});

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return ChangeNotifierProvider(
      create: (context) => RecommendationsViewModel(
        catalog: context.read(),
        history: context.read(),
        settings: context.read(),
      ),
      child: Consumer<RecommendationsViewModel>(
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
                ? SizedBox(
                    height: size.height, // Constrain height
                    width: size.width,
                    child: Scaffold(
                      extendBody: true,
                      extendBodyBehindAppBar: true,
                      backgroundColor: Col.transp,
                      body: RecommendationsBodyMacos(dataManager: dataManager),
                    ),
                  )
                : /*  const SizedBox(
                          child: Center(
                            child: Text("data"),
                          ),
                        ) */ SizedBox(
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
