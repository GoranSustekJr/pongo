// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../../domain/models/playlists/playlist_handler.dart';
import '../../../../../domain/models/playlists/user_playlist.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../app/view_models/app_settings_view_model.dart';
import '../../../../core/app_icons.dart';
import '../../../../core/ui/app_blur.dart';
import '../../../../core/ui/buttons/text_button.dart';
import '../../../../core/ui/phone/buttons/icon_button.dart';
import '../../../../core/ui/phone/liquid_glass_background.dart';
import '../../../../shell/view_models/shell_view_model.dart';
import 'playlist_handler_body_add_playlist_phone.dart';
import 'playlist_handler_body_add_tracks_phone.dart';
import 'selected_tracks_phone.dart';

class PlaylistHandlerBodyPhone extends StatefulWidget {
  final List<PlaylistHandlerTrack>? playlistHandlerTracks;
  final bool showCreatePlaylist;
  final bool onlyCreatePlaylist;
  final bool working;
  final List<UserPlaylist> currentPlaylists;
  final TextEditingController titleController;
  final Map<int, Set<String>> playlistTrackMap;
  final Object? newPlaylistCover;
  final List<int> selectedPlaylists;
  final Function() createPlaylistFunction;
  final Function() addTracksToPlaylists;
  final Function() changeCreatePlaylist;
  final Function(int) selectPlaylist;
  final Function() pickImage;
  final Function(String) onChanged;
  const PlaylistHandlerBodyPhone({
    super.key,
    required this.playlistHandlerTracks,
    required this.showCreatePlaylist,
    required this.onlyCreatePlaylist,
    required this.createPlaylistFunction,
    required this.addTracksToPlaylists,
    required this.changeCreatePlaylist,
    required this.currentPlaylists,
    required this.playlistTrackMap,
    required this.selectedPlaylists,
    required this.selectPlaylist,
    required this.pickImage,
    this.newPlaylistCover,
    required this.titleController,
    required this.onChanged,
    required this.working,
  });

  @override
  State<PlaylistHandlerBodyPhone> createState() =>
      _PlaylistHandlerBodyPhoneState();
}

class _PlaylistHandlerBodyPhoneState extends State<PlaylistHandlerBodyPhone> {
  // Height of the multiple track shower
  double height = 0;

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Stack(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child:
              widget.showCreatePlaylist ||
                  widget.onlyCreatePlaylist ||
                  widget.playlistHandlerTracks == null
              ? PlaylistHandlerBodyAddPlaylistPhone(
                  key: const ValueKey(true),
                  cover: widget.newPlaylistCover,
                  titleController: widget.titleController,
                  pickImage: widget.pickImage,
                  onChanged: widget.onChanged,
                  createPlaylistFunction: widget.createPlaylistFunction,
                )
              : PlaylistHandlerBodyAddTracksPhone(
                  currentPlaylists: widget.currentPlaylists,
                  playlistTrackMap: widget.playlistTrackMap,
                  selectedPlaylists: widget.selectedPlaylists,
                  playlistHandlerTracks: widget.playlistHandlerTracks,
                  selectPlaylist: widget.selectPlaylist,
                ),
        ),
        Positioned(
          bottom: kBottomNavigationBarHeight,
          left: 0,
          right: 0,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(60),
              child: liquidGlassBackground(
                child: BackdropFilter(
                  filter: nonAppleBlur(context, 5),
                  child: Container(
                    color: Colors.black.withAlpha(
                      context.readSettings.useBlur ? 50 : 200,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 350),
                          transform: !widget.onlyCreatePlaylist
                              ? Matrix4.translationValues(0, 0, 0)
                              : Matrix4.translationValues(-20, 0, 0),
                          curve: Curves.fastEaseInToSlowEaseOut,
                          width: widget.onlyCreatePlaylist ? 0 : 65,
                          child: iconButton(
                            widget.showCreatePlaylist
                                ? AppIcons.x
                                : AppIcons.addToQueue,
                            widget.onlyCreatePlaylist
                                ? Colors.transparent
                                : Colors.white,
                            widget.changeCreatePlaylist,
                            edgeInsets: EdgeInsets.zero,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 25),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 350),
                            width: widget.onlyCreatePlaylist ? 0 : 1,
                            height: 20,
                            color: Colors.white,
                          ),
                        ),
                        textButton(
                          AppLocalizations.of(context).cancel,
                          () {
                            if (!widget.working) {
                              context.shell.playlistHandler.value = null;
                            }
                          },
                          const TextStyle(color: Colors.white, fontSize: 20),
                          edgeInsets: EdgeInsets.zero,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 25),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 350),
                            width: widget.showCreatePlaylist ? 0 : 1,
                            height: 20,
                            color: Colors.white,
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.fastEaseInToSlowEaseOut,
                          width: widget.showCreatePlaylist ? 0 : 65,
                          child: iconButton(
                            CupertinoIcons.plus,
                            Colors.white,
                            widget.addTracksToPlaylists,
                            edgeInsets: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (widget.playlistHandlerTracks != null)
          SelectedTracksPhone(
            show:
                widget.showCreatePlaylist ||
                widget.onlyCreatePlaylist ||
                widget.playlistHandlerTracks == null,
            playlistHandlerTracks: widget.playlistHandlerTracks!,
            height: height,
            onVerticalDragEnd: (details) {
              // Set a threshold for the drag distance
              const dragThreshold = 10;

              setState(() {
                // Check if the drag distance exceeds the threshold
                if (details.primaryVelocity != null &&
                    details.primaryVelocity! < -dragThreshold) {
                  // If dragged up, snap to full height
                  height = 0;
                } else if (details.primaryVelocity != null &&
                    details.primaryVelocity! < dragThreshold) {
                  // If dragged down, snap back to bottom
                  height = size.height / 2.5;
                } else {
                  // If not enough velocity, check current height to decide snap
                  if (height > dragThreshold) {
                    height = size.height / 2.5; // Snap to full height
                  } else {
                    height = 0; // Snap to bottom
                  }
                }
              });
            },
            onVerticalDragUpdate: (details) {
              setState(() {
                height += details.delta.dy;
                if (height > size.height / 2.5) {
                  height = size.height / 2.5;
                } else if (height < 0) {
                  height = 0;
                }
              });
            },
          ),
      ],
    );
  }
}
