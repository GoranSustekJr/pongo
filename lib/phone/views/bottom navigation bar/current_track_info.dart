import 'dart:io';
import '../../../exports.dart';

class TrackInfo extends StatefulWidget {
  const TrackInfo({super.key});

  @override
  State<TrackInfo> createState() => _TrackInfoState();
}

class _TrackInfoState extends State<TrackInfo> {
  double horizontalPositionStart = 0;
  double horizontalPositionEnd = 0;
  double horizontalPositionCurrent = 0;

  // Text styles
  final TextStyle bottomTitle = TextStyle(
    fontSize: kIsApple ? 17 : 18,
    fontWeight: kIsApple ? FontWeight.w500 : FontWeight.w600,
  );

  final TextStyle bottomArtist = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w300,
    color: Colors.white.withAlpha(200),
  );

  @override
  Widget build(BuildContext context) {
    final audioServiceHandler =
        Provider.of<AudioHandler>(context) as AudioServiceHandler;
    return SafeArea(
      child: StreamBuilder(
        stream: audioServiceHandler.playbackState.stream,
        builder: (context, AsyncSnapshot<PlaybackState> playbackState) {
          return StreamBuilder(
            stream: audioServiceHandler.mediaItem,
            builder: (context, AsyncSnapshot<MediaItem?> mediaItem) {
              play() {
                if (playbackState.data?.playing ?? false) {
                  audioServiceHandler.pause();
                } else {
                  audioServiceHandler.play();
                }
              }

              // Get the current media item
              final currentMediaItem = mediaItem.data;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.decelerate,
                margin: const EdgeInsets.fromLTRB(24, 0, 24, 11),
                padding: const EdgeInsets.all(1),
                height: currentMediaItem == null || playbackState.data == null
                    ? 55
                    : kIsApple
                        ? 110
                        : 125,
                constraints: const BoxConstraints(maxWidth: 768),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: Colors.transparent,
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: currentMediaItem == null || playbackState.data == null
                      ? Container(key: const ValueKey(true))
                      : ClipRRect(
                          key: ValueKey(currentMediaItem.id),
                          borderRadius: BorderRadius.circular(24),
                          child: Stack(
                            children: [
                              FadeTransition(
                                opacity:
                                    const AlwaysStoppedAnimation<double>(1),
                                child: ClipRRect(
                                  child: Blurhash(
                                    blurhash: currentMediaItem
                                            .artHeaders?["blurhash"] ??
                                        AppConstants().BLURHASH,
                                    sigmaX: 0,
                                    sigmaY: 0,
                                    child: Container(
                                      color: Colors.transparent,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned.fill(
                                child: Container(
                                  color: Colors.black.withAlpha(25),
                                ),
                              ),
                              Positioned.fill(
                                child: GestureDetector(
                                  onVerticalDragEnd: (details) async {
                                    if (details.primaryVelocity! < 0) {
                                      /* OverlayEntry overlayEntry =
                                          overlay(context);
                                      Overlay.of(context).insert(overlayEntry);
                                      final track = await TrackData().get(
                                          context,
                                          currentMediaItem.id.split(".")[2]);
                                      overlayEntry.remove();
                                      Navigations().trackScreen(
                                          context,
                                          PhoneTrack(
                                            track: track,
                                            fromSearch: false,
                                          )); */
                                    }
                                  },
                                  onDoubleTap: () {
                                    /*  showModalBottomSheet(
                                        backgroundColor: Col.transp,
                                        isScrollControlled: true,
                                        context: context,
                                        builder: (context) => QueuePhone()); */
                                  },
                                  onLongPress: () {
                                    /*   showModalBottomSheet(
                                        backgroundColor: Col.transp,
                                        isScrollControlled: true,
                                        context: context,
                                        builder: (context) => QueuePhone()); */
                                  },
                                  onTap: () async {
                                    /*  OverlayEntry overlayEntry =
                                        overlay(context);
                                    Overlay.of(context).insert(overlayEntry);
                                    final track = await TrackData().get(context,
                                        currentMediaItem.id.split(".")[2]);
                                    overlayEntry.remove();
                                    Navigations().trackScreen(
                                        context,
                                        PhoneTrack(
                                          track: track,
                                          fromSearch: false,
                                        )); */
                                  },
                                  child: SwipeToSnapBack(
                                    swipeLeft: () async {
                                      await audioServiceHandler.skipToNext();
                                    },
                                    swipeRight: () async {
                                      await audioServiceHandler
                                          .skipToPrevious();
                                    },
                                    child: Stack(
                                      children: [
                                        Positioned(
                                          left: horizontalPositionCurrent != 0
                                              ? horizontalPositionCurrent -
                                                  horizontalPositionStart
                                              : 0,
                                          child: kIsApple
                                              ? Container(
                                                  height: 70,
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width -
                                                      48,
                                                  color: Colors.transparent,
                                                  child: Column(
                                                    children: [
                                                      Container(
                                                        height: 55,
                                                        width: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width -
                                                            48,
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          horizontal: 15,
                                                          vertical: 5,
                                                        ),
                                                        child: Row(
                                                          children: [
                                                            Container(
                                                              decoration:
                                                                  const BoxDecoration(
                                                                      boxShadow: [
                                                                    BoxShadow(
                                                                        color: Col
                                                                            .realBackground,
                                                                        blurRadius:
                                                                            5,
                                                                        spreadRadius:
                                                                            0,
                                                                        offset: Offset(
                                                                            0,
                                                                            0)),
                                                                  ]),
                                                              child: ClipRRect(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            7.5),
                                                                child:
                                                                    CachedNetworkImage(
                                                                  imageUrl:
                                                                      currentMediaItem
                                                                          .artUri
                                                                          .toString(), //  "REMOVEDtrack_art/${currentMediaItem.id.split(".")[2]}.png",
                                                                  width: 40,
                                                                  height: 40,
                                                                ),
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                width: 10),
                                                            SizedBox(
                                                              width: MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .width -
                                                                  180,
                                                              child: Column(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .max,
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  marquee(
                                                                    "${currentMediaItem.title}  ",
                                                                    bottomTitle,
                                                                    1,
                                                                    null,
                                                                    height: 22,
                                                                  ),
                                                                  marquee(
                                                                    "${currentMediaItem.artist}  ",
                                                                    bottomArtist,
                                                                    1,
                                                                    null,
                                                                    height: 20,
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                            const Expanded(
                                                                child:
                                                                    SizedBox()),
                                                            playPauseMini(
                                                              audioServiceHandler
                                                                  .audioPlayer
                                                                  .playing,
                                                              () {
                                                                play();
                                                              },
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                )
                                              : Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  children: [
                                                    SizedBox(
                                                      height: 60,
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width -
                                                              48,
                                                      child: Material(
                                                        color:
                                                            Colors.transparent,
                                                        child: ListTile(
                                                          leading: Container(
                                                            decoration:
                                                                const BoxDecoration(
                                                                    boxShadow: [
                                                                  BoxShadow(
                                                                      color: Col
                                                                          .realBackground,
                                                                      blurRadius:
                                                                          5,
                                                                      spreadRadius:
                                                                          0,
                                                                      offset:
                                                                          Offset(
                                                                              0,
                                                                              0)),
                                                                ]),
                                                            child: ClipRRect(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          7.5),
                                                              child:
                                                                  Image.network(
                                                                "REMOVEDtrack_art/${currentMediaItem.id.split(".")[2]}.png",
                                                                width: 40,
                                                                height: 40,
                                                              ), /* Image.file(
                                                              File.fromUri(
                                                                  currentMediaItem
                                                                      .artUri!),
                                                              width: 40,
                                                              height: 40,
                                                            ), */
                                                            ),
                                                          ),
                                                          title: SizedBox(
                                                            width: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width -
                                                                180,
                                                            child: Text(
                                                              currentMediaItem
                                                                  .title,
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              style:
                                                                  bottomTitle,
                                                            ),
                                                          ),
                                                          subtitle: Text(
                                                            currentMediaItem
                                                                .artist!,
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style: bottomArtist,
                                                          ),
                                                          trailing:
                                                              playPauseMini(
                                                            audioServiceHandler
                                                                .audioPlayer
                                                                .playing,
                                                            () {
                                                              play();
                                                            },
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
