import '../../../exports.dart';

class PlayShuffleHaltPlaylist extends StatefulWidget {
  final Playlist playlist;
  final List missingTracks;
  final bool loadingShuffle;
  final Function() play;
  final Function() shuffle;
  const PlayShuffleHaltPlaylist({
    super.key,
    required this.playlist,
    required this.missingTracks,
    required this.loadingShuffle,
    required this.play,
    required this.shuffle,
  });

  @override
  State<PlayShuffleHaltPlaylist> createState() =>
      _PlayShuffleHaltPlaylistState();
}

class _PlayShuffleHaltPlaylistState extends State<PlayShuffleHaltPlaylist> {
  // Pulsating shuffle icon
  /*  late AnimationController controller;
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
  } */

  @override
  Widget build(BuildContext context) {
    final audioServiceHandler =
        Provider.of<AudioHandler>(context) as AudioServiceHandler;
    return StreamBuilder(
        stream: audioServiceHandler.mediaItem.stream,
        builder: (context, mediaItemStream) {
          bool showPlay = mediaItemStream.data == null
              ? true
              : "search.playlist:${widget.playlist.id}" !=
                  '${mediaItemStream.data!.id.split('.')[0]}.${mediaItemStream.data!.id.split('.')[1]}';
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: showPlay
                ? Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      iconTextButton(
                        AppIcons.play,
                        "Play",
                        TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: !showPlay || widget.loadingShuffle
                              ? Colors.white.withAlpha(125)
                              : Colors.white,
                        ),
                        widget.play,
                        !showPlay || widget.loadingShuffle
                            ? Colors.white.withAlpha(125)
                            : Colors.white,
                        padding: EdgeInsets.zero,
                      ),
                      iconTextButton(
                        AppIcons.shuffle,
                        " Shuffle",
                        TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: widget.missingTracks.isNotEmpty
                              ? Colors.white.withAlpha(125)
                              : widget.loadingShuffle
                                  ? Colors.white.withAlpha(125)
                                  : Colors.white,
                        ),
                        widget.shuffle,
                        widget.missingTracks.isNotEmpty
                            ? Colors.white.withAlpha(125)
                            : widget.loadingShuffle
                                ? Colors.white.withAlpha(125)
                                : Colors.white,
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  )
                : Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    key: const ValueKey(false),
                    children: [
                      iconTextButton(
                        AppIcons.halt,
                        " Halt",
                        const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                        () async {
                          await audioServiceHandler.halt();
                        },
                        Colors.white,
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
          );
        });
  }
}
