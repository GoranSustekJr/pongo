import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../../data/repositories/player/media_items.dart';
import '../../../../../domain/models/playlists/playlist_handler.dart';
import '../../../../core/app_icons.dart';
import '../../../../core/themes/colors.dart';
import '../../../../core/ui/app_blur.dart';
import '../../../../core/ui/phone/trailing.dart';
import '../../../../core/ui/space.dart';
import '../../../../core/view_models/track_actions_view_model.dart';
import '../../../../playlists/view_models/open_playlist.dart';
import '../../../view_models/player_view_model.dart';
import 'queue_button_phone.dart';
import 'queue_tile.dart';

class QueueBodyPhone extends StatelessWidget {
  final bool shuffleModeEnabled;
  final bool editQueue;
  final bool showQueue;
  final bool lyricsOn;
  final bool lyricsExist;
  final List<MediaItem>? queue;
  final List<int> shuffleIndices;
  final List<int> selectedQueueIndexes;
  final ScrollController scrollController;
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
    required this.lyricsExist,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    final player = context.player;
    return SizedBox(
      height: size.height,
      width: size.width - 20,
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
                      return ReorderableListView.builder(
                        //key: ValueKey("$shuffleModeEnabled"),
                        scrollController: scrollController,
                        padding: EdgeInsets.only(
                          top: MediaQuery.of(context).padding.top + 55,
                          bottom: 300,
                        ),
                        itemCount: queue!.length,
                        shrinkWrap: true,
                        onReorderItem: (oldIndex, newIndex) {
                          // The handlers below expect the index from before the
                          // item is removed
                          if (newIndex > oldIndex) newIndex += 1;
                          player.moveInQueue(oldIndex, newIndex);
                        },
                        proxyDecorator: (child, index, animation) => Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: context.colors.primaryCard.withAlpha(175),
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
                            imageUrl: (queue![ind].artUri?.toString() ?? ''),
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
                                            forceWhite: true,
                                            showThis:
                                                id == queue![ind].id &&
                                                player.currentIndex == ind,
                                            trailing: const SizedBox(),
                                          ),
                                        ),
                                        razw(5),
                                        const Icon(
                                          AppIcons.burger,
                                          color: Colors.white,
                                          size: 22.5,
                                        ),
                                      ],
                                    )
                                  : SizedBox(
                                      key: const ValueKey(false),
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
                                        ),
                                      ),
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
                      );
                    },
                  ),
                  QueueButtonPhone(
                    showQueue: showQueue,
                    lyricsOn: lyricsOn,
                    editQueue: editQueue,
                    lyricsExist: lyricsExist,
                    changeShowQueue: changeShowQueue,
                    changeEditQueue: changeEditQueue,
                    removeItemsFromQueue: removeItemsFromQueue,
                    changeLyricsOn: changeLyricsOn,
                    saveAsPlaylist: saveAsPlaylist,
                    download: () async {
                      if (queue != null) {
                        List<String> selectedStids = [];
                        for (int i = 0; i < queue!.length; i++) {
                          final int ind = shuffleModeEnabled
                              ? shuffleIndices[i]
                              : i;

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
                        final List<String> toDownload = await context
                            .trackActions
                            .missingDownloads(selectedStids);
                        if (!context.mounted) return;

                        // Open playlist helper and add them to a playlist or
                        // create a new playlist
                        OpenPlaylist().show(
                          context,
                          PlaylistHandler(
                            toDownload: toDownload,
                            type: PlaylistHandlerType.offline,
                            function: PlaylistHandlerFunction.addToPlaylist,
                            track: queue!
                                .where((track) {
                                  return selectedStids.contains(
                                    track.id.split('.')[2],
                                  );
                                })
                                .map((item) {
                                  final track = item.toTrack();
                                  return PlaylistHandlerOnlineTrack(
                                    id: track.id,
                                    name: track.name,
                                    artist: track.artists,
                                    cover: item.artUri?.toString() ?? '',
                                    albumTrack: track.album,
                                    playlistHandlerCoverType:
                                        (item.artUri?.toString() ?? '')
                                            .contains('file:///')
                                        ? PlaylistHandlerCoverType.bytes
                                        : PlaylistHandlerCoverType.url,
                                  );
                                })
                                .toList(),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            )
          : const SizedBox(),
    );
  }
}
