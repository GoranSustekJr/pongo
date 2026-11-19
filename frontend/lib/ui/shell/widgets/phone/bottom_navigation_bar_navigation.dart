import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../utils/platform.dart';
import '../../../app/view_models/app_settings_view_model.dart';
import '../../../app/view_models/connectivity_view_model.dart';
import '../../../core/app_icons.dart';
import '../../../core/themes/colors.dart';
import '../../../core/ui/app_blur.dart';
import '../../../core/ui/blurhash/blurhash.dart';
import '../../../player/view_models/player_view_model.dart';
import '../../view_models/shell_view_model.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final internetConnectivityHandler = context.watch<ConnectivityViewModel>();
    if (kIsIOS && context.readSettings.useLiquidGlass) {
      return _glassBar(context, internetConnectivityHandler);
    }
    return SafeArea(
      child: Container(
        key: const ValueKey(false),
        margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        padding: const EdgeInsets.all(1),
        constraints: const BoxConstraints(maxWidth: 768),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.black,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned.fill(
                child: FadeTransition(
                  opacity: const AlwaysStoppedAnimation<double>(1),
                  child: ClipRRect(
                    child: ValueListenableBuilder(
                      valueListenable: context.player.currentBlurhash,
                      builder: (context, signedIn, child) {
                        return AnimatedSwitcher(
                          duration: const Duration(milliseconds: 450),
                          child: Blurhash(
                            key: ValueKey(
                              (context.player.currentBlurhash.value ??
                                  context.colors.defaultBlurhash),
                            ),
                            blurhash:
                                (context.player.currentBlurhash.value ??
                                context.colors.defaultBlurhash),
                            sigmaX: 0,
                            sigmaY: 0,
                            child: Container(color: Colors.transparent),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Container(color: Colors.black.withAlpha(50)),
              ),
              BackdropFilter(
                filter: nonAppleBlur(context, 10),
                child: Container(
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    color: context.colors.realBackground.withAlpha(
                      context.readSettings.useBlur
                          ? kIsApple
                                ? 0
                                : 150
                          : 250,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Container(
                    color: context.readSettings.darkMode
                        ? Col.transp
                        : Colors.black.withAlpha(45),
                    child: ValueListenableBuilder<int>(
                      valueListenable: context.shell.navigationBarIndex,
                      builder: (context, value, child) {
                        return Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Expanded(
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  CupertinoButton(
                                    child: Icon(
                                      AppIcons.search,
                                      color:
                                          context
                                                  .shell
                                                  .navigationBarIndex
                                                  .value ==
                                              0
                                          ? Colors.white
                                          : Colors.white.withAlpha(150),
                                    ),
                                    onPressed: () {
                                      context.shell.navigationBarIndex.value =
                                          0;
                                    },
                                  ),
                                  CupertinoButton(
                                    child: Icon(
                                      AppIcons.library,
                                      color:
                                          context
                                                  .shell
                                                  .navigationBarIndex
                                                  .value ==
                                              1
                                          ? Colors.white
                                          : Colors.white.withAlpha(150),
                                    ),
                                    onPressed: () {
                                      context.shell.navigationBarIndex.value =
                                          1;
                                    },
                                  ),
                                  CupertinoButton(
                                    child: Icon(
                                      AppIcons.settings,
                                      color:
                                          context
                                                  .shell
                                                  .navigationBarIndex
                                                  .value ==
                                              2
                                          ? Colors.white
                                          : Colors.white.withAlpha(150),
                                    ),
                                    onPressed: () {
                                      context.shell.navigationBarIndex.value =
                                          2;
                                    },
                                  ),
                                ],
                              ),
                            ),
                            Builder(
                              builder: (context) {
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.easeInOutCirc,
                                  width:
                                      !internetConnectivityHandler.isConnected
                                      ? 65
                                      : 0,
                                  height: 50,
                                  child: Center(
                                    child: Icon(
                                      internetConnectivityHandler.isConnected
                                          ? CupertinoIcons.wifi
                                          : CupertinoIcons.wifi_slash,
                                      color:
                                          internetConnectivityHandler
                                              .isConnected
                                          ? Colors.blue
                                          : Colors.red,
                                    ) /* PulsatingIcon(
                                        icon: internetConnectivityHandler.isConnected
                                            ? CupertinoIcons.wifi
                                            : CupertinoIcons.wifi_slash,
                                        color: internetConnectivityHandler.isConnected
                                            ? Colors.blue
                                            : Colors.red,
                                      ), */,
                                  ),
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _glassBar(
    BuildContext context,
    ConnectivityViewModel internetConnectivityHandler,
  ) {
    return SafeArea(
      child: ValueListenableBuilder<int>(
        valueListenable: context.shell.navigationBarIndex,
        builder: (context, index, child) {
          return Row(
            children: [
              Expanded(
                child: GlassTabBar.bottom(
                  selectedIndex: index,
                  onTabSelected: (tab) =>
                      context.shell.navigationBarIndex.value = tab,
                  horizontalPadding: 16,
                  verticalPadding: 6,
                  barHeight: 56,
                  iconSize: 24,
                  selectedIconColor: Col.primary,
                  unselectedIconColor: context.colors.text.withAlpha(170),
                  tabs: [
                    GlassTab(
                      icon: const Icon(AppIcons.home),
                      activeIcon: const Icon(AppIcons.homeFill),
                      semanticLabel: AppLocalizations.of(context).search,
                    ),
                    GlassTab(
                      icon: Icon(AppIcons.library),
                      activeIcon: const Icon(AppIcons.libraryFill),
                      semanticLabel: AppLocalizations.of(context).library,
                    ),
                    GlassTab(
                      icon: Icon(AppIcons.settings),
                      activeIcon: const Icon(CupertinoIcons.settings_solid),
                      semanticLabel: AppLocalizations.of(context).settings,
                    ),
                  ],
                ),
              ),
              Builder(
                builder: (context) {
                  return internetConnectivityHandler.isConnected
                      ? const SizedBox()
                      : const Padding(
                          padding: EdgeInsets.only(right: 16),
                          child: Icon(
                            CupertinoIcons.wifi_slash,
                            color: Colors.red,
                          ),
                        );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
