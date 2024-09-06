import 'package:pongo/phone/views/bottom%20navigation%20bar/current_track_info.dart';
import '../../../exports.dart';
import 'bottom_navigation_bar_navigation.dart';

class Bottom extends StatelessWidget {
  const Bottom({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: showBottomNavBar,
        builder: (context, _, __) {
          return AnimatedSwitcher(
            duration: Duration(milliseconds: showBottomNavBar.value ? 300 : 0),
            child: showBottomNavBar.value
                ? SizedBox(
                    key: const ValueKey(true),
                    height: kIsApple ? 155 : 170,
                    child: Stack(
                      children: [
                        Positioned(
                          bottom: 0,
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width,
                            child: const TrackInfo(),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          child: SizedBox(
                              width: MediaQuery.of(context).size.width,
                              child: const BottomNavBar()),
                        ),
                      ],
                    ),
                  )
                : const SizedBox(
                    key: ValueKey(false),
                  ),
          );
        });
  }
}
