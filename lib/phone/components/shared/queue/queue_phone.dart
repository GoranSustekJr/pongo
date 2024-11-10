import 'package:pongo/exports.dart';
import 'package:pongo/phone/components/shared/queue/queue_body_phone.dart';

class QueuePhone extends StatefulWidget {
  final bool showQueue;
  final bool lyricsOn;
  final Function() changeShowQueue;
  final Function() changeLyricsOn;
  const QueuePhone({
    super.key,
    required this.showQueue,
    required this.lyricsOn,
    required this.changeShowQueue,
    required this.changeLyricsOn,
  });

  @override
  State<QueuePhone> createState() => _QueuePhoneState();
}

class _QueuePhoneState extends State<QueuePhone> {
  // Edit queue
  bool editQueue = false;

  // Selected queue indexes
  final List<int> selectedQueueIndexes = [];

  void selectQueueIndex(int ind) {
    if (selectedQueueIndexes.contains(ind)) {
      setState(() {
        selectedQueueIndexes.remove(ind);
      });
    } else {
      setState(() {
        selectedQueueIndexes.add(ind);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    final audioServiceHandler =
        Provider.of<AudioHandler>(context, listen: false)
            as AudioServiceHandler;
    return AnimatedPositioned(
      duration: Duration(
          milliseconds: widget.showQueue && !widget.lyricsOn ? 0 : 750),
      top: widget.showQueue && !widget.lyricsOn ? 0 : size.height,
      child: AnimatedOpacity(
        opacity: widget.showQueue && !widget.lyricsOn ? 1 : 0,
        duration: Duration(
            milliseconds: widget.lyricsOn || !widget.showQueue ? 150 : 400),
        child: StreamBuilder(
            stream: audioServiceHandler.queue.stream,
            builder: (context, snapshot) {
              final queue = snapshot.data;

              return StreamBuilder(
                  stream: audioServiceHandler.audioPlayer.shuffleIndicesStream,
                  builder: (context, snap) {
                    final shuffleIndices = snap.data;

                    return StreamBuilder(
                        stream: audioServiceHandler
                            .audioPlayer.shuffleModeEnabledStream,
                        builder: (context, snp) {
                          final shuffleModeEnabled = (snp.data ?? false) &&
                              (shuffleIndices != null
                                  ? shuffleIndices.isNotEmpty
                                  : false);
                          return Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: QueueBodyPhone(
                              shuffleModeEnabled: shuffleModeEnabled,
                              editQueue: editQueue,
                              showQueue: widget.showQueue,
                              lyricsOn: widget.lyricsOn,
                              queue: queue ?? [],
                              shuffleIndices: shuffleIndices ?? [],
                              selectedQueueIndexes: selectedQueueIndexes,
                              selectQueueIndex: selectQueueIndex,
                              changeShowQueue: widget.changeShowQueue,
                              changeEditQueue: () {
                                setState(() {
                                  editQueue = !editQueue;
                                });
                              },
                              removeItemsFromQueue: () async {
                                for (int index in selectedQueueIndexes) {
                                  if (audioServiceHandler
                                          .audioPlayer.currentIndex !=
                                      index) {
                                    audioServiceHandler.queue.value
                                        .removeAt(index);
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
                                  /*   OpenPlaylist().open(
                                    context,
                                    playlist: queue.map((track) {
                                      print(track.id);
                                      return track.id.split('.')[2];
                                    }).toList(),
                                  ); */
                                  print("object");
                                  OpenPlaylist().show(
                                    context,
                                    PlaylistHandler(
                                      type: PlaylistHandlerType.online,
                                      function: PlaylistHandlerFunction
                                          .createPlaylist,
                                      track: queue
                                          .map((track) =>
                                              PlaylistHandlerOnlineTrack(
                                                id: track.id.split('.')[2],
                                                name: track.title,
                                                artist: track.artist ?? "",
                                                cover: track.artUri.toString(),
                                                playlistHandlerCoverType:
                                                    PlaylistHandlerCoverType
                                                        .url,
                                              ))
                                          .toList(),
                                    ),
                                  );
                                }
                              },
                            ),
                          );
                        });
                  });
            }),
      ),
    );
  }
}
