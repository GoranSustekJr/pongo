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
    Size size = MediaQuery.of(context).size;
    return SafeArea(
      child: StreamBuilder(
        stream: audioServiceHandler.playbackState.stream,
        builder: (context, playbackState) {
          bool playing = false;
          if (playbackState.data != null) {
            playing = playbackState.data!.playing;
          }
          return StreamBuilder(
            stream: audioServiceHandler.mediaItem,
            builder: (context, AsyncSnapshot<MediaItem?> mediaItem) {
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
                  duration: const Duration(milliseconds: 300),
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
                                  child: ValueListenableBuilder(
                                      valueListenable: currentBlurhash,
                                      builder: (context, signedIn, child) {
                                        return AnimatedSwitcher(
                                          duration:
                                              const Duration(milliseconds: 300),
                                          child: Blurhash(
                                            key:
                                                ValueKey(currentBlurhash.value),
                                            blurhash: currentBlurhash.value,
                                            sigmaX: 0,
                                            sigmaY: 0,
                                            child: Container(
                                              color: Colors.transparent,
                                            ),
                                          ),
                                        );
                                      }),
                                ),
                              ),
                              Positioned.fill(
                                child: Container(
                                  color: Colors.black.withAlpha(50),
                                ),
                              ),
                              Positioned.fill(
                                child: GestureDetector(
                                  onVerticalDragUpdate: (details) {
                                    // Move the panel upwards/downwards
                                    currentTrackHeight.value -=
                                        details.delta.dy;

                                    // Prevent it from going below 0 or above the screen height
                                    if (currentTrackHeight.value < 0) {
                                      currentTrackHeight.value = 0;
                                    } else if (currentTrackHeight.value >
                                        size.height) {
                                      currentTrackHeight.value = size.height;
                                    }
                                  },
                                  onVerticalDragEnd: (details) {
                                    // Set a threshold for the drag distance (e.g., 40 pixels)
                                    const dragThreshold = 40;

                                    setState(() {
                                      // Check if the drag distance exceeds the threshold
                                      if (details.primaryVelocity != null &&
                                          details.primaryVelocity! <
                                              -dragThreshold) {
                                        // If dragged upwards (velocity is negative), snap to full height
                                        currentTrackHeight.value = size.height;
                                      } else if (details.primaryVelocity !=
                                              null &&
                                          details.primaryVelocity! >
                                              dragThreshold) {
                                        // If dragged downwards (velocity is positive), snap back to bottom
                                        currentTrackHeight.value = 0;
                                      } else {
                                        // Check the current height to decide whether to snap to full or bottom
                                        if (currentTrackHeight.value > 40) {
                                          currentTrackHeight.value = size
                                              .height; // Snap to full height
                                        } else {
                                          currentTrackHeight.value =
                                              0; // Snap back to bottom
                                        }
                                      }
                                    });
                                  },
                                  onTap: () async {
                                    currentTrackHeight.value = size.height;
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
                                              ? RepaintBoundary(
                                                  child: Container(
                                                    height: 70,
                                                    width:
                                                        MediaQuery.of(context)
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
                                                                child:
                                                                    ClipRRect(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              7.5),
                                                                  child:
                                                                      CachedNetworkImage(
                                                                    imageUrl: currentMediaItem
                                                                        .artUri
                                                                        .toString(),
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
                                                                      height:
                                                                          22,
                                                                    ),
                                                                    marquee(
                                                                      "${currentMediaItem.artist}  ",
                                                                      bottomArtist,
                                                                      1,
                                                                      null,
                                                                      height:
                                                                          20,
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              const Expanded(
                                                                  child:
                                                                      SizedBox()),
                                                              RepaintBoundary(
                                                                child:
                                                                    PlayPauseMini(
                                                                  playbackState:
                                                                      playbackState,
                                                                  function: () {
                                                                    if (playing) {
                                                                      audioServiceHandler
                                                                          .pause();
                                                                    } else {
                                                                      audioServiceHandler
                                                                          .play();
                                                                    }
                                                                  },
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                )
                                              : RepaintBoundary(
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    children: [
                                                      SizedBox(
                                                        height: 60,
                                                        width: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width -
                                                            48,
                                                        child: Material(
                                                          color: Colors
                                                              .transparent,
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
                                                                        offset: Offset(
                                                                            0,
                                                                            0)),
                                                                  ]),
                                                              child: ClipRRect(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            7.5),
                                                                child: Image
                                                                    .network(
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
                                                              style:
                                                                  bottomArtist,
                                                            ),
                                                            trailing:
                                                                RepaintBoundary(
                                                              child:
                                                                  PlayPauseMini(
                                                                playbackState:
                                                                    playbackState,
                                                                function: () {
                                                                  if (playing) {
                                                                    audioServiceHandler
                                                                        .pause();
                                                                  } else {
                                                                    audioServiceHandler
                                                                        .play();
                                                                  }
                                                                },
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
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
