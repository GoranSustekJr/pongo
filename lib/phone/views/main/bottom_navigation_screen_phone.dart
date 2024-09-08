import 'package:pongo/exports.dart';
import 'package:pongo/phone/views/library/library_main_phone.dart';
import 'package:pongo/phone/views/playing%20details/playing_details_phone.dart';
import 'package:pongo/phone/views/settings/settings_main_phone.dart';

import '../bottom navigation bar/bottom_navigation_bar.dart';
import '../home/home_main_phone.dart';

class BottomNavigationScreenPhone extends StatefulWidget {
  const BottomNavigationScreenPhone({super.key});

  @override
  State<BottomNavigationScreenPhone> createState() =>
      _BottomNavigationScreenPhoneState();
}

class _BottomNavigationScreenPhoneState
    extends State<BottomNavigationScreenPhone>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final homeNavigatorKey = GlobalKey<NavigatorState>();
  final libraryHomeNavigatorKey = GlobalKey<NavigatorState>();
  final settingsNavigatorKey = GlobalKey<NavigatorState>();

  List<Widget> pages = [];

  @override
  void initState() {
    super.initState();
    pages = [
      HomeMainPhone(homeNavigatorKey: homeNavigatorKey),
      LibraryMainPhone(libraryHomeNavigatorKey: libraryHomeNavigatorKey),
      SettingsMainPhone(settingsHomeNavigatorKey: settingsNavigatorKey),
    ];
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBody: true,
      extendBodyBehindAppBar: true,
      bottomNavigationBar: const Bottom(),
      body: ValueListenableBuilder(
        valueListenable: navigationBarIndex,
        builder: (context, index, child) {
          return Stack(
            children: [
              IndexedStack(
                index: navigationBarIndex.value,
                children: pages,
              ),
              ValueListenableBuilder(
                valueListenable: currentTrackHeight,
                builder: (context, index, child) {
                  return Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    // Use AnimatedContainer for smooth transitions
                    child: GestureDetector(
                      onVerticalDragUpdate: (details) {
                        // Update the panel height when dragging
                        setState(() {
                          currentTrackHeight.value -= details.delta.dy;
                          if (currentTrackHeight.value > size.height) {
                            currentTrackHeight.value = size.height;
                          } else if (currentTrackHeight.value < 0) {
                            currentTrackHeight.value = 0;
                          }
                        });
                      },
                      onVerticalDragEnd: (details) {
                        // Set a threshold for the drag distance
                        const dragThreshold = 40;

                        setState(() {
                          // Check if the drag distance exceeds the threshold
                          if (details.primaryVelocity != null &&
                              details.primaryVelocity! < -dragThreshold) {
                            // If dragged up, snap to full height
                            currentTrackHeight.value = size.height;
                          } else if (details.primaryVelocity != null &&
                              details.primaryVelocity! > dragThreshold) {
                            // If dragged down, snap back to bottom
                            currentTrackHeight.value = 0;
                          } else {
                            // If not enough velocity, check current height to decide snap
                            if (currentTrackHeight.value > size.height - 50) {
                              currentTrackHeight.value =
                                  size.height; // Snap to full height
                            } else {
                              currentTrackHeight.value = 0; // Snap to bottom
                            }
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.fastEaseInToSlowEaseOut,
                        height: currentTrackHeight.value,
                        child: const PlayingDetailsPhone(),
                      ),
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
