import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:pongo/phone/widgets/special/liquid_glass_background.dart';
import '../../../exports.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final internetConnectivityHandler =
        Provider.of<InternetConnectivityHandler>(context);
    return SafeArea(
      child: Container(
        key: const ValueKey(false),
        margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        padding: const EdgeInsets.all(1),
        constraints: const BoxConstraints(maxWidth: 768),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
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
                      valueListenable: currentBlurhash,
                      builder: (context, signedIn, child) {
                        return AnimatedSwitcher(
                          duration: const Duration(milliseconds: 100),
                          child: Blurhash(
                            key: ValueKey(currentBlurhash.value),
                            blurhash: currentBlurhash.value,
                            sigmaX: 0,
                            sigmaY: 0,
                            child: Container(
                              color: Colors.transparent,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Container(
                  color: Colors.black.withAlpha(50),
                ),
              ),
              BackdropFilter(
                filter: ImageFilter.blur(
                    sigmaX: useBlur.value && !kIsApple ? 10 : 0,
                    sigmaY: useBlur.value && !kIsApple ? 10 : 0),
                child: Container(
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    color: Col.realBackground.withAlpha(useBlur.value
                        ? kIsApple
                            ? 0
                            : 150
                        : 250),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Container(
                    color: darkMode.value
                        ? Col.transp
                        : Colors.black.withAlpha(45),
                    child: ValueListenableBuilder<int>(
                      valueListenable: navigationBarIndex,
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
                                      child: Icon(AppIcons.search,
                                          color: navigationBarIndex.value == 0
                                              ? Colors.white
                                              : Colors.white.withAlpha(150)),
                                      onPressed: () {
                                        navigationBarIndex.value = 0;
                                      }),
                                  CupertinoButton(
                                      child: Icon(AppIcons.library,
                                          color: navigationBarIndex.value == 1
                                              ? Colors.white
                                              : Colors.white.withAlpha(150)),
                                      onPressed: () {
                                        navigationBarIndex.value = 1;
                                      }),
                                  CupertinoButton(
                                      child: Icon(AppIcons.settings,
                                          color: navigationBarIndex.value == 2
                                              ? Colors.white
                                              : Colors.white.withAlpha(150)),
                                      onPressed: () {
                                        navigationBarIndex.value = 2;
                                      }),
                                ],
                              ),
                            ),
                            StreamBuilder(
                              stream: internetConnectivityHandler
                                  .connectivityStream,
                              builder: (context, snapshot) {
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
                                      color: internetConnectivityHandler
                                              .isConnected
                                          ? Colors.blue
                                          : Colors.red,
                                    ), /* PulsatingIcon(
                                        icon: internetConnectivityHandler.isConnected
                                            ? CupertinoIcons.wifi
                                            : CupertinoIcons.wifi_slash,
                                        color: internetConnectivityHandler.isConnected
                                            ? Colors.blue
                                            : Colors.red,
                                      ), */
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
}
