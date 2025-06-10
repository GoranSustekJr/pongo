import 'dart:ui';

import 'package:pongo/exports.dart';
import 'package:pongo/phone/widgets/special/liquid_glass_background.dart';

class SelectedTracksPhone extends StatelessWidget {
  final bool show;
  final double height;
  final List<PlaylistHandlerTrack> playlistHandlerTracks;
  final Function(DragEndDetails) onVerticalDragEnd;
  final Function(DragUpdateDetails) onVerticalDragUpdate;
  const SelectedTracksPhone({
    super.key,
    required this.show,
    required this.playlistHandlerTracks,
    required this.height,
    required this.onVerticalDragEnd,
    required this.onVerticalDragUpdate,
  });

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 350),
      curve: show ? Curves.easeIn : Curves.fastEaseInToSlowEaseOut,
      top: show ? -300 : kToolbarHeight,
      left: 0,
      right: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(60),
          child: liquidGlassBackground(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                  sigmaX: useBlur.value && !kIsApple ? 10 : 0,
                  sigmaY: useBlur.value && !kIsApple ? 10 : 0),
              child: Container(
                color: Colors.black.withAlpha(useBlur.value ? 50 : 200),
                child: playlistHandlerTracks.length == 1
                    ? Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7.5, vertical: 5),
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width,
                          height: 45,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              razw(10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(5),
                                child: Container(
                                  width: 45,
                                  height: 45,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(5),
                                    color: Col.primaryCard.withAlpha(150),
                                  ),
                                  child: FadeInImage(
                                    placeholder: const AssetImage(
                                        'assets/images/placeholder.png'),
                                    fadeInDuration:
                                        const Duration(milliseconds: 200),
                                    fadeOutDuration:
                                        const Duration(milliseconds: 200),
                                    image: playlistHandlerTracks[0]
                                                .playlistHandlerCoverType ==
                                            PlaylistHandlerCoverType.url
                                        ? NetworkImage(
                                            playlistHandlerTracks[0].cover,
                                          )
                                        : FileImage(
                                            File.fromUri(Uri.parse(
                                                playlistHandlerTracks[0]
                                                    .cover)),
                                          ),
                                  ),
                                ),
                              ),
                              razw(7.5),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    marquee(
                                      "${playlistHandlerTracks[0].name}  ",
                                      const TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      1,
                                      null,
                                      height: 22,
                                    ),
                                    marquee(
                                      playlistHandlerTracks[0]
                                          .artist
                                          .map((artist) => artist["name"])
                                          .join(', '),
                                      const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w400,
                                      ),
                                      1,
                                      null,
                                      height: 20,
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      )
                    : GestureDetector(
                        onVerticalDragUpdate: onVerticalDragUpdate,
                        onVerticalDragEnd: onVerticalDragEnd,
                        child: AnimatedContainer(
                            duration: const Duration(milliseconds: 350),
                            height: show ? 50 : 60 + height,
                            curve: Curves.fastEaseInToSlowEaseOut,
                            child: Column(
                              children: [
                                razh(5),
                                Text(
                                  "${playlistHandlerTracks.length} ${AppLocalizations.of(context).plustracks}",
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 350),
                                  curve: Curves.fastEaseInToSlowEaseOut,
                                  height: show ? 0 : height,
                                  width: size.width - 40,
                                  child: ListView.builder(
                                    itemCount: playlistHandlerTracks.length,
                                    shrinkWrap: true,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10, horizontal: 10),
                                    itemBuilder: (context, index) {
                                      final track =
                                          playlistHandlerTracks[index];
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 2.5),
                                        child: Row(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(7.5),
                                              child: /* CachedNetworkImage(
                                                imageUrl: track.cover.toString(),
                                                width: 55,
                                                height: 55,
                                              ), */
                                                  FadeInImage(
                                                width: 55,
                                                height: 55,
                                                placeholder: const AssetImage(
                                                    'assets/images/placeholder.png'),
                                                fadeInDuration: const Duration(
                                                    milliseconds: 200),
                                                fadeOutDuration: const Duration(
                                                    milliseconds: 200),
                                                image: playlistHandlerTracks[
                                                                index]
                                                            .playlistHandlerCoverType ==
                                                        PlaylistHandlerCoverType
                                                            .url
                                                    ? NetworkImage(
                                                        playlistHandlerTracks[
                                                                index]
                                                            .cover,
                                                      )
                                                    : FileImage(
                                                        File.fromUri(Uri.parse(
                                                            playlistHandlerTracks[
                                                                    index]
                                                                .cover)),
                                                      ),
                                              ),
                                            ),
                                            razw(10),
                                            Flexible(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.max,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  marquee(
                                                    "${track.name}  ",
                                                    const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 17,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                    1,
                                                    null,
                                                    height: 22,
                                                  ),
                                                  marquee(
                                                    "${playlistHandlerTracks[index].artist.map((artist) => artist["name"]).join(', ')}  ",
                                                    const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                    ),
                                                    1,
                                                    null,
                                                    height: 20,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                Flexible(
                                  child: Container(
                                    height: 25,
                                    width: size.width - 40,
                                    color: Colors.transparent,
                                    child: Center(
                                      child: Container(
                                        width: 50,
                                        height: 5,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(360),
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
