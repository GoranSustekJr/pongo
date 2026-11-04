import 'package:pongo/exports.dart';

class FavouritesBodyPhone extends StatefulWidget {
  final List<Track> favourites;
  final List missingTracks;
  final List<String> loading;
  final int numberOfSTIDS;
  final bool edit;
  final List<String> selectedTracks;
  final Function(int) play;
  final Function(String) select;
  const FavouritesBodyPhone({
    super.key,
    required this.favourites,
    required this.missingTracks,
    required this.loading,
    required this.play,
    required this.numberOfSTIDS,
    required this.edit,
    required this.select,
    required this.selectedTracks,
  });

  @override
  State<FavouritesBodyPhone> createState() => _FavouritesBodyPhoneState();
}

class _FavouritesBodyPhoneState extends State<FavouritesBodyPhone> {
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
      padding: const EdgeInsets.only(left: 0),
      child: StreamBuilder(
          key: const ValueKey(false),
          stream: audioServiceHandler.mediaItem.stream,
          builder: (context, snapshot) {
            final String id = snapshot.data != null ? snapshot.data!.id : "";
            return ListView.builder(
              controller: controller,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.favourites.length + 1,
              itemBuilder: (context, index) {
                if (index == widget.favourites.length) {
                  return widget.numberOfSTIDS != index
                      ? const CircularProgressIndicator.adaptive()
                      : const SizedBox();
                }
                return FavouritesTile(
                  track: widget.favourites[index],
                  first: index == 0,
                  forceWhite: false,
                  last: widget.favourites.length - 1 == index,
                  exists: !widget.missingTracks
                      .contains(widget.favourites[index].id),
                  trailing: Padding(
                    padding: const EdgeInsets.only(right: 0),
                    child: SizedBox(
                      child: Row(
                        children: [
                          SizedBox(
                              height: 40,
                              width: 25,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 5),
                                child: Trailing(
                                  forceWhite: false,
                                  show: !widget.loading
                                      .contains(widget.favourites[index].id),
                                  showThis: id ==
                                          "library.favourites.${widget.favourites[index].id}" &&
                                      audioServiceHandler
                                              .audioPlayer.currentIndex ==
                                          index,
                                  trailing:
                                      const CircularProgressIndicator.adaptive(
                                    key: ValueKey(true),
                                  ),
                                ),
                              ) /* AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: widget.loading.contains(widget.favourites[index].id)
                                  ? const CircularProgressIndicator.adaptive(
                                      key: ValueKey(true),
                                    )
                                  : const SizedBox()), */
                              ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: widget.edit ? 40 : 0,
                            height: 40,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 0),
                              child: iconButton(
                                widget.selectedTracks
                                        .contains(widget.favourites[index].id)
                                    ? AppIcons.checkmark
                                    : AppIcons.uncheckmark,
                                Col.icon,
                                () {
                                  widget.select(widget.favourites[index].id);
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
                          widget.select(widget.favourites[index].id);
                        }
                      : () async {
                          final playNew = audioServiceHandler.mediaItem.value !=
                                  null
                              ? "${audioServiceHandler.mediaItem.value!.id.split(".")[0]}.${audioServiceHandler.mediaItem.value!.id.split(".")[1]}" !=
                                  "library.favourites"
                              : true;

                          final skipTo =
                              audioServiceHandler.mediaItem.value != null
                                  ? audioServiceHandler.mediaItem.value!.id
                                          .split(".")[2] !=
                                      widget.favourites[index].id
                                  : false;

                          if (playNew) {
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
          }),
    );
  }
}
