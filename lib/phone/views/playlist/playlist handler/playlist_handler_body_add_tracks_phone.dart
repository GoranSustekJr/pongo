import 'package:flutter/cupertino.dart';
import 'package:pongo/exports.dart';

class PlaylistHandlerBodyAddTracksPhone extends StatelessWidget {
  final List currentPlaylists;
  final List<MemoryImage?> currentPlaylistsCoverImages;
  final Map playlistTrackMap;
  final List<int> selectedPlaylists;
  final List<PlaylistHandlerTrack>? playlistHandlerTracks;
  final Function(int) selectPlaylist;
  const PlaylistHandlerBodyAddTracksPhone({
    super.key,
    required this.currentPlaylists,
    required this.currentPlaylistsCoverImages,
    required this.playlistTrackMap,
    required this.selectedPlaylists,
    required this.playlistHandlerTracks,
    required this.selectPlaylist,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(
          top: kToolbarHeight * 2 + 10, bottom: kBottomNavigationBarHeight * 2),
      itemCount: currentPlaylists.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(top: 5),
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              selectPlaylist(currentPlaylists[index]["id"]);
            },
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              height: 60,
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  razw(15),
                  Container(
                    height: 55,
                    width: 55,
                    decoration: BoxDecoration(
                      color: Col.primaryCard.withAlpha(125),
                      borderRadius: BorderRadius.circular(7.5),
                    ),
                    child: currentPlaylistsCoverImages[index] != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(7.5),
                            child: FadeInImage(
                              width: 250,
                              fit: BoxFit.cover,
                              height: 250,
                              placeholder: const AssetImage(
                                  'assets/images/placeholder.png'),
                              fadeInDuration: const Duration(milliseconds: 200),
                              fadeOutDuration:
                                  const Duration(milliseconds: 200),
                              image: MemoryImage(
                                currentPlaylistsCoverImages[index]!.bytes,
                              ),
                            ),
                          )
                        : Center(
                            child: Icon(
                              AppIcons.blankTrack,
                              color: Colors.white,
                            ),
                          ),
                  ),
                  razw(15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        currentPlaylists[index]["title"],
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  Expanded(child: Container()),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 15,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child:
                              (playlistTrackMap[currentPlaylists[index]['id']]
                                          .map((entry) => entry["track_id"]))
                                      .contains(playlistHandlerTracks != null
                                          ? playlistHandlerTracks![0].id
                                          : "")
                                  ? const Icon(
                                      key: ValueKey(true),
                                      CupertinoIcons.bookmark_fill,
                                      color: Colors.white,
                                    )
                                  : null,
                        ),
                      ),
                      razw(7.5),
                      SizedBox(
                        width: 10,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: selectedPlaylists
                                  .contains(currentPlaylists[index]['id'])
                              ? const Icon(
                                  key: ValueKey(true),
                                  CupertinoIcons.checkmark_circle,
                                  color: Colors.white,
                                )
                              : const Icon(
                                  key: ValueKey(false),
                                  CupertinoIcons.circle,
                                  color: Colors.white,
                                ),
                        ),
                      ),
                      razw(20),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
