import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../routing/navigation.dart';
import '../../../../utils/result.dart';
import '../../../album/widgets/phone/album_phone.dart';
import '../../../app/view_models/app_settings_view_model.dart';
import '../../../artist/widgets/phone/artist_phone.dart';
import '../../../home/widgets/phone/home_main_phone.dart';
import '../../../library/widgets/phone/library_main_phone.dart';
import '../../../player/widgets/phone/playing_details/playing_details_phone.dart';
import '../../../playlists/widgets/phone/handler/playlist_handler_phone.dart';
import '../../../settings/widgets/phone/settings_main_phone.dart';
import '../../view_models/shell_view_model.dart';
import 'bottom_navigation_bar.dart';

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

  final libraryHomeNavigatorKey = GlobalKey<NavigatorState>();
  final settingsNavigatorKey = GlobalKey<NavigatorState>();

  List<Widget> pages = [];

  @override
  void initState() {
    super.initState();
    pages = [
      HomeMainPhone(homeNavigatorKey: context.shell.homeNavigatorKey),
      LibraryMainPhone(libraryHomeNavigatorKey: libraryHomeNavigatorKey),
      SettingsMainPhone(settingsHomeNavigatorKey: settingsNavigatorKey),
    ];
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBody: true,
      extendBodyBehindAppBar: true,
      bottomNavigationBar: const Bottom(),
      body: ValueListenableBuilder(
        valueListenable: context.shell.navigationBarIndex,
        builder: (context, index, child) {
          return Stack(
            children: [
              // The views
              IndexedStack(
                index: context.shell.navigationBarIndex.value,
                children: pages,
              ),

              // Playing details view
              ValueListenableBuilder(
                valueListenable: context.shell.currentTrackHeight,
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
                          context.shell.currentTrackHeight.value -=
                              details.delta.dy;
                          if (context.shell.currentTrackHeight.value >
                              size.height) {
                            context.shell.currentTrackHeight.value =
                                size.height;
                          } else if (context.shell.currentTrackHeight.value <
                              0) {
                            context.shell.currentTrackHeight.value = 0;
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
                            context.shell.currentTrackHeight.value =
                                size.height;
                          } else if (details.primaryVelocity != null &&
                              details.primaryVelocity! > dragThreshold) {
                            // If dragged down, snap back to bottom
                            context.shell.currentTrackHeight.value = 0;
                          } else {
                            // If not enough velocity, check current height to
                            // decide snap
                            if (context.shell.currentTrackHeight.value >
                                size.height - 50) {
                              context.shell.currentTrackHeight.value =
                                  size.height; // Snap to full height
                            } else {
                              context.shell.currentTrackHeight.value =
                                  0; // Snap to bottom
                            }
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.fastEaseInToSlowEaseOut,
                        height: context.shell.currentTrackHeight.value,
                        child: RepaintBoundary(
                          child: PlayingDetailsPhone(
                            showArtist: (aid) async {
                              final shell = context.shell;
                              shell.showHomeTab();
                              final artist = jsonDecode(aid) as Map;
                              final result = await shell.artist(
                                id: artist['id'] as String,
                                name: artist['name'] as String,
                              );
                              final navigator =
                                  shell.homeNavigatorKey.currentState;
                              if (result case Ok(:final value)
                                  when navigator != null && context.mounted) {
                                Navigations().push(
                                  navigator,
                                  ArtistPhone(artist: value, context: context),
                                );
                              }
                            },
                            showAlbum: (salid) async {
                              final shell = context.shell;
                              shell.showHomeTab();
                              final result = await shell.album(salid);
                              final navigator =
                                  shell.homeNavigatorKey.currentState;
                              if (result case Ok(:final value)
                                  when navigator != null && context.mounted) {
                                Navigations().push(
                                  navigator,
                                  AlbumPhone(album: value, context: context),
                                );
                              }
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
                valueListenable: context.shell.playlistHandler,
                builder: (context, value, child) {
                  return AnimatedPositioned(
                    duration: Duration(
                      milliseconds: context.readSettings.useAnimations
                          ? context.shell.playlistHandler.value != null
                                ? 0
                                : 300
                          : 0,
                    ),
                    top: context.shell.playlistHandler.value != null
                        ? 0
                        : size.height,
                    curve: Curves.easeIn,
                    child: AnimatedOpacity(
                      duration: Duration(
                        milliseconds: context.readSettings.useAnimations
                            ? context.shell.playlistHandler.value != null
                                  ? 500
                                  : 300
                            : 0,
                      ),
                      curve: Curves.fastEaseInToSlowEaseOut,
                      opacity: context.shell.playlistHandler.value != null
                          ? 1
                          : 0,
                      child: AnimatedSwitcher(
                        duration: Duration(
                          milliseconds: context.readSettings.useAnimations
                              ? 350
                              : 0,
                        ),
                        child: context.shell.playlistHandler.value != null
                            ? PlaylistHandlerPhone(
                                key: const ValueKey(true),
                                playlistHandler:
                                    context.shell.playlistHandler.value!,
                              )
                            : const SizedBox(key: ValueKey(false)),
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
