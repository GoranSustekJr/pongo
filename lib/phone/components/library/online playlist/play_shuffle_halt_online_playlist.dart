import 'package:flutter/cupertino.dart';

import '../../../../exports.dart';

class PlayShuffleHaltOnlinePlaylist extends StatefulWidget {
  final int opid;
  final List missingTracks;
  final bool loadingShuffle;
  final bool edit;
  final bool allSelected;
  final Widget frontWidget;
  final Widget endWidget;
  final Function() play;
  final Function() shuffle;
  final Function() stopEdit;
  final Function() remove;
  final Function() addToPlaylist;
  final Function() show;
  final Function() hide;
  final Function() selectAll;
  final Function() download;
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
    required this.remove,
    required this.addToPlaylist,
    required this.show,
    required this.hide,
    required this.allSelected,
    required this.selectAll,
    required this.download,
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
              : "online.playlist:${widget.opid}" !=
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
                        () {
                          widget.download();
                        },
                        edgeInsets: EdgeInsets.zero,
                      ),
                      iconButton(
                        AppIcons.musicAlbums,
                        Colors.white,
                        () {
                          widget.addToPlaylist();
                        },
                        edgeInsets: EdgeInsets.zero,
                      ),
                      iconButton(
                        widget.allSelected
                            ? AppIcons.checkmark
                            : AppIcons.uncheckmark,
                        Colors.white,
                        widget.selectAll,
                        edgeInsets: EdgeInsets.zero,
                      ),
                      if (kIsApple)
                        PullDownButton(
                          itemBuilder: (context) {
                            return [
                              PullDownMenuItem(
                                onTap: widget.show,
                                title: AppLocalizations.of(context).show,
                                icon: AppIcons.unhideFill,
                              ),
                              const PullDownMenuDivider(),
                              PullDownMenuItem(
                                onTap: widget.hide,
                                title: AppLocalizations.of(context).hide,
                                icon: AppIcons.hideFill,
                              ),
                            ];
                          },
                          position: PullDownMenuPosition.automatic,
                          buttonBuilder: (context, showMenu) => CupertinoButton(
                            onPressed: showMenu,
                            padding: EdgeInsets.zero,
                            child: const Icon(
                              AppIcons.hide,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      iconButton(
                        AppIcons.trash,
                        Colors.white,
                        () {
                          widget.remove();
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
