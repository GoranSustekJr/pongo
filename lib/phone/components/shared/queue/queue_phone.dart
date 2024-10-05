import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:pongo/exports.dart';
import 'package:pongo/phone/components/shared/tiles/queue_tile.dart';
import 'package:pongo/shared/functions/queue/clear_queue.dart';

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
                            child: SizedBox(
                              height: size.height,
                              width: size.width - 20,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: queue != null
                                    ? ConstrainedBox(
                                        key: const ValueKey(true),
                                        constraints: BoxConstraints(
                                            minHeight: size.height),
                                        child: Stack(
                                          children: [
                                            SingleChildScrollView(
                                              child: Column(
                                                children: <Widget>[
                                                  razh(
                                                    MediaQuery.of(context)
                                                            .padding
                                                            .top +
                                                        50,
                                                  ),
                                                  ListView.builder(
                                                    padding: EdgeInsets.zero,
                                                    itemCount: queue.length,
                                                    shrinkWrap: true,
                                                    physics:
                                                        const NeverScrollableScrollPhysics(),
                                                    itemBuilder:
                                                        (context, index) {
                                                      int ind =
                                                          shuffleModeEnabled
                                                              ? shuffleIndices[
                                                                  index]
                                                              : index;
                                                      return AnimatedSwitcher(
                                                        duration:
                                                            const Duration(
                                                                milliseconds:
                                                                    200),
                                                        child: QueueTile(
                                                          key: ValueKey(ind),
                                                          title:
                                                              queue[ind].title,
                                                          artist: queue[ind]
                                                                  .artist ??
                                                              "",
                                                          imageUrl: queue[ind]
                                                              .artUri
                                                              .toString(),
                                                          trailing:
                                                              AnimatedSwitcher(
                                                            duration:
                                                                const Duration(
                                                                    milliseconds:
                                                                        250),
                                                            child: !editQueue
                                                                ? Row(
                                                                    key: const ValueKey(
                                                                        true),
                                                                    children: [
                                                                      SizedBox(
                                                                        height:
                                                                            40,
                                                                        width:
                                                                            20,
                                                                        child:
                                                                            AnimatedSwitcher(
                                                                          duration:
                                                                              const Duration(milliseconds: 200),
                                                                          child:
                                                                              StreamBuilder(
                                                                            key:
                                                                                const ValueKey(false),
                                                                            stream:
                                                                                audioServiceHandler.mediaItem.stream,
                                                                            builder:
                                                                                (context, snapshot) {
                                                                              final String id = snapshot.data != null ? snapshot.data!.id : "";

                                                                              return id == queue[ind].id && audioServiceHandler.audioPlayer.currentIndex == ind
                                                                                  ? StreamBuilder(
                                                                                      stream: audioServiceHandler.audioPlayer.playingStream,
                                                                                      builder: (context, playingStream) {
                                                                                        return SizedBox(
                                                                                          width: 20,
                                                                                          height: 40,
                                                                                          child: MiniMusicVisualizer(
                                                                                            color: Colors.white,
                                                                                            radius: 60,
                                                                                            animate: playingStream.data ?? false,
                                                                                          ),
                                                                                        );
                                                                                      })
                                                                                  : const SizedBox();
                                                                            },
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      razw(5),
                                                                      const Icon(
                                                                        AppIcons
                                                                            .burger,
                                                                        color: Colors
                                                                            .white,
                                                                        size:
                                                                            22.5,
                                                                      ),
                                                                    ],
                                                                  )
                                                                : SizedBox(
                                                                    key:
                                                                        const ValueKey(
                                                                      false,
                                                                    ),
                                                                    width: 47.0,
                                                                    height:
                                                                        47.0,
                                                                    child: CupertinoButton(
                                                                        padding: EdgeInsets.zero,
                                                                        onPressed: () {
                                                                          selectQueueIndex(
                                                                              ind);
                                                                        },
                                                                        child: Icon(
                                                                          selectedQueueIndexes.contains(ind)
                                                                              ? AppIcons.checkmark
                                                                              : AppIcons.uncheckmark,
                                                                          size:
                                                                              25,
                                                                          color:
                                                                              Colors.white,
                                                                        )),
                                                                  ),
                                                          ),
                                                          onTap: () async {
                                                            if (!editQueue) {
                                                              bool thisPlaying = audioServiceHandler
                                                                          .mediaItem
                                                                          .value !=
                                                                      null
                                                                  ? audioServiceHandler
                                                                              .mediaItem
                                                                              .value!
                                                                              .id ==
                                                                          queue[ind]
                                                                              .id &&
                                                                      audioServiceHandler
                                                                              .audioPlayer
                                                                              .currentIndex ==
                                                                          ind
                                                                  : false;
                                                              if (thisPlaying) {
                                                                if (audioServiceHandler
                                                                    .audioPlayer
                                                                    .playing) {
                                                                  await audioServiceHandler
                                                                      .pause();
                                                                } else {
                                                                  await audioServiceHandler
                                                                      .play();
                                                                }
                                                              } else {
                                                                await audioServiceHandler
                                                                    .skipToQueueItem(
                                                                        ind);
                                                              }
                                                            } else {
                                                              selectQueueIndex(
                                                                  ind);
                                                            }
                                                          },
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                  razh(300),
                                                ],
                                              ),
                                            ),
                                            QueueButtonPhone(
                                              showQueue: widget.showQueue,
                                              lyricsOn: widget.lyricsOn,
                                              editQueue: editQueue,
                                              changeShowQueue:
                                                  widget.changeShowQueue,
                                              changeEditQueue: () {
                                                setState(() {
                                                  editQueue = !editQueue;
                                                });
                                              },
                                              removeItemsFromQueue: () async {
                                                for (int index
                                                    in selectedQueueIndexes) {
                                                  if (audioServiceHandler
                                                          .audioPlayer
                                                          .currentIndex !=
                                                      index) {
                                                    audioServiceHandler
                                                        .queue.value
                                                        .removeAt(index);
                                                    await audioServiceHandler
                                                        .playlist
                                                        .removeAt(index);
                                                  }
                                                }

                                                setState(() {
                                                  editQueue = false;
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                      )
                                    : const SizedBox(
                                        key: ValueKey(false),
                                      ),
                              ),
                            ),
                          );
                        });
                  });
            }),
      ),
    );
  }
}
