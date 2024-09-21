import 'package:pongo/exports.dart';

class PlaylistBodyPhone extends StatefulWidget {
  final Playlist playlist;
  final List<Track> tracks;
  final List missingTracks;
  final List<String> loading;
  final Function(int) play;
  const PlaylistBodyPhone({
    super.key,
    required this.playlist,
    required this.tracks,
    required this.missingTracks,
    required this.loading,
    required this.play,
  });

  @override
  State<PlaylistBodyPhone> createState() => _PlaylistBodyPhoneState();
}

class _PlaylistBodyPhoneState extends State<PlaylistBodyPhone>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<Color?> colorAnimation;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    )..repeat(reverse: true);

    colorAnimation = ColorTween(
      begin: Colors.white,
      end: Colors.white.withAlpha(100),
    ).animate(controller);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audioServiceHandler =
        Provider.of<AudioHandler>(context) as AudioServiceHandler;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(
          top: 35,
          left: 15,
          right: 15,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ListView.builder(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom),
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
                            "search.playlist:${widget.playlist.id}"
                        : true;

                    final skipTo = audioServiceHandler.mediaItem.value != null
                        ? audioServiceHandler.mediaItem.value!.id
                                .split(".")[2] !=
                            widget.tracks[index].id
                        : false;

                    if (playNew) {
                      print("play; $index");
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
                  trailing: SizedBox(
                    height: 40,
                    width: 20,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: widget.loading.contains(widget.tracks[index].id)
                          ? const CircularProgressIndicator.adaptive(
                              key: ValueKey(true),
                            )
                          : StreamBuilder(
                              key: const ValueKey(false),
                              stream: audioServiceHandler.mediaItem.stream,
                              builder: (context, snapshot) {
                                final String id = snapshot.data != null
                                    ? snapshot.data!.id.split(".")[2]
                                    : "";

                                return id == widget.tracks[index].id
                                    ? StreamBuilder(
                                        stream: audioServiceHandler
                                            .audioPlayer.playingStream,
                                        builder: (context, playingStream) {
                                          return SizedBox(
                                            width: 20,
                                            height: 40,
                                            child: MiniMusicVisualizer(
                                              color: Colors.white,
                                              radius: 60,
                                              animate:
                                                  playingStream.data ?? false,
                                            ),
                                          );
                                        })
                                    : const SizedBox();
                              },
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
