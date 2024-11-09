import 'package:pongo/exports.dart';
import 'package:pongo/phone/widgets/library/favourites/favourites_tile.dart';
import 'package:spotify_api/spotify_api.dart' as sp;

class OnlinePlaylistBodyPhone extends StatefulWidget {
  final int opid;
  final List<sp.Track> tracks;
  final List missingTracks;
  final List<String> loading;
  final int numberOfSTIDS;
  final bool edit;
  final List<String> selectedTracks;
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
  });

  @override
  State<OnlinePlaylistBodyPhone> createState() =>
      _OnlinePlaylistBodyPhoneState();
}

class _OnlinePlaylistBodyPhoneState extends State<OnlinePlaylistBodyPhone> {
  // Scroll controller
  ScrollController controller = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            itemCount: widget.tracks.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            onReorder: (oldIndex, newIndex) {
              if (widget.edit) {}
              widget.move(oldIndex, newIndex);
            },
            itemBuilder: (context, index) {
              print(widget.missingTracks);
              return FavouritesTile(
                key: ValueKey(index),
                track: widget.tracks[index],
                first: index == 0,
                last: widget.tracks.length - 1 == index,
                exists: !widget.missingTracks.contains(widget.tracks[index].id),
                trailing: Padding(
                  padding: const EdgeInsets.only(right: 15),
                  child: SizedBox(
                    child: Row(
                      children: [
                        SizedBox(
                          height: 40,
                          width: 20,
                          child: Trailing(
                            show: !widget.loading
                                .contains(widget.tracks[index].id),
                            showThis: id ==
                                    "library.onlineplaylist:${widget.opid}.${widget.tracks[index].id}" &&
                                audioServiceHandler.audioPlayer.currentIndex ==
                                    index,
                            trailing: const CircularProgressIndicator.adaptive(
                              key: ValueKey(true),
                            ),
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: widget.edit ? 40 : 0,
                          height: 40,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 15),
                            child: iconButton(
                              widget.selectedTracks
                                      .contains(widget.tracks[index].id)
                                  ? AppIcons.checkmark
                                  : AppIcons.uncheckmark,
                              Colors.white,
                              () {
                                widget.select(widget.tracks[index].id);
                              },
                              edgeInsets: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                function: widget.edit
                    ? () {
                        widget.select(widget.tracks[index].id);
                      }
                    : () async {
                        final playNew = audioServiceHandler.mediaItem.value !=
                                null
                            ? "${audioServiceHandler.mediaItem.value!.id.split(".")[0]}.${audioServiceHandler.mediaItem.value!.id.split(".")[1]}" !=
                                "library.onlineplaylist:${widget.opid}"
                            : true;

                        final skipTo =
                            audioServiceHandler.mediaItem.value != null
                                ? audioServiceHandler.mediaItem.value!.id
                                        .split(".")[2] !=
                                    widget.tracks[index].id
                                : false;

                        if (playNew) {
                          print("play; $index");
                          changeTrackOnTap.value = true;
                          widget.play(index);
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
