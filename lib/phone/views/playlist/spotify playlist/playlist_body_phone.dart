import 'package:pongo/exports.dart';

class PlaylistBodyPhone extends StatelessWidget {
  final Playlist playlist;
  final List<Track> tracks;
  final List missingTracks;
  final List<String> loading;
  final MediaItem? mediaItem;
  final Function(int) play;
  const PlaylistBodyPhone({
    super.key,
    required this.playlist,
    required this.tracks,
    required this.missingTracks,
    required this.loading,
    required this.play,
    required this.mediaItem,
  });

  @override
  Widget build(BuildContext context) {
    String id = mediaItem != null ? mediaItem!.id : "";
    final audioServiceHandler =
        Provider.of<AudioHandler>(context) as AudioServiceHandler;
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          top: kIsDesktop ? 5 : 35,
          left: 0,
          right: 0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ListView.builder(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom),
              itemCount: tracks.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return PlaylistSongTile(
                  track: tracks[index],
                  first: index == 0,
                  last: index == tracks.length - 1,
                  exists: !missingTracks.contains(tracks[index].id),
                  function: () async {
                    final playNew = mediaItem != null
                        ? "${mediaItem!.id.split(".")[0]}.${mediaItem!.id.split(".")[1]}" !=
                            "online.playlist:${playlist.id}"
                        : true;

                    final skipTo = mediaItem != null
                        ? mediaItem!.id.split(".")[2] != tracks[index].id
                        : false;

                    if (playNew) {
                      changeTrackOnTap.value = true;
                      play(index);
                    } else if (skipTo &&
                        (audioServiceHandler.playlist.length - 1) >= index &&
                        changeTrackOnTap.value) {
                      await audioServiceHandler.skipToQueueItem(index);
                    } else {
                      if (audioServiceHandler.audioPlayer.playing) {
                        await audioServiceHandler.pause();
                      } else {
                        await audioServiceHandler.play();
                      }
                    }
                  },
                  trailing: Padding(
                    padding: const EdgeInsets.only(right: 15),
                    child: SizedBox(
                      height: 40,
                      width: 20,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: loading.contains(tracks[index].id)
                            ? const Icon(
                                key: ValueKey(true),
                                AppIcons.loading,
                                color: Colors.white,
                              )
                            : Trailing(
                                show: !loading.contains(tracks[index].id),
                                showThis: id ==
                                        "online.playlist:${playlist.id}.${tracks[index].id}" &&
                                    audioServiceHandler
                                            .audioPlayer.currentIndex ==
                                        index,
                                trailing: const Icon(
                                  key: ValueKey(true),
                                  AppIcons.loading,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                );
              },
            ),
            razh(15),
          ],
        ),
      ),
    );
  }
}
