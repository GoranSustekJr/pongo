import 'package:pongo/phone/views/bottom%20navigation%20bar/current_track_info.dart';
import '../../../exports.dart';
import 'bottom_navigation_bar_navigation.dart';

class Bottom extends StatelessWidget {
  const Bottom({super.key});

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return MediaQuery.removeViewInsets(
      context: context,
      removeBottom: true,
      child: ValueListenableBuilder(
          valueListenable: showBottomNavBar,
          builder: (context, _, __) {
            return ValueListenableBuilder(
              valueListenable: currentTrackHeight,
              builder: (context, index, child) {
                return ValueListenableBuilder(
                    valueListenable: playlistHandler,
                    builder: (context, index, child) {
                      return SizedBox(
                        key: const ValueKey(true),
                        height: kIsApple ? 165 : 180, // delta = 15
                        child: Stack(
                          children: [
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.fastEaseInToSlowEaseOut,
                              bottom: playlistHandler.value != null
                                  ? -(size.height / 3)
                                  : showBottomNavBar.value
                                      ? -(currentTrackHeight.value /
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
                              bottom: playlistHandler.value != null
                                  ? -(size.height / 3)
                                  : showBottomNavBar.value
                                      ? -(currentTrackHeight.value /
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
                    });
              },
            );
          }),
    );
  }
}
