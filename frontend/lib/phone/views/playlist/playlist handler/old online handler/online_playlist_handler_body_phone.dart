import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:pongo/exports.dart';

class OnlinePlaylistHandlerBodyPhone extends StatefulWidget {
  final TextEditingController titleController;
  final bool redIt;
  final bool createPlaylist;
  final List playlists;
  final List<int> selectedPlaylists;
  final List<MemoryImage?> coverImages;
  final Map playlistTrackMap;
  final File? cover;
  final Uint8List? coverBytes;
  final Function() pickImage;
  final Function(String) onChanged;
  final Function() createPlaylistFunction;
  final Function(int) selectPlaylist;
  final Function() changeCreatePlaylist;
  final Function() addTracksToPlalists;
  const OnlinePlaylistHandlerBodyPhone(
      {super.key,
      required this.titleController,
      required this.redIt,
      required this.createPlaylist,
      required this.playlists,
      required this.selectedPlaylists,
      required this.coverImages,
      required this.playlistTrackMap,
      this.cover,
      this.coverBytes,
      required this.pickImage,
      required this.onChanged,
      required this.createPlaylistFunction,
      required this.selectPlaylist,
      required this.changeCreatePlaylist,
      required this.addTracksToPlalists});

  @override
  State<OnlinePlaylistHandlerBodyPhone> createState() =>
      _OnlinePlaylistHandlerBodyPhoneState();
}

