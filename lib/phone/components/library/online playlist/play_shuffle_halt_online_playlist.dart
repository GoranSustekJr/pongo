import '../../../../exports.dart';

class PlayShuffleHaltOnlinePlaylist extends StatefulWidget {
  final int opid;
  final List missingTracks;
  final bool loadingShuffle;
  final bool edit;
  final Widget frontWidget;
  final Widget endWidget;
  final Function() play;
  final Function() shuffle;
  final Function() stopEdit;
  final Function() unfavourite;
  const PlayShuffleHaltOnlinePlaylist({
    super.key,
    required this.opid,
    required this.missingTracks,
    required this.loadingShuffle,
    required this.edit,
    required this.frontWidget,
    required this.endWidget,
    required this.play,
    required this.shuffle,
    required this.stopEdit,
    required this.unfavourite,
  });

  @override
  State<PlayShuffleHaltOnlinePlaylist> createState() =>
      _PlayShuffleHaltOnlinePlaylistState();
}

class _PlayShuffleHaltOnlinePlaylistState
    extends State<PlayShuffleHaltOnlinePlaylist> {
  @override
  Widget build(BuildContext context) {
    final audioServiceHandler =
        Provider.of<AudioHandler>(context) as AudioServiceHandler;
    return StreamBuilder(
        stream: audioServiceHandler.mediaItem.stream,
        builder: (context, mediaItemStream) {
          bool showPlay = mediaItemStream.data == null
              ? true
              : "library.onlineplaylist:${widget.opid}" !=
                  '${mediaItemStream.data!.id.split('.')[0]}.${mediaItemStream.data!.id.split('.')[1]}';
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.fastOutSlowIn,
            switchOutCurve: Curves.fastOutSlowIn,
            child: widget.edit
                ? Row(
                    key: const ValueKey(true),
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      iconButton(
                        AppIcons.download,
                        Colors.white,
                        () {},
                        edgeInsets: EdgeInsets.zero,
                      ),
                      iconButton(
                        AppIcons.musicAlbums,
                        Colors.white,
                        () {},
                        edgeInsets: EdgeInsets.zero,
                      ),
                      iconButton(
                        AppIcons.heartSlash,
                        Colors.white,
                        () {
                          widget.unfavourite();
                        },
                        edgeInsets: EdgeInsets.zero,
                      ),
                      iconButton(
                        AppIcons.cancel,
                        Colors.white,
                        widget.stopEdit,
                        edgeInsets: EdgeInsets.zero,
                      ),
                    ],
                  )
                : AnimatedSwitcher(
                    key: const ValueKey(false),
                    duration: const Duration(milliseconds: 300),
                    switchInCurve: Curves.fastOutSlowIn,
                    switchOutCurve: Curves.fastOutSlowIn,
                    child: showPlay
                        ? Row(
                            key: const ValueKey(true),
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              widget.frontWidget,
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
                              widget.endWidget
                            ],
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            key: const ValueKey(false),
                            children: [
                              widget.frontWidget,
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
                              widget.endWidget,
                            ],
                          ),
                  ),
          );
        });
  }
}
