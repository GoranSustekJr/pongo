import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/app_icons.dart';
import '../../../../core/themes/colors.dart';
import '../../../../core/ui/app_blur.dart';
import '../../../../core/ui/phone/trailing.dart';
import '../../../../core/ui/space.dart';
import '../../../view_models/player_view_model.dart';
import '../../phone/queue/queue_tile.dart';

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
    final Size size = MediaQuery.of(context).size;

    final player = context.player;
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
                      stream: player.currentItemStream,
                      builder: (context, snapshot) {
                        final String id = snapshot.data != null
                            ? snapshot.data!.id
                            : '';
                        return Theme(
                          data: ThemeData(
                            iconTheme: const IconThemeData(color: Colors.white),
                          ),
                          child: ReorderableListView.builder(
                            key: ValueKey('$shuffleModeEnabled'),
                            padding: const EdgeInsets.only(
                              // top: MediaQuery.of(context).padding.top + 50,
                              bottom: 0,
                            ),
                            itemCount: queue!.length,
                            shrinkWrap: true,
                            onReorderItem: (oldIndex, newIndex) {
                              // The handlers below expect the index from before
                              // the item is removed
                              if (newIndex > oldIndex) newIndex += 1;
                              player.moveInQueue(oldIndex, newIndex);
                            },
                            proxyDecorator: (child, index, animation) =>
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: context.colors.primaryCard.withAlpha(
                                      175,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: BackdropFilter(
                                      filter: appBlur(context, 10),
                                      child: child,
                                    ),
                                  ),
                                ),
                            itemBuilder: (context, index) {
                              final int ind = shuffleModeEnabled
                                  ? shuffleIndices[index]
                                  : index;

                              return QueueTile(
                                key: ValueKey(ind),
                                title: queue![ind].title,
                                artist: queue![ind].artist ?? '',
                                imageUrl:
                                    (queue![ind].artUri?.toString() ?? ''),
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
                                                showThis:
                                                    id == queue![ind].id &&
                                                    player.currentIndex == ind,
                                                trailing: const SizedBox(),
                                              ),
                                            ),
                                            razw(32.5),
                                          ],
                                        )
                                      : Row(
                                          children: [
                                            SizedBox(
                                              key: const ValueKey(false),
                                              width: 30,
                                              height: 40,
                                              child: CupertinoButton(
                                                padding: EdgeInsets.zero,
                                                onPressed: () {
                                                  selectQueueIndex(ind);
                                                },
                                                child: Icon(
                                                  selectedQueueIndexes.contains(
                                                        ind,
                                                      )
                                                      ? AppIcons.checkmark
                                                      : AppIcons.uncheckmark,
                                                  size: 25,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                            razw(27.5),
                                          ],
                                        ),
                                ),
                                onTap: () async {
                                  if (!editQueue) {
                                    final bool thisPlaying =
                                        player.currentItem.value != null
                                        ? player.currentItem.value!.id ==
                                                  queue![ind].id &&
                                              player.currentIndex == ind
                                        : false;
                                    if (thisPlaying) {
                                      if (player.isPlaying) {
                                        await player.pause();
                                      } else {
                                        await player.play();
                                      }
                                    } else {
                                      await player.skipToIndex(ind);
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
            : const SizedBox(key: ValueKey(false)),
      ),
    );
  }
}
