import 'package:flutter_animate/flutter_animate.dart';
import 'package:pongo/exports.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

class TrackSyncLyricsDesktop extends StatefulWidget {
  final bool lyricsOn;
  final List<dynamic> lyrics;
  final int syncTimeDelay;
  final bool fullscreenPlaying;
  const TrackSyncLyricsDesktop({
    super.key,
    required this.lyrics,
    required this.syncTimeDelay,
    required this.lyricsOn,
    required this.fullscreenPlaying,
  });

  @override
  State<TrackSyncLyricsDesktop> createState() => _TrackSyncLyricsDesktopState();
}

class _TrackSyncLyricsDesktopState extends State<TrackSyncLyricsDesktop> {
  // Auto scroll controller
  AutoScrollController autoScrollController =
      AutoScrollController(axis: Axis.vertical);

  // Regex for text
  RegExp regExp = RegExp(r'\[.*?\]');

  // Lyrics list
  int index = -1;

  // Current line index
  int currentLyricIndex = -1;
  ValueNotifier<double> notifier = ValueNotifier(1);

  // Is user scrolling
  bool isUserScrolling = false;
  ScrollController manualScrollController = ScrollController();

  Timer? _timer;
  Duration _currentPosition = Duration.zero;

  @override
  void initState() {
    super.initState();

    // Get the current position
    getCurrentPosition();

    // Start a timer that updates every 250 milliseconds
    _timer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      final audioServiceHandler =
          Provider.of<AudioHandler>(context, listen: false)
              as AudioServiceHandler;
      // Fetch the current position from your audio service
      // Assuming audioServiceHandler.positionStream is a stream of Duration
      audioServiceHandler.positionStream.first.then((position) {
        setState(() {
          _currentPosition = position;
        });
        if (WidgetsBinding.instance.lifecycleState ==
            AppLifecycleState.resumed) {
          findCurrentLyricIndex(_currentPosition);
        }
      });
    });
  }

  void getCurrentPosition() async {
    final audioServiceHandler =
        Provider.of<AudioHandler>(context, listen: false)
            as AudioServiceHandler;

    audioServiceHandler.positionStream.first.then((position) {
      setState(() {
        _currentPosition = position + widget.syncTimeDelay.milliseconds;
      });
      if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        findCurrentLyricIndex(_currentPosition, first: true);
      }
    });
  }

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
  findCurrentLyricIndex(Duration position, {bool first = false}) {
    for (int i = 0; i < widget.lyrics.length - 1; i++) {
      final currentTimestamp = parseTimestamp(widget.lyrics[i]);

      if (currentTimestamp != null && widget.lyricsOn) {
        if (!first) {
          if (position.inMilliseconds <=
                  currentTimestamp.inMilliseconds +
                      250 -
                      widget.syncTimeDelay &&
              position.inMilliseconds >=
                  currentTimestamp.inMilliseconds -
                      250 -
                      widget.syncTimeDelay &&
              !isUserScrolling) {
            autoScrollController.scrollToIndex(
              i,
              duration: const Duration(milliseconds: 350),
              preferPosition: 0.5, // 200 / MediaQuery.of(context).size.height
            );

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  currentLyricIndex = i;
                  if (i == 0) {
                    notifier.value = 1;
                  } else {
                    notifier.value = i.toDouble();
                  }
                });
              }
            });
          }
        } else {
          if (currentTimestamp.inMilliseconds >= position.inMilliseconds) {
            if (mounted && i != 0) {
              Future.delayed(const Duration(milliseconds: 250), () {
                autoScrollController.scrollToIndex(
                  i - 1,
                  duration: const Duration(milliseconds: 350),
                  preferPosition:
                      0.5, // 200 / MediaQuery.of(context).size.height
                );

                setState(() {
                  currentLyricIndex = i - 1;
                  if (i == 0) {
                    notifier.value = 1;
                  } else {
                    notifier.value = i - 1.toDouble();
                  }
                });
              });
            }
            break;
          }
        }
      }
    }
    return 0;
  }

  @override
  void dispose() {
    autoScrollController.dispose();
    _timer?.cancel();
    manualScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    final audioServiceHandler =
        Provider.of<AudioHandler>(context) as AudioServiceHandler;
    return Stack(
      children: [
        SizedBox(
          height: widget.fullscreenPlaying
              ? size.height
              : size.height < 685
                  ? size.height - 120
                  : size.height - 60,
          width: widget.fullscreenPlaying ? size.width / 2 : size.width,
          child: widget.lyrics.length <= 2
              ? SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        razh(size.height / 2 -
                            AppBar().preferredSize.height -
                            MediaQuery.of(context).padding.top),
                        Text(
                          AppLocalizations.of(context).nosynclyrics,
                          textAlign: currentLyricsTextAlignment.value,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 29),
                        ),
                        Text(
                          AppLocalizations.of(context).wanttohelpoutlyrics,
                          textAlign: currentLyricsTextAlignment.value,
                          style: const TextStyle(
                              fontWeight: FontWeight.w500, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.only(
                    top: size.height / 2 -
                        AppBar().preferredSize.height -
                        MediaQuery.of(context).padding.top,
                    bottom: size.height / 2 -
                        AppBar().preferredSize.height -
                        MediaQuery.of(context).padding.top,
                  ),
                  controller: autoScrollController,
                  itemCount: widget.lyrics.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        if (index < widget.lyrics.length - 1) {
                          final currentTimestamp =
                              parseTimestamp(widget.lyrics[index]);
                          if (currentTimestamp != null) {
                            final duration = Duration(
                              milliseconds: currentTimestamp.inMilliseconds -
                                  widget.syncTimeDelay,
                            );
                            audioServiceHandler.seek(duration);
                          }
                        }
                      },
                      child: AutoScrollTag(
                        color: Col.transp,
                        highlightColor: Col.transp,
                        key: ValueKey(index),
                        controller: autoScrollController,
                        index: index,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 0, horizontal: 10),
                          child: Align(
                            alignment: currentLyricsTextAlignment.value ==
                                    TextAlign.left
                                ? Alignment.centerLeft
                                : currentLyricsTextAlignment.value ==
                                        TextAlign.center
                                    ? Alignment.centerLeft
                                    : currentLyricsTextAlignment.value ==
                                            TextAlign.right
                                        ? Alignment.centerRight
                                        : Alignment.center,
                            child: AnimatedScale(
                              scale: currentLyricIndex != index ? 0.85 : 1,
                              alignment: currentLyricsTextAlignment.value ==
                                      TextAlign.left
                                  ? Alignment.centerLeft
                                  : currentLyricsTextAlignment.value ==
                                          TextAlign.center
                                      ? Alignment.center
                                      : currentLyricsTextAlignment.value ==
                                              TextAlign.right
                                          ? Alignment.centerRight
                                          : Alignment.center,
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.fastEaseInToSlowEaseOut,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                switchInCurve: Curves.fastOutSlowIn,
                                child: Padding(
                                  key: ValueKey(currentLyricIndex - index),
                                  padding: const EdgeInsets.only(bottom: 40),
                                  child: Text(
                                    "${widget.lyrics[index].replaceAll(regExp, '')}"
                                        .trimLeft(),
                                    key: ValueKey<int>(
                                        (currentLyricIndex - index)),
                                    maxLines: null,
                                    softWrap: true,
                                    textAlign: currentLyricsTextAlignment.value,
                                    style: TextStyle(
                                      color: currentLyricIndex == index
                                          ? Colors.white
                                          : (index - currentLyricIndex) == 1
                                              ? Colors.white.withAlpha(200)
                                              : (index - currentLyricIndex) == 2
                                                  ? Colors.white.withAlpha(150)
                                                  : Colors.white.withAlpha(100),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 35 * (size.height / 625),
                                      height: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ).animate().blurXY(
                                  begin: 0,
                                  end: currentLyricIndex == index
                                      ? 0
                                      : (currentLyricIndex - index) == -1
                                          ? 2.25
                                          : (currentLyricIndex - index) == 1
                                              ? 2.75
                                              : 3.5,
                                  duration: const Duration(milliseconds: 350),
                                ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
