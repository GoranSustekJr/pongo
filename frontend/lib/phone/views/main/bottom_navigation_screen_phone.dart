import 'package:pongo/exports.dart';
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
    notificationsContext.value = context;

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
              // The views
              IndexedStack(
                index: navigationBarIndex.value,
                children: pages,
              ),

              // Playing details view
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
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.fastEaseInToSlowEaseOut,
                        height: currentTrackHeight.value,
                        child: RepaintBoundary(
                          child: PlayingDetailsPhone(
                            showArtist: (aid) async {
                              currentTrackHeight.value = 0;
                              navigationBarIndex.value = 0;
                              Map artist = await ArtistSpotify()
                                  .getImage(context, jsonDecode(aid)["id"]);

                              Navigations().nextScreen(
                                  searchScreenContext.value,
                                  ArtistPhone(
                                      artist: Artist(
                                          id: jsonDecode(aid)["id"],
                                          name: jsonDecode(aid)["name"],
                                          image: calculateBestImageForTrack(
                                              (artist["images"]
                                                      as List<dynamic>)
                                                  .map((image) =>
                                                      AlbumImagesTrack(
                                                          url: image["url"],
                                                          height:
                                                              image["height"],
                                                          width:
                                                              image["width"]))
                                                  .toList())),
                                      context: context));
                            },
                            showAlbum: (salid) async {
                              currentTrackHeight.value = 0;
                              navigationBarIndex.value = 0;
                              Map album =
                                  await AlbumSpotify().getData(context, salid);
                              Navigations().nextScreen(
                                searchScreenContext.value,
                                AlbumPhone(
                                  album: Album(
                                      id: album["id"],
                                      name: album["name"],
                                      type: album["album_type"],
                                      artists: album["artists"].map((artist) {
                                        return artist[
                                            "name"]; //{artist["id"]: artist["name"]};
                                      }).toList(),
                                      image: calculateWantedResolution(
                                          album["images"], 300, 300)),
                                  context: context,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Playlist handler view
              ValueListenableBuilder(
                valueListenable: playlistHandler,
                builder: (context, value, child) {
                  return AnimatedPositioned(
                    duration: Duration(
                        milliseconds: animations
                            ? playlistHandler.value != null
                                ? 0
                                : 300
                            : 0),
                    top: playlistHandler.value != null ? 0 : size.height,
                    curve: Curves.easeIn,
                    child: AnimatedOpacity(
                      duration: Duration(
                          milliseconds: animations
                              ? playlistHandler.value != null
                                  ? 500
                                  : 300
                              : 0),
                      curve: Curves.fastEaseInToSlowEaseOut,
                      opacity: playlistHandler.value != null ? 1 : 0,
                      child: AnimatedSwitcher(
                        duration: Duration(milliseconds: animations ? 350 : 0),
                        child: playlistHandler.value != null
                            ? PlaylistHandlerPhone(
                                key: const ValueKey(true),
                                playlistHandler: playlistHandler.value!,
                              )
                            : const SizedBox(
                                key: ValueKey(false),
                              ),
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
