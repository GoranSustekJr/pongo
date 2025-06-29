import 'package:pongo/phone/widgets/special/liquid_glass_background.dart';
import 'package:pongo/phone/widgets/special/liquid_glass_render.dart';

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
  final TextStyle bottomTitle = const TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w500,
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
    return liquidGlassLayer(
      glassColor: Col.text.withAlpha(30),
      child: SafeArea(
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
                  margin: const EdgeInsets.fromLTRB(10, 0, 10, 11),
                  padding: const EdgeInsets.all(1),
                  height: currentMediaItem == null || playbackState.data == null
                      ? 0
                      : 58,
                  constraints: const BoxConstraints(maxWidth: 768),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: Colors.transparent,
                  ),
                  child: liquidGlass(
                    radius: 24,
                    child: liquidGlassBackground(
                      enabled: liquidGlassEnabled,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: currentMediaItem == null ||
                                playbackState.data == null
                            ? Container(key: const ValueKey(true))
                            : ClipRRect(
                                key: ValueKey(currentMediaItem.id),
                                borderRadius: BorderRadius.circular(24),
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: GestureDetector(
                                        onLongPress: () async {
                                          CustomButton ok =
                                              await haltAlert(context);
                                          if (ok ==
                                              CustomButton.positiveButton) {
                                            currentTrackHeight.value = 0;
                                            final audioServiceHandler =
                                                Provider.of<AudioHandler>(
                                                        context,
                                                        listen: false)
                                                    as AudioServiceHandler;

                                            await audioServiceHandler.halt();
                                          }
                                        },
                                        onVerticalDragUpdate: (details) {
                                          // Move the panel upwards/downwards
                                          currentTrackHeight.value -=
                                              details.delta.dy;

                                          // Prevent it from going below 0 or above the screen height
                                          if (currentTrackHeight.value < 0) {
                                            currentTrackHeight.value = 0;
                                          } else if (currentTrackHeight.value >
                                              size.height) {
                                            currentTrackHeight.value =
                                                size.height;
                                          }
                                        },
                                        onVerticalDragEnd: (details) {
                                          // Set a threshold for the drag distance (e.g., 40 pixels)
                                          const dragThreshold = 40;

                                          setState(() {
                                            // Check if the drag distance exceeds the threshold
                                            if (details.primaryVelocity !=
                                                    null &&
                                                details.primaryVelocity! <
                                                    -dragThreshold) {
                                              // If dragged upwards (velocity is negative), snap to full height
                                              currentTrackHeight.value =
                                                  size.height;
                                            } else if (details
                                                        .primaryVelocity !=
                                                    null &&
                                                details.primaryVelocity! >
                                                    dragThreshold) {
                                              // If dragged downwards (velocity is positive), snap back to bottom
                                              currentTrackHeight.value = 0;
                                            } else {
                                              // Check the current height to decide whether to snap to full or bottom
                                              if (currentTrackHeight.value >
                                                  40) {
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
                                          currentTrackHeight.value =
                                              size.height;
                                        },
                                        child: SwipeToSnapBack(
                                          swipeLeft: () async {
                                            await audioServiceHandler
                                                .skipToNext();
                                          },
                                          swipeRight: () async {
                                            await audioServiceHandler
                                                .skipToPrevious();
                                          },
                                          child: Stack(
                                            children: [
                                              Positioned(
                                                  left: horizontalPositionCurrent !=
                                                          0
                                                      ? horizontalPositionCurrent -
                                                          horizontalPositionStart
                                                      : 0,
                                                  child: RepaintBoundary(
                                                    child: Container(
                                                      height: 70,
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width -
                                                              10,
                                                      color: Colors.transparent,
                                                      child: Column(
                                                        children: [
                                                          Container(
                                                            height: 55,
                                                            width: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width -
                                                                10,
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                              horizontal: 15,
                                                              vertical: 5,
                                                            ),
                                                            child: Row(
                                                              children: [
                                                                SizedBox(
                                                                  width: 50,
                                                                  height: 50,
                                                                  child:
                                                                      ClipRRect(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            7.5),
                                                                    child: currentMediaItem.artUri.toString() !=
                                                                                "" &&
                                                                            currentMediaItem.artUri !=
                                                                                null
                                                                        ? ImageCompatible(
                                                                            image:
                                                                                currentMediaItem.artUri.toString(),
                                                                            width:
                                                                                40,
                                                                            height:
                                                                                40,
                                                                          )
                                                                        : SizedBox(
                                                                            height:
                                                                                40,
                                                                            width:
                                                                                40,
                                                                            child:
                                                                                Center(
                                                                              child: Icon(
                                                                                AppIcons.blankTrack,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                    width: 10),
                                                                SizedBox(
                                                                  width:
                                                                      size.width -
                                                                          155,
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
                                                                razw(10)
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  )),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
