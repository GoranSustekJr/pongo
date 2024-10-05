import 'package:pongo/exports.dart';
import 'package:pongo/phone/components/shared/queue/queue_body_phone.dart';

class QueuePhone extends StatefulWidget {
  final bool showQueue;
  final bool lyricsOn;
  final Function() changeShowQueue;
  const QueuePhone({
    super.key,
    required this.showQueue,
    required this.lyricsOn,
    required this.changeShowQueue,
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
      duration: const Duration(milliseconds: 0),
      top: widget.showQueue && !widget.lyricsOn ? 0 : size.height,
      child: AnimatedOpacity(
        opacity: widget.showQueue && !widget.lyricsOn ? 1 : 0,
        duration: Duration(milliseconds: widget.lyricsOn ? 500 : 150),
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
                            ),
                          );
                        });
                  });
            }),
      ),
    );
  }
}
