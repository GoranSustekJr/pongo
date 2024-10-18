import 'package:pongo/exports.dart';
import 'package:pongo/phone/widgets/library/favourites/favourites_tile.dart';
import 'package:spotify_api/spotify_api.dart' as sp;

class FavouritesBodyPhone extends StatefulWidget {
  final PagingController<int, sp.Track> pagingController;
  final List<sp.Track> favourites;
  final List missingTracks;
  final List<String> loading;
  final Function(int) play;
  const FavouritesBodyPhone({
    super.key,
    required this.pagingController,
    required this.favourites,
    required this.missingTracks,
    required this.loading,
    required this.play,
  });

  @override
  State<FavouritesBodyPhone> createState() => _FavouritesBodyPhoneState();
}

class _FavouritesBodyPhoneState extends State<FavouritesBodyPhone> {
  @override
  Widget build(BuildContext context) {
    final audioServiceHandler =
        Provider.of<AudioHandler>(context) as AudioServiceHandler;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: PagedListView(
        shrinkWrap: true,
        pagingController: widget.pagingController,
        physics: const NeverScrollableScrollPhysics(),
        builderDelegate: PagedChildBuilderDelegate(
          firstPageErrorIndicatorBuilder: (context) => const SizedBox(),
          firstPageProgressIndicatorBuilder: (context) => const SizedBox(),
          itemBuilder: (context, item, index) {
            return FavouritesTile(
              track: widget.favourites[index],
              first: index == 0,
              last: widget.favourites.length - 1 == index,
              exists:
                  !widget.missingTracks.contains(widget.favourites[index].id),
              trailing: SizedBox(
                height: 40,
                width: 20,
                child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: widget.loading.contains(widget.favourites[index].id)
                        ? const CircularProgressIndicator.adaptive(
                            key: ValueKey(true),
                          )
                        : const SizedBox()),
              ),
              function: () async {
                final playNew = audioServiceHandler.mediaItem.value != null
                    ? "${audioServiceHandler.mediaItem.value!.id.split(".")[0]}.${audioServiceHandler.mediaItem.value!.id.split(".")[1]}" !=
                        "library.favourites"
                    : true;

                final skipTo = audioServiceHandler.mediaItem.value != null
                    ? audioServiceHandler.mediaItem.value!.id.split(".")[2] !=
                        widget.favourites[index].id
                    : false;

                if (playNew) {
                  print("play; $index");
                  changeTrackOnTap.value = true;
                  widget.play(index);
                } else if (skipTo &&
                    (audioServiceHandler.playlist.length - 1) >= index &&
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
        ),
      ),
    );
  }
}
