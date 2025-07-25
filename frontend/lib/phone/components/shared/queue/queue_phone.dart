import 'package:pongo/exports.dart';

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
      scrollController.jumpTo(queueScrollOffset);
      scrollController.addListener(offsetListener);
    });
  }

  void offsetListener() {
    queueScrollOffset = scrollController.offset;
  }

  @override
  void dispose() {
    super.dispose();
    scrollController.removeListener(offsetListener);
    scrollController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    final audioServiceHandler =
        Provider.of<AudioHandler>(context, listen: false)
            as AudioServiceHandler;

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
          stream: audioServiceHandler.queue.stream,
          builder: (context, snapshot) {
            final queue = snapshot.data;
            return StreamBuilder(
              stream: audioServiceHandler.audioPlayer.shuffleIndicesStream,
              builder: (context, snap) {
                final shuffleIndices = snap.data;
                return StreamBuilder(
                  stream:
                      audioServiceHandler.audioPlayer.shuffleModeEnabledStream,
                  builder: (context, snp) {
                    final shuffleModeEnabled = (snp.data ?? false) &&
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
                            final selectedIndexes = selectedQueueIndexes;
                            selectedIndexes.sort();
                            for (int index in selectedIndexes.reversed) {
                              if (audioServiceHandler
                                      .audioPlayer.currentIndex !=
                                  index) {
                                audioServiceHandler.queue.value.removeAt(index);
                                await audioServiceHandler.playlist
                                    .removeAt(index);
                              }
                              changeTrackOnTap.value = false;
                            }
                            setState(() {
                              editQueue = false;
                              selectedQueueIndexes.clear();
                            });
                          },
                          changeLyricsOn: widget.changeLyricsOn,
                          saveAsPlaylist: () {
                            if (queue != null) {
                              if (premium.value) {
                                OpenPlaylist().show(
                                  context,
                                  PlaylistHandler(
                                    type: PlaylistHandlerType.online,
                                    function:
                                        PlaylistHandlerFunction.createPlaylist,
                                    track: queue.map((track) {
                                      return PlaylistHandlerOnlineTrack(
                                        id: track.id.split('.')[2],
                                        name: track.title,
                                        artist: track.artist != null
                                            ? (jsonDecode(track
                                                        .extras!["artists"])
                                                    as List)
                                                .map((e) =>
                                                    e as Map<String, dynamic>)
                                                .toList()
                                            : [],
                                        cover: track.artUri.toString(),
                                        albumTrack: track.album != null
                                            ? AlbumTrack(
                                                id: track.extras!["album"]
                                                    .split("..Ææ..")[0],
                                                name: track.album!,
                                                releaseDate:
                                                    track.extras!["released"],
                                                images: track.artUri != null
                                                    ? [
                                                        AlbumImagesTrack(
                                                            url: track.artUri!
                                                                .toString(),
                                                            height: null,
                                                            width: null)
                                                      ]
                                                    : [],
                                              )
                                            : null,
                                        playlistHandlerCoverType: track.artUri
                                                .toString()
                                                .contains("file:///")
                                            ? PlaylistHandlerCoverType.bytes
                                            : PlaylistHandlerCoverType.url,
                                      );
                                    }).toList(),
                                  ),
                                );
                              } else {
                                Notifications().showSpecialNotification(
                                    notificationsContext.value!,
                                    AppLocalizations.of(
                                            notificationsContext.value!)
                                        .error,
                                    AppLocalizations.of(
                                            notificationsContext.value!)
                                        .premiumisneededtosavethequeue,
                                    AppIcons.warning, onTap: () {
                                  if (!premium.value) {
                                    currentTrackHeight.value = 0;
                                    navigationBarIndex.value = 2;
                                  }
                                });
                              }
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
