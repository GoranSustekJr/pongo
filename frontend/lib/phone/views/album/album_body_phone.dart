import 'package:pongo/exports.dart';

class AlbumBodyPhone extends StatefulWidget {
  final Album album;
  final List<Track> tracks;
  final List missingTracks;
  final List<String> loading;
  final Function(int) play;
  const AlbumBodyPhone({
    super.key,
    required this.album,
    required this.tracks,
    required this.missingTracks,
    required this.loading,
    required this.play,
  });

  @override
  State<AlbumBodyPhone> createState() => _AlbumBodyPhoneState();
}

class _AlbumBodyPhoneState extends State<AlbumBodyPhone> {
  @override
  Widget build(BuildContext context) {
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
                  bottom: MediaQuery.of(context).padding.bottom + 10),
              itemCount: widget.tracks.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return PlaylistSongTile(
                  track: widget.tracks[index],
                  first: index == 0,
                  last: index == widget.tracks.length - 1,
                  exists:
                      !widget.missingTracks.contains(widget.tracks[index].id),
                  function: () async {
                    final playNew = audioServiceHandler.mediaItem.value != null
                        ? "${audioServiceHandler.mediaItem.value!.id.split(".")[0]}.${audioServiceHandler.mediaItem.value!.id.split(".")[1]}" !=
                            "online.album:${widget.album.id}"
                        : true;

                    final skipTo = audioServiceHandler.mediaItem.value != null
                        ? audioServiceHandler.mediaItem.value!.id
                                .split(".")[2] !=
                            widget.tracks[index].id
                        : false;

                    if (playNew) {
                      changeTrackOnTap.value = true;
                      widget.play(index);
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
                        child: widget.loading.contains(widget.tracks[index].id)
                            ? const Icon(
                                key: ValueKey(true),
                                AppIcons.loading,
                                color: Colors.white,
                              )
                            : StreamBuilder(
                                key: const ValueKey(false),
                                stream: audioServiceHandler.mediaItem.stream,
                                builder: (context, snapshot) {
                                  final String id = snapshot.data != null
                                      ? snapshot.data!.id
                                      : "";

                                  return Trailing(
                                    forceWhite: true,
                                    show: !widget.loading
                                        .contains(widget.tracks[index].id),
                                    showThis: id ==
                                            "online.album:${widget.album.id}.${widget.tracks[index].id}" &&
                                        audioServiceHandler
                                                .audioPlayer.currentIndex ==
                                            index,
                                    trailing: const Padding(
                                      padding: EdgeInsets.only(right: 10),
                                      child: Icon(
                                        key: ValueKey(true),
                                        AppIcons.loading,
                                        color: Colors.white,
                                      ),
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
          ],
        ),
      ),
    );
  }
}
