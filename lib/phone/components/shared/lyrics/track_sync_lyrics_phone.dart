import 'package:pongo/exports.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

class TrackSyncLyricsPhone extends StatefulWidget {
  final List<dynamic> lyrics;
  final int syncTimeDelay;
  const TrackSyncLyricsPhone(
      {super.key, required this.lyrics, required this.syncTimeDelay});

  @override
  State<TrackSyncLyricsPhone> createState() => _TrackSyncLyricsPhoneState();
}

class _TrackSyncLyricsPhoneState extends State<TrackSyncLyricsPhone> {
  // Auto scroll controller
  AutoScrollController autoScrollController =
      AutoScrollController(axis: Axis.vertical);

  // Fade scroll view controller
  ScrollController controller = ScrollController();

  // Regex for text
  RegExp regExp = RegExp(r'\[.*?\]');

  // Lyrics list
  int index = 0;

  // Current line index
  int currentLyricIndex = 0;

  // Is user scrolling
  bool isUserScrolling = false;
  ScrollController manualScrollController = ScrollController();

  /* @override
  void initState() {
    super.initState();
    if (widget.lyrics[0] != null) {
      // If lyrics exist => get list of lyric lines
      lyrics = widget.lyrics[0].split('\n');
      lyrics.insert(0, "{#¶€[”„’‘¤ß÷×¤ß#}"); // Start height
      lyrics.add("{#¶€[”„’‘¤ß÷×¤ß#˘¸}"); // end height
    }

    // Listen for manual scroll start and end
    //   autoScrollController.addListener(autoScrollListener);
  } */

  // Parse timestamp to Duration
  Duration? parseTimestamp(String lyric) {
    final a = regExp.firstMatch(lyric);
    final b = a?.group(0);
    if (b != null) {
      final timestamp = b.substring(1, b.length - 1);
      final parts = timestamp.split(':');
      final parts2 = parts[1].split('.');
      if (parts.length == 2) {
        final minutes = int.parse(parts[0]);
        final seconds = int.parse(parts2[0]);
        final milliseconds = int.parse(parts2[1]) * 10;

        final dur = Duration(
          minutes: minutes,
          seconds: seconds,
          milliseconds: milliseconds.toInt(),
        );
        return dur;
      }
    }
    return null;
  }

