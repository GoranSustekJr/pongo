/* import 'dart:ui';
import 'package:pongo/exports.dart';

class SelectedTracksPhone extends StatelessWidget {
  final double height;
  final bool createPlaylist;
  final Size size;
  final Function(DragEndDetails) onVerticalDragEnd;
  final Function(DragUpdateDetails) onVerticalDragUpdate;
  const SelectedTracksPhone({
    super.key,
    required this.height,
    required this.createPlaylist,
    required this.size,
    required this.onVerticalDragEnd,
    required this.onVerticalDragUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 350),
      curve: createPlaylist || playlistTrackToAddData.value == null
          ? Curves.easeIn
          : Curves.fastEaseInToSlowEaseOut,
      top: createPlaylist || playlistTrackToAddData.value == null
          ? -300
          : kToolbarHeight,
      left: 0,
      right: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(60),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              color: Colors.black.withAlpha(50),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: playlistTrackToAddData.value != null
                      ? playlistTrackToAddData.value!["tracks"] != null
                          ? 0
                          : 15
                      : 15,
                  vertical: playlistTrackToAddData.value != null
                      ? playlistTrackToAddData.value!["tracks"] != null
                          ? 0
                          : 5
                      : 5,
                ),
                child: playlistTrackToAddData.value != null
                    ? playlistTrackToAddData.value!["tracks"] != null
                        ? GestureDetector(
                            onVerticalDragUpdate: onVerticalDragUpdate,
                            onVerticalDragEnd: onVerticalDragEnd,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 350),
                              height: createPlaylist ? 60 : 60 + height,
                              curve: Curves.fastEaseInToSlowEaseOut,
                              child: Column(
                                children: [
                                  razh(5),
                                  Text(
                                    "${playlistTrackToAddData.value!["tracks"].length} ${AppLocalizations.of(context)!.plustracks}",
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 350),
                                    curve: Curves.fastEaseInToSlowEaseOut,
                                    height: createPlaylist ? 0 : height,
                                    width: size.width - 40,
                                    child: ListView.builder(
                                      itemCount: playlistTrackToAddData
                                          .value!["tracks"].length,
                                      shrinkWrap: true,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10, horizontal: 10),
                                      itemBuilder: (context, index) {
                                        final track = playlistTrackToAddData
                                            .value!["tracks"][index];
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 2.5),
                                          child: Row(
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(7.5),
                                                child: CachedNetworkImage(
                                                  imageUrl:
                                                      track["cover"].toString(),
                                                  width: 55,
                                                  height: 55,
                                                ),
                                              ),
                                              razw(10),
                                              Flexible(
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.max,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    marquee(
                                                      "${track["title"]}  ",
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
                                                      "${track["artist"]}  ",
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
                                  Container(
                                    height: 30,
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
                                ],
                              ),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(7.5),
                                child: CachedNetworkImage(
                                  imageUrl: playlistTrackToAddData
                                      .value!["cover"]
                                      .toString(),
                                  width: 55,
                                  height: 55,
                                ),
                              ),
                              razw(10),
                              Flexible(
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    marquee(
                                      "${playlistTrackToAddData.value!["title"]}  ",
                                      const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      1,
                                      null,
                                      height: 22,
                                    ),
                                    marquee(
                                      "${playlistTrackToAddData.value!["artist"]}  ",
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
                              ),
                            ],
                          )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.max,
                        children: [Text("-")],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
 */
