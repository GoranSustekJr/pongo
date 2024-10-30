import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:pongo/exports.dart';

class OnlinePlaylistHandlerBodyPhone extends StatelessWidget {
  final String title;
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
      required this.title,
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
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Stack(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: createPlaylist || playlistTrackToAddData.value == null
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
                              if (cover != null)
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
                                    image: FileImage(
                                      cover!,
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
                                  pickImage,
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
                              onChanged: onChanged,
                              decoration: InputDecoration(
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: redIt && title.isEmpty
                                        ? Colors.red
                                        : Colors.white,
                                  ),
                                ),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: redIt && title.isEmpty
                                        ? Colors.red
                                        : Colors.white,
                                  ),
                                ),
                                disabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: redIt && title.isEmpty
                                        ? Colors.red
                                        : Colors.white,
                                  ),
                                ),
                                hintText:
                                    AppLocalizations.of(context)!.playlistname,
                              ),
                            ),
                          ),
                        ),
                        razh(25),
                        textButton(
                          AppLocalizations.of(context)!.create,
                          createPlaylistFunction,
                          const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                )
              : ListView.builder(
                  key: const ValueKey(false),
                  padding: const EdgeInsets.only(top: kToolbarHeight * 2 + 10),
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: ListTile(
                        onTap: () {
                          selectPlaylist(index);
                        },
                        leading: Container(
                          height: 55,
                          width: 55,
                          decoration: BoxDecoration(
                            color: Col.primaryCard.withAlpha(125),
                            borderRadius: BorderRadius.circular(7.5),
                          ),
                          child: coverImages[index] != null
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
                                      coverImages[index]!.bytes,
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
                          playlists[index]["title"],
                          style: const TextStyle(fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 50,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: selectedPlaylists
                                        .contains(playlists[index]['opid'])
                                    ? const Icon(
                                        key: ValueKey(true),
                                        CupertinoIcons.checkmark_circle)
                                    : const Icon(
                                        key: ValueKey(false),
                                        CupertinoIcons.circle),
                              ),
                            ),
                            SizedBox(
                              width: 15,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: (playlistTrackMap[playlists[index]
                                                ['opid']]
                                            .map((entry) => entry["track_id"]))
                                        .contains(
                                            playlistTrackToAddData.value!["id"])
                                    ? const Icon(
                                        key: ValueKey(true),
                                        CupertinoIcons.bookmark_fill)
                                    : null,
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      iconButton(
                        createPlaylist ? AppIcons.x : AppIcons.addToQueue,
                        Colors.white,
                        changeCreatePlaylist,
                      ),
                      Container(
                        width: 1,
                        height: 20,
                        color: Colors.white,
                      ),
                      textButton(
                        AppLocalizations.of(context)!.cancel,
                        () {
                          showPlaylistHandler.value = false;
                        },
                        const TextStyle(color: Colors.white),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.fastEaseInToSlowEaseOut,
                        width: createPlaylist ? 0 : 65,
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
                                addTracksToPlalists,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )),
            ),
          ),
        ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 350),
          curve:
              createPlaylist ? Curves.easeIn : Curves.fastEaseInToSlowEaseOut,
          top: createPlaylist ? -300 : kToolbarHeight,
          left: 0,
          right: 0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(60),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                child: playlistTrackToAddData.value != null
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(7.5),
                            child: CachedNetworkImage(
                              imageUrl: playlistTrackToAddData.value!["cover"]
                                  .toString(),
                              width: 55,
                              height: 55,
                            ),
                          ),
                          razw(10),
                          Flexible(
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                marquee(
                                  "${playlistTrackToAddData.value!["title"]}  ",
                                  const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  1,
                                  null,
                                  height: 22,
                                ),
                                marquee(
                                  "${playlistTrackToAddData.value!["artist"]}  ",
                                  const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  1,
                                  null,
                                  height: 20,
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.max,
                        children: [Text("-")],
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
