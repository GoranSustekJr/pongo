import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:pongo/exports.dart';
import 'package:pongo/phone/components/shared/tiles/queue_tile.dart';

class QueueBodyMacos extends StatelessWidget {
  final bool shuffleModeEnabled;
  final bool editQueue;
  final List<MediaItem>? queue;
  final List<int> shuffleIndices;
  final List<int> selectedQueueIndexes;
  final Function(int) selectQueueIndex;

  const QueueBodyMacos({
    super.key,
    required this.shuffleModeEnabled,
    required this.editQueue,
    this.queue,
    required this.shuffleIndices,
    required this.selectedQueueIndexes,
    required this.selectQueueIndex,
  });

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    final audioServiceHandler =
        Provider.of<AudioHandler>(context, listen: false)
            as AudioServiceHandler;
    return SizedBox(
      height: size.height - 130,
      width: size.width - 20,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: queue != null
            ? ConstrainedBox(
                key: const ValueKey(true),
                constraints: BoxConstraints(minHeight: size.height),
                child: Stack(
                  children: [
                    StreamBuilder(
                      key: const ValueKey(false),
                      stream: audioServiceHandler.mediaItem.stream,
                      builder: (context, snapshot) {
                        final String id =
                            snapshot.data != null ? snapshot.data!.id : "";
                        return Theme(
                          data: ThemeData(
                              iconTheme:
                                  const IconThemeData(color: Colors.white)),
                          child: ReorderableListView.builder(
                            key: ValueKey("$shuffleModeEnabled"),
                            padding: const EdgeInsets.only(
                                // top: MediaQuery.of(context).padding.top + 50,
                                bottom: 0),
                            itemCount: queue!.length,
                            shrinkWrap: true,
                            onReorder: (oldIndex, newIndex) {
                              audioServiceHandler.reorderQueue(
                                  audioServiceHandler, oldIndex, newIndex);
                            },
                            proxyDecorator: (child, index, animation) =>
                                Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Col.primaryCard.withAlpha(175),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                      sigmaX: useBlur.value ? 10 : 0,
                                      sigmaY: useBlur.value ? 10 : 0),
                                  child: child,
                                ),
                              ),
                            ),
                            itemBuilder: (context, index) {
                              int ind = shuffleModeEnabled
                                  ? shuffleIndices[index]
                                  : index;

                              return QueueTile(
                                key: ValueKey(ind),
                                title: queue![ind].title,
                                artist: queue![ind].artist ?? "",
                                imageUrl: queue![ind].artUri.toString(),
                                trailing: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 250),
                                  child: !editQueue
                                      ? Row(
                                          key: const ValueKey(true),
                                          children: [
                                            SizedBox(
                                                height: 40,
                                                width: 20,
                                                child: Trailing(
                                                    show: true,
                                                    forceWhite: false,
                                                    showThis: id ==
                                                            queue![ind].id &&
                                                        audioServiceHandler
                                                                .audioPlayer
                                                                .currentIndex ==
                                                            ind,
                                                    trailing:
                                                        const SizedBox())),
                                            razw(32.5),
                                          ],
                                        )
                                      : Row(
                                          children: [
                                            SizedBox(
                                              key: const ValueKey(
                                                false,
                                              ),
                                              width: 30,
                                              height: 40,
                                              child: CupertinoButton(
                                                  padding: EdgeInsets.zero,
                                                  onPressed: () {
                                                    selectQueueIndex(ind);
                                                  },
                                                  child: Icon(
                                                    selectedQueueIndexes
                                                            .contains(ind)
                                                        ? AppIcons.checkmark
                                                        : AppIcons.uncheckmark,
                                                    size: 25,
                                                    color: Colors.white,
                                                  )),
                                            ),
                                            razw(27.5),
                                          ],
                                        ),
                                ),
                                onTap: () async {
                                  if (!editQueue) {
                                    bool thisPlaying =
                                        audioServiceHandler.mediaItem.value !=
                                                null
                                            ? audioServiceHandler
                                                        .mediaItem.value!.id ==
                                                    queue![ind].id &&
                                                audioServiceHandler.audioPlayer
                                                        .currentIndex ==
                                                    ind
                                            : false;
                                    if (thisPlaying) {
                                      if (audioServiceHandler
                                          .audioPlayer.playing) {
                                        await audioServiceHandler.pause();
                                      } else {
                                        await audioServiceHandler.play();
                                      }
                                    } else {
                                      await audioServiceHandler
                                          .skipToQueueItem(ind);
                                    }
                                  } else {
                                    selectQueueIndex(ind);
                                  }
                                },
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              )
            : const SizedBox(
                key: ValueKey(false),
              ),
      ),
    );
  }
}
