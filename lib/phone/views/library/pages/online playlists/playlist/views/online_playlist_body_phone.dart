import 'dart:ui';
import 'package:pongo/exports.dart';

class OnlinePlaylistBodyPhone extends StatelessWidget {
  final int opid;
  final List<Track> tracks;
  final List missingTracks;
  final List<String> loading;
  final int numberOfSTIDS;
  final bool edit;
  final List<String> selectedTracks;
  final Map<String, bool> hidden;
  final Function(int) play;
  final Function(String) select;
  final Function(int, int) move;
  const OnlinePlaylistBodyPhone({
    super.key,
    required this.opid,
    required this.tracks,
    required this.missingTracks,
    required this.loading,
    required this.numberOfSTIDS,
    required this.edit,
    required this.selectedTracks,
    required this.play,
    required this.select,
    required this.move,
    required this.hidden,
  });

  @override
  Widget build(BuildContext context) {
    // Not hiddent tracks
    List<Track> shownTracks =
        tracks.where((track) => hidden[track.id] != true || edit).toList();

    final audioServiceHandler =
        Provider.of<AudioHandler>(context) as AudioServiceHandler;

    return Padding(
      padding: const EdgeInsets.only(left: 15),
      child: StreamBuilder(
        key: const ValueKey(false),
        stream: audioServiceHandler.mediaItem.stream,
        builder: (context, snapshot) {
          final String id = snapshot.data != null ? snapshot.data!.id : "";

          return ReorderableListView.builder(
            padding: EdgeInsets.only(
              top: 35,
              bottom: MediaQuery.of(context).padding.bottom + 15,
            ),
            itemCount: shownTracks.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            onReorder: (oldIndex, newIndex) {
              if (edit) {}
              move(oldIndex, newIndex);
            },
            proxyDecorator: (child, index, animation) => Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Col.primaryCard.withAlpha(175),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: child,
                ),
              ),
            ),
            itemBuilder: (context, index) {
              return FavouritesTile(
                key: ValueKey(index),
                track: shownTracks[index],
                first: index == 0,
                forceWhite: true,
                last: shownTracks.length - 1 == index,
                exists: !missingTracks.contains(shownTracks[index].id),
                trailing: Padding(
                  padding: const EdgeInsets.only(right: 15),
                  child: SizedBox(
                    child: Row(
                      children: [
                        SizedBox(
                          height: 40,
                          width: 20,
                          child: Trailing(
                              show: !loading.contains(shownTracks[index].id),
                              showThis: id ==
                                      "online.playlist:$opid.${shownTracks[index].id}" &&
                                  audioServiceHandler
                                          .audioPlayer.currentIndex ==
                                      index,
                              trailing: const Icon(
                                key: ValueKey(true),
                                AppIcons.loading,
                                color: Colors.white,
                              )),
                        ),
                        if (edit && hidden[shownTracks[index].id] == true)
                          const SizedBox(
                            height: 40,
                            width: 20,
                            child: Icon(
                              AppIcons.hide,
                              color: Colors.white,
                            ),
                          ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: edit ? 40 : 0,
                          height: 40,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 15),
                            child: iconButton(
                              selectedTracks.contains(shownTracks[index].id)
                                  ? AppIcons.checkmark
                                  : AppIcons.uncheckmark,
                              Colors.white,
                              () {
                                select(shownTracks[index].id);
                              },
                              edgeInsets: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                function: edit
                    ? () {
                        select(shownTracks[index].id);
                      }
                    : () async {
                        final playNew = audioServiceHandler.mediaItem.value !=
                                null
                            ? "${audioServiceHandler.mediaItem.value!.id.split(".")[0]}.${audioServiceHandler.mediaItem.value!.id.split(".")[1]}" !=
                                "online.playlist:$opid"
                            : true;

                        final skipTo =
                            audioServiceHandler.mediaItem.value != null
                                ? audioServiceHandler.mediaItem.value!.id
                                        .split(".")[2] !=
                                    shownTracks[index].id
                                : false;

                        if (playNew) {
                          changeTrackOnTap.value = true;
                          play(index);
                        } else if (skipTo &&
                            (audioServiceHandler.playlist.length - 1) >=
                                index &&
                            changeTrackOnTap.value) {
                          await audioServiceHandler.skipToQueueItem(index);
                        } else {
                          if (audioServiceHandler.audioPlayer.playing) {
                            await audioServiceHandler.pause();
                          } else {
                            await audioServiceHandler.play();
                          }
                        }
                      },
              );
            },
          );
        },
      ),
    );
  }
}
