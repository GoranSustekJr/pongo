import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:pongo/phone/components/shared/tiles/queue_tile.dart';
import 'package:pongo/exports.dart';

class QueueBodyPhone extends StatelessWidget {
  final bool shuffleModeEnabled;
  final bool editQueue;
  final bool showQueue;
  final bool lyricsOn;
  final List<MediaItem>? queue;
  final List<int> shuffleIndices;
  final List<int> selectedQueueIndexes;
  final Function(int) selectQueueIndex;
  final Function() changeShowQueue;
  final Function() changeEditQueue;
  final Function() removeItemsFromQueue;
  final Function() changeLyricsOn;
  final Function() saveAsPlaylist;
  const QueueBodyPhone({
    super.key,
    required this.queue,
    required this.shuffleModeEnabled,
    required this.editQueue,
    required this.shuffleIndices,
    required this.selectedQueueIndexes,
    required this.selectQueueIndex,
    required this.showQueue,
    required this.lyricsOn,
    required this.changeShowQueue,
    required this.changeEditQueue,
    required this.removeItemsFromQueue,
    required this.changeLyricsOn,
    required this.saveAsPlaylist,
  });

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    final audioServiceHandler =
        Provider.of<AudioHandler>(context, listen: false)
            as AudioServiceHandler;
    return SizedBox(
      height: size.height,
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
                        return ReorderableListView.builder(
                          key: ValueKey("$shuffleModeEnabled"),
                          padding: EdgeInsets.only(
                              top: MediaQuery.of(context).padding.top + 50,
                              bottom: 300),
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
                                                  showThis: id ==
                                                          queue![ind].id &&
                                                      audioServiceHandler
                                                              .audioPlayer
                                                              .currentIndex ==
                                                          ind,
                                                  trailing: const SizedBox())),
                                          razw(5),
                                          const Icon(
                                            AppIcons.burger,
                                            color: Colors.white,
                                            size: 22.5,
                                          ),
                                        ],
                                      )
                                    : SizedBox(
                                        key: const ValueKey(
                                          false,
                                        ),
                                        width: 47.0,
                                        height: 47.0,
                                        child: CupertinoButton(
                                            padding: EdgeInsets.zero,
                                            onPressed: () {
                                              selectQueueIndex(ind);
                                            },
                                            child: Icon(
                                              selectedQueueIndexes.contains(ind)
                                                  ? AppIcons.checkmark
                                                  : AppIcons.uncheckmark,
                                              size: 25,
                                              color: Colors.white,
                                            )),
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
                        );
                      },
                    ),
                    QueueButtonPhone(
                      showQueue: showQueue,
                      lyricsOn: lyricsOn,
                      editQueue: editQueue,
                      changeShowQueue: changeShowQueue,
                      changeEditQueue: changeEditQueue,
                      removeItemsFromQueue: removeItemsFromQueue,
                      changeLyricsOn: changeLyricsOn,
                      saveAsPlaylist: saveAsPlaylist,
                      download: () async {
                        if (queue != null) {
                          List<String> selectedStids = [];
                          for (int i = 0; i < queue!.length; i++) {
                            int ind =
                                shuffleModeEnabled ? shuffleIndices[i] : i;

                            if (selectedQueueIndexes.contains(ind)) {
                              selectedStids.add(queue![ind].id.split('.')[2]);
                            }
                          }
                          if (selectedStids.isEmpty) {
                            selectedStids = queue!
                                .map((mediaItem) => mediaItem.id.split('.')[2])
                                .toList();
                          }

                          // Get the tracks that need to be downloaded
                          List<String> toDownload = await DatabaseHelper()
                              .queryMissingStids(selectedStids);

                          // Open playlist helper and add them to a playlist or create a new playlist
                          OpenPlaylist().show(
                            context,
                            PlaylistHandler(
                              toDownload: toDownload,
                              type: PlaylistHandlerType.offline,
                              function: PlaylistHandlerFunction.addToPlaylist,
                              track: queue!.where((track) {
                                return selectedStids
                                    .contains(track.id.split('.')[2]);
                              }).map(
                                (track) {
                                  return PlaylistHandlerOnlineTrack(
                                    id: track.id.split('.')[2],
                                    name: track.title,
                                    artist: (jsonDecode(
                                            track.extras!["artists"]) as List)
                                        .map((e) => e as Map<String, dynamic>)
                                        .toList(),
                                    cover: track.artUri != null
                                        ? track.artUri.toString()
                                        : "",
                                    playlistHandlerCoverType: track.artUri
                                            .toString()
                                            .contains('file:///')
                                        ? PlaylistHandlerCoverType.bytes
                                        : PlaylistHandlerCoverType.url,
                                  );
                                },
                              ).toList(),
                            ),
                          );
                        }
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