class _OnlinePlaylistHandlerBodyPhoneState
    extends State<OnlinePlaylistHandlerBodyPhone> {
  // Height of the multiple track shower
  double height = 0;
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Stack(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: widget.createPlaylist ||
                  playlistTrackToAddData.value == null ||
                  (playlistTrackToAddData.value != null
                      ? playlistTrackToAddData.value!["playlist"] != null
                      : true)
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      key: const ValueKey(true),
                      children: [
                        razh(kToolbarHeight + 30),
                        Container(
                          width: 250,
                          height: 250,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: Col.primaryCard.withAlpha(200),
                          ),
                          child: Stack(
                            children: [
                              if (widget.cover != null ||
                                  (playlistTrackToAddData.value != null
                                      ? playlistTrackToAddData
                                                  .value!["playlist"] !=
                                              null
                                          ? playlistTrackToAddData
                                                      .value!["cover"] !=
                                                  null
                                              ? true
                                              : false
                                          : false
                                      : false))
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: FadeInImage(
                                    width: 250,
                                    fit: BoxFit.cover,
                                    height: 250,
                                    placeholder: const AssetImage(
                                        'assets/images/placeholder.png'),
                                    fadeInDuration:
                                        const Duration(milliseconds: 200),
                                    fadeOutDuration:
                                        const Duration(milliseconds: 200),
                                    image: widget.cover == null ||
                                            (playlistTrackToAddData.value !=
                                                    null
                                                ? playlistTrackToAddData.value![
                                                            "playlist"] !=
                                                        null
                                                    ? playlistTrackToAddData
                                                                    .value![
                                                                "cover"] !=
                                                            null
                                                        ? true
                                                        : false
                                                    : false
                                                : false)
                                        ? NetworkImage(playlistTrackToAddData
                                            .value!["cover"])
                                        : FileImage(
                                            widget.cover!,
                                          ),
                                  ),
                                ),
                              Center(
                                  child: Container(
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(360),
                                    color: Col.primaryCard.withAlpha(200)),
                                child: iconButton(
                                  Icons.camera_alt_rounded,
                                  Colors.white,
                                  size: 30,
                                  widget.pickImage,
                                ),
                              )),
                            ],
                          ),
                        ),
                        razh(25),
                        SizedBox(
                          width: size.width,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: TextFormField(
                              controller: widget.titleController,
                              onChanged: widget.onChanged,
                              decoration: InputDecoration(
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: widget.redIt &&
                                            widget.titleController.value.text
                                                    .trim() ==
                                                ""
                                        ? Colors.red
                                        : Colors.white,
                                  ),
                                ),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: widget.redIt &&
                                            widget.titleController.value.text
                                                    .trim() ==
                                                ""
                                        ? Colors.red
                                        : Colors.white,
                                  ),
                                ),
                                disabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: widget.redIt &&
                                            widget.titleController.value.text
                                                    .trim() ==
                                                ""
                                        ? Colors.red
                                        : Colors.white,
                                  ),
                                ),
                                hintText:
                                    AppLocalizations.of(context).playlistname,
                              ),
                            ),
                          ),
                        ),
                        razh(25),
                        textButton(
                          AppLocalizations.of(context).create,
                          widget.createPlaylistFunction,
                          const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                )
              : ListView.builder(
                  key: const ValueKey(false),
                  padding: const EdgeInsets.only(
                      top: kToolbarHeight * 2 + 10,
                      bottom: kBottomNavigationBarHeight * 2),
                  itemCount: widget.playlists.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: ListTile(
                        onTap: () {
                          widget.selectPlaylist(index);
                        },
                        leading: Container(
                          height: 55,
                          width: 55,
                          decoration: BoxDecoration(
                            color: Col.primaryCard.withAlpha(125),
                            borderRadius: BorderRadius.circular(7.5),
                          ),
                          child: widget.coverImages[index] != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(7.5),
                                  child: FadeInImage(
                                    width: 250,
                                    fit: BoxFit.cover,
                                    height: 250,
                                    placeholder: const AssetImage(
                                        'assets/images/placeholder.png'),
                                    fadeInDuration:
                                        const Duration(milliseconds: 200),
                                    fadeOutDuration:
                                        const Duration(milliseconds: 200),
                                    image: MemoryImage(
                                      widget.coverImages[index]!.bytes,
                                    ),
                                  ), /* Image.memory(
                                                    coverImages[index]!.bytes,
                                                    fit: BoxFit.cover,
                                                  ), */
                                )
                              : Center(
                                  child: Icon(AppIcons.blankTrack),
                                ),
                        ),
                        title: Text(
                          widget.playlists[index]["title"],
                          style: const TextStyle(fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 15,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: (widget.playlistTrackMap[
                                                widget.playlists[index]['opid']]
                                            .map((entry) => entry["track_id"]))
                                        .contains(
                                            playlistTrackToAddData.value!["id"])
                                    ? const Icon(
                                        key: ValueKey(true),
                                        CupertinoIcons.bookmark_fill)
                                    : null,
                              ),
                            ),
                            razw(7.5),
                            SizedBox(
                              width: 10,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: widget.selectedPlaylists.contains(
                                        widget.playlists[index]['opid'])
                                    ? const Icon(
                                        key: ValueKey(true),
                                        CupertinoIcons.checkmark_circle)
                                    : const Icon(
                                        key: ValueKey(false),
                                        CupertinoIcons.circle),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
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
              child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    color: Colors.black.withAlpha(50),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        iconButton(
                          widget.createPlaylist ||
                                  playlistTrackToAddData.value == null ||
                                  (playlistTrackToAddData.value != null
                                      ? playlistTrackToAddData
                                              .value!["playlist"] !=
                                          null
                                      : true)
                              ? AppIcons.x
                              : AppIcons.addToQueue,
                          Colors.white,
                          widget.changeCreatePlaylist,
                        ),
                        Container(
                          width: 1,
                          height: 20,
                          color: Colors.white,
                        ),
                        textButton(
                          AppLocalizations.of(context).cancel,
                          () {
                            showPlaylistHandler.value = false;
                          },
                          const TextStyle(color: Colors.white),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.fastEaseInToSlowEaseOut,
                          width: widget.createPlaylist ||
                                  playlistTrackToAddData.value == null ||
                                  (playlistTrackToAddData.value != null
                                      ? playlistTrackToAddData
                                              .value!["playlist"] !=
                                          null
                                      : true)
                              ? 0
                              : 65,
                          child: Row(
                            children: [
                              Flexible(
                                child: Container(
                                  width: 1,
                                  height: 20,
                                  color: Colors.white,
                                ),
                              ),
                              Flexible(
                                child: iconButton(
                                  CupertinoIcons.plus,
                                  Colors.white,
                                  widget.addTracksToPlalists,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
            ),
          ),
        ),
        /*   SelectedTracksPhone(
          height: height,
          createPlaylist: widget.createPlaylist ||
              playlistTrackToAddData.value == null ||
              (playlistTrackToAddData.value != null
                  ? playlistTrackToAddData.value!["playlist"] != null
                  : true),
          size: size,
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
        ), */
      ],
    );
  }
}
