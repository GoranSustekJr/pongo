import 'package:flutter/material.dart';

import '../../../../utils/platform.dart';
import '../../../player/widgets/phone/current_track_info.dart';
import '../../view_models/shell_view_model.dart';
import 'bottom_navigation_bar_navigation.dart';

class Bottom extends StatelessWidget {
  const Bottom({super.key});

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return MediaQuery.removeViewInsets(
      context: context,
      removeBottom: true,
      child: ValueListenableBuilder(
        valueListenable: context.shell.showBottomNavBar,
        builder: (context, _, _) {
          return ValueListenableBuilder(
            valueListenable: context.shell.currentTrackHeight,
            builder: (context, index, child) {
              return ValueListenableBuilder(
                valueListenable: context.shell.playlistHandler,
                builder: (context, index, child) {
                  return SizedBox(
                    key: const ValueKey(true),
                    height: kIsApple ? 165 : 180, // delta = 15
                    child: Stack(
                      children: [
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.fastEaseInToSlowEaseOut,
                          bottom: context.shell.playlistHandler.value != null
                              ? -(size.height / 3)
                              : context.shell.showBottomNavBar.value
                              ? -(context.shell.currentTrackHeight.value /
                                            size.height) *
                                        (size.height / 3) +
                                    60
                              : -(size.height / 3),
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width,
                            child: const TrackInfo(),
                          ),
                        ),
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.fastEaseInToSlowEaseOut,
                          bottom: context.shell.playlistHandler.value != null
                              ? -(size.height / 3)
                              : context.shell.showBottomNavBar.value
                              ? -(context.shell.currentTrackHeight.value /
                                        size.height) *
                                    (size.height / 3)
                              : -(size.height / 3),
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width,
                            child: const BottomNavBar(),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
