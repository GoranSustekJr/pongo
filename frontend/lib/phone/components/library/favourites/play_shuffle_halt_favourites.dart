import '../../../../exports.dart';

class PlayShuffleHaltFavourites extends StatefulWidget {
  final List missingTracks;
  final bool loadingShuffle;
  final bool edit;
  final Widget frontWidget;
  final Widget endWidget;
  final Function() play;
  final Function() shuffle;
  final Function() stopEdit;
  final Function() unfavourite;
  final Function() addToPlaylist;
  final Function() download;
  const PlayShuffleHaltFavourites({
    super.key,
    required this.missingTracks,
    required this.loadingShuffle,
    required this.edit,
    required this.frontWidget,
    required this.endWidget,
    required this.play,
    required this.shuffle,
    required this.stopEdit,
    required this.unfavourite,
    required this.addToPlaylist,
    required this.download,
  });

  @override
  State<PlayShuffleHaltFavourites> createState() =>
      _PlayShuffleHaltFavouritesState();
}

class _PlayShuffleHaltFavouritesState extends State<PlayShuffleHaltFavourites> {
  @override
  Widget build(BuildContext context) {
    final audioServiceHandler =
        Provider.of<AudioHandler>(context) as AudioServiceHandler;
    return StreamBuilder(
        stream: audioServiceHandler.mediaItem.stream,
        builder: (context, mediaItemStream) {
          bool showPlay = mediaItemStream.data == null
              ? true
              : "library.favourites" !=
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
                        Col.icon,
                        () {
                          widget.download();
                        },
                        edgeInsets: EdgeInsets.zero,
                      ),
                      iconButton(
                        AppIcons.musicAlbums,
                        Col.icon,
                        () {
                          widget.addToPlaylist();
                        },
                        edgeInsets: EdgeInsets.zero,
                      ),
                      iconButton(
                        AppIcons.heartSlash,
                        Col.icon,
                        () {
                          widget.unfavourite();
                        },
                        edgeInsets: EdgeInsets.zero,
                      ),
                      iconButton(
                        AppIcons.cancel,
                        Col.icon,
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
                                      ? Col.icon.withAlpha(125)
                                      : Col.icon,
                                ),
                                widget.play,
                                !showPlay || widget.loadingShuffle
                                    ? Col.icon.withAlpha(125)
                                    : Col.icon,
                                padding: EdgeInsets.zero,
                              ),
                              iconTextButton(
                                AppIcons.shuffle,
                                " Shuffle",
                                TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                  color: widget.missingTracks.isNotEmpty
                                      ? Col.icon.withAlpha(125)
                                      : widget.loadingShuffle
                                          ? Col.icon.withAlpha(125)
                                          : Col.icon,
                                ),
                                widget.shuffle,
                                widget.missingTracks.isNotEmpty
                                    ? Col.icon.withAlpha(125)
                                    : widget.loadingShuffle
                                        ? Col.icon.withAlpha(125)
                                        : Col.icon,
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
                                TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                  color: Col.icon,
                                ),
                                () async {
                                  await audioServiceHandler.halt();
                                },
                                Col.icon,
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
