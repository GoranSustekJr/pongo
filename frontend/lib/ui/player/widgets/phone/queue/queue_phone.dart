import 'package:flutter/material.dart';

import '../../../../../data/repositories/player/media_items.dart';

import '../../../../../domain/models/playlists/playlist_handler.dart';
import '../../../../playlists/view_models/open_playlist.dart';
import '../../../../shell/view_models/shell_view_model.dart';
import '../../../view_models/player_view_model.dart';
import 'queue_body_phone.dart';

class QueuePhone extends StatefulWidget {
  final bool showQueue;
  final bool lyricsOn;
  final bool lyricsExist;
  final Function() changeShowQueue;
  final Function() changeLyricsOn;

  const QueuePhone({
    super.key,
    required this.showQueue,
    required this.lyricsOn,
    required this.changeShowQueue,
    required this.changeLyricsOn,
    required this.lyricsExist,
  });

  @override
  State<QueuePhone> createState() => _QueuePhoneState();
}

class _QueuePhoneState extends State<QueuePhone> {
  // Edit queue state
  bool editQueue = false;

  // Queue controller
  ScrollController scrollController = ScrollController();

  // Selected queue indexes state
  final List<int> selectedQueueIndexes = [];

  // Function to toggle selection
  void selectQueueIndex(int ind) {
    setState(() {
      if (selectedQueueIndexes.contains(ind)) {
        selectedQueueIndexes.remove(ind);
      } else {
        selectedQueueIndexes.add(ind);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 10), () {
      if (!mounted) return;
      scrollController.jumpTo(context.shell.queueScrollOffset);
      scrollController.addListener(offsetListener);
    });
  }

  void offsetListener() {
    context.shell.queueScrollOffset = scrollController.offset;
  }

  @override
  void dispose() {
    super.dispose();
    scrollController.removeListener(offsetListener);
    scrollController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    final player = context.player;

    return AnimatedPositioned(
      duration: Duration(
        milliseconds:
            widget.showQueue && !(widget.lyricsOn && widget.lyricsExist)
            ? 0
            : 750,
      ),
      top: widget.showQueue && !(widget.lyricsOn && widget.lyricsExist)
          ? 0
          : size.height,
      child: AnimatedOpacity(
        opacity: widget.showQueue && !(widget.lyricsOn && widget.lyricsExist)
            ? 1
            : 0,
        duration: const Duration(milliseconds: 150),
        child: StreamBuilder(
          stream: player.queueStream,
          builder: (context, snapshot) {
            final queue = snapshot.data;
            return StreamBuilder(
              stream: player.shuffleIndicesStream,
              builder: (context, snap) {
                final shuffleIndices = snap.data;
                return StreamBuilder(
                  stream: player.shuffleEnabledStream,
                  builder: (context, snp) {
                    final shuffleModeEnabled =
                        (snp.data ?? false) &&
                        (shuffleIndices != null
                            ? shuffleIndices.isNotEmpty
                            : false);

                    return Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: RepaintBoundary(
                        child: QueueBodyPhone(
                          shuffleModeEnabled: shuffleModeEnabled,
                          editQueue: editQueue,
                          showQueue: widget.showQueue,
                          lyricsOn: widget.lyricsOn,
                          lyricsExist: widget.lyricsExist,
                          scrollController: scrollController,
                          queue: queue ?? [],
                          shuffleIndices: shuffleIndices ?? [],
                          selectedQueueIndexes: selectedQueueIndexes,
                          selectQueueIndex: selectQueueIndex,
                          changeShowQueue: widget.changeShowQueue,
                          changeEditQueue: () {
                            setState(() {
                              if (editQueue == true) {
                                selectedQueueIndexes.clear();
                              }
                              editQueue = !editQueue;
                            });
                          },
                          removeItemsFromQueue: () async {
                            await player.removeFromQueue([
                              ...selectedQueueIndexes,
                            ]);
                            setState(() {
                              editQueue = false;
                              selectedQueueIndexes.clear();
                            });
                          },
                          changeLyricsOn: widget.changeLyricsOn,
                          saveAsPlaylist: () {
                            if (queue != null) {
                              OpenPlaylist().show(
                                context,
                                PlaylistHandler(
                                  type: PlaylistHandlerType.online,
                                  function:
                                      PlaylistHandlerFunction.createPlaylist,
                                  track: queue.map((item) {
                                    final track = item.toTrack();
                                    return PlaylistHandlerOnlineTrack(
                                      id: track.id,
                                      name: track.name,
                                      artist: track.artists,
                                      cover: (item.artUri?.toString() ?? ''),
                                      albumTrack: track.album,
                                      playlistHandlerCoverType:
                                          (item.artUri?.toString() ?? '')
                                              .contains('file:///')
                                          ? PlaylistHandlerCoverType.bytes
                                          : PlaylistHandlerCoverType.url,
                                    );
                                  }).toList(),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
