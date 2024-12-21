import 'package:pongo/exports.dart';
import 'package:pongo/phone/widgets/library/locals/locals_tile.dart';

class LocalsBodyPhone extends StatefulWidget {
  final LocalsDataManager localsDataManager;

  const LocalsBodyPhone({super.key, required this.localsDataManager});

  @override
  State<LocalsBodyPhone> createState() => _LocalsBodyPhoneState();
}

class _LocalsBodyPhoneState extends State<LocalsBodyPhone> {
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
            return ListView.builder(
              controller: controller,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.localsDataManager.tracks.length,
              itemBuilder: (context, index) {
                return LocalsTile(
                  track: widget.localsDataManager.tracks[index],
                  first: index == 0,
                  last: widget.localsDataManager.tracks.length - 1 == index,
                  trailing: Padding(
                    padding: const EdgeInsets.only(right: 15),
                    child: SizedBox(
                      child: Row(
                        children: [
                          SizedBox(
                              height: 40,
                              width: 20,
                              child: Trailing(
                                show: false,
                                showThis: id ==
                                        "library.locals.${widget.localsDataManager.tracks[index].id}" &&
                                    audioServiceHandler
                                            .audioPlayer.currentIndex ==
                                        index,
                                trailing: const SizedBox(
                                  key: ValueKey(true),
                                ),
                              )),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: widget.localsDataManager.edit ? 40 : 0,
                            height: 40,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 15),
                              child: iconButton(
                                widget.localsDataManager.selectedTracks
                                        .contains(widget
                                            .localsDataManager.tracks[index].id)
                                    ? AppIcons.checkmark
                                    : AppIcons.uncheckmark,
                                Colors.white,
                                () {
                                  widget.localsDataManager.select(widget
                                      .localsDataManager.tracks[index].id);
                                },
                                edgeInsets: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  function: widget.localsDataManager.edit
                      ? () {
                          widget.localsDataManager.select(
                              widget.localsDataManager.tracks[index].id);
                        }
                      : () async {
                          final playNew = audioServiceHandler.mediaItem.value !=
                                  null
                              ? "${audioServiceHandler.mediaItem.value!.id.split(".")[0]}.${audioServiceHandler.mediaItem.value!.id.split(".")[1]}" !=
                                  "library.locals"
                              : true;

                          final skipTo =
                              audioServiceHandler.mediaItem.value != null
                                  ? audioServiceHandler.mediaItem.value!.id
                                          .split(".")[2] !=
                                      widget.localsDataManager.tracks[index].id
                                  : false;

                          if (playNew) {
                            changeTrackOnTap.value = true;
                            print("object");
                            widget.localsDataManager.play(index: index);
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
          }),
    );
  }
}