  // Find the index of the current lyric based on the position
  findCurrentLyricIndex(Duration position) {
    for (int i = 1; i < widget.lyrics.length - 1; i++) {
      final currentTimestamp = parseTimestamp(widget.lyrics[i]);

      if (currentTimestamp != null) {
        if (position.inMilliseconds <=
                currentTimestamp.inMilliseconds + 250 - widget.syncTimeDelay &&
            position.inMilliseconds >=
                currentTimestamp.inMilliseconds - 250 - widget.syncTimeDelay &&
            !isUserScrolling) {
          autoScrollController.scrollToIndex(i,
              duration: const Duration(milliseconds: 350),
              preferPosition: AutoScrollPosition.middle);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              currentLyricIndex = i;
            });
          });
        }
      }
    }
    return 0;
  }

  @override
  void dispose() {
    autoScrollController.dispose();
    controller.dispose();
    manualScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    final audioServiceHandler =
        Provider.of<AudioHandler>(context) as AudioServiceHandler;

    return NotificationListener(
      child: StreamBuilder(
        stream: audioServiceHandler.positionStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData) {
            Duration position = snapshot.data as Duration;
            findCurrentLyricIndex(position);
            //print(position);
          }

          return Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Stack(
              children: [
                RepaintBoundary(
                  child: SizedBox(
                    height: size.height,
                    width: size.width - 20,
                    child: Center(
                      child: SingleChildScrollView(
                        controller: controller,
                        child: widget.lyrics.length <= 2
                            ? Column(
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!.nosynclyrics,
                                    textAlign: currentLyricsTextAlignment.value,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 29),
                                  ),
                                  Text(
                                    AppLocalizations.of(context)!
                                        .wanttohelpoutlyrics,
                                    textAlign: currentLyricsTextAlignment.value,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 15),
                                  ),
                                ],
                              )
                            : SizedBox(
                                height: size.height,
                                child: ListView(
                                  shrinkWrap: true,
                                  controller: autoScrollController,
                                  children: widget.lyrics.map(
                                    (lyric) {
                                      int index = widget.lyrics.indexOf(lyric);
                                      if (lyric == "{#¶€[”„’‘¤ß÷×¤ß#}") {
                                        return SizedBox(
                                            height: size.height / 2 -
                                                AppBar().preferredSize.height -
                                                MediaQuery.of(context)
                                                    .padding
                                                    .top);
                                      } else if (lyric ==
                                          "{#¶€[”„’‘¤ß÷×¤ß#˘¸}") {
                                        return SizedBox(
                                            height: size.height / 2);
                                      } else {
                                        return GestureDetector(
                                          onTap: () {
                                            if (index > 0 &&
                                                index <
                                                    widget.lyrics.length - 1) {
                                              final currentTimestamp =
                                                  parseTimestamp(
                                                      widget.lyrics[index]);
                                              if (currentTimestamp != null) {
                                                final duration = Duration(
                                                  milliseconds: currentTimestamp
                                                          .inMilliseconds -
                                                      widget.syncTimeDelay,
                                                );
                                                audioServiceHandler
                                                    .seek(duration);
                                              }
                                            }
                                          },
                                          child: AutoScrollTag(
                                            key: ValueKey(index),
                                            controller: autoScrollController,
                                            index: index,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                vertical: 0,
                                              ),
                                              child: Row(
                                                mainAxisAlignment: currentLyricsTextAlignment
                                                            .value ==
                                                        TextAlign.left
                                                    ? MainAxisAlignment.start
                                                    : currentLyricsTextAlignment
                                                                .value ==
                                                            TextAlign.center
                                                        ? MainAxisAlignment
                                                            .center
                                                        : currentLyricsTextAlignment
                                                                    .value ==
                                                                TextAlign.right
                                                            ? MainAxisAlignment
                                                                .end
                                                            : MainAxisAlignment
                                                                .spaceEvenly,
                                                mainAxisSize: MainAxisSize.max,
                                                children: [
                                                  Align(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    child: SizedBox(
                                                      width: size.width - 20,
                                                      child: AnimatedSwitcher(
                                                        duration:
                                                            const Duration(
                                                                milliseconds:
                                                                    200),
                                                        child: Text(
                                                          "${fixEncoding(lyric).replaceAll(regExp, '')}\n\n"
                                                              .trimLeft(),
                                                          key: ValueKey<int>(
                                                              currentLyricIndex ==
                                                                      index
                                                                  ? 1
                                                                  : 0),
                                                          maxLines: null,
                                                          softWrap: true,
                                                          textAlign:
                                                              currentLyricsTextAlignment
                                                                  .value,
                                                          style: currentLyricIndex ==
                                                                  index
                                                              ? const TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize:
                                                                      35.5,
                                                                  height: 1.5,
                                                                )
                                                              : TextStyle(
                                                                  color: Colors
                                                                      .white
                                                                      .withAlpha(
                                                                          100),
                                                                  fontWeight: kIsMacOS
                                                                      ? FontWeight
                                                                          .w300
                                                                      : FontWeight
                                                                          .w400,
                                                                  fontSize: 35,
                                                                  height: 1.5,
                                                                ),
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  ).toList(),
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

String fixEncoding(String incorrectString) {
  // Convert the incorrectly encoded string to a list of bytes
  List<int> bytes = utf8.encode(incorrectString);

  // Decode the bytes to a properly encoded string
  String fixedString = utf8.decode(bytes);

  return fixedString;
}
