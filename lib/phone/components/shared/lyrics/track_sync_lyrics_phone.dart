import 'package:pongo/exports.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

class TrackSyncLyricsPhone extends StatefulWidget {
  final bool lyricsOn;
  final List<dynamic> lyrics;
  final int syncTimeDelay;
  const TrackSyncLyricsPhone({
    super.key,
    required this.lyrics,
    required this.syncTimeDelay,
    required this.lyricsOn,
  });

  @override
  State<TrackSyncLyricsPhone> createState() => _TrackSyncLyricsPhoneState();
}

class _TrackSyncLyricsPhoneState extends State<TrackSyncLyricsPhone> {
  // Auto scroll controller
  AutoScrollController autoScrollController =
      AutoScrollController(axis: Axis.vertical);

  // Regex for text
  RegExp regExp = RegExp(r'\[.*?\]');

  // Lyrics list
  int index = 0;

  // Current line index
  int currentLyricIndex = -1;

  // Is user scrolling
  bool isUserScrolling = false;
  ScrollController manualScrollController = ScrollController();

  Timer? _timer;
  Duration _currentPosition = Duration.zero;

  @override
  void initState() {
    super.initState();
    // Start a timer that updates every 250 milliseconds
    _timer = Timer.periodic(const Duration(milliseconds: 250), (timer) {
      final audioServiceHandler =
          Provider.of<AudioHandler>(context, listen: false)
              as AudioServiceHandler;
      // Fetch the current position from your audio service
      // Assuming audioServiceHandler.positionStream is a stream of Duration
      audioServiceHandler.positionStream.first.then((position) {
        setState(() {
          _currentPosition = position;
        });
        findCurrentLyricIndex(_currentPosition);
      });
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
  findCurrentLyricIndex(Duration position) {
    for (int i = 0; i < widget.lyrics.length - 1; i++) {
      final currentTimestamp = parseTimestamp(widget.lyrics[i]);

      if (currentTimestamp != null && widget.lyricsOn) {
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
    _timer?.cancel();
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
          /*  if (!snapshot.hasData) {
            return const Center(child: SizedBox());
          }
           */

          return Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Stack(
              children: [
                SizedBox(
                  height: size.height,
                  width: size.width - 20,
                  child: widget.lyrics.length <= 2
                      ? Column(
                          children: [
                            razh(size.height / 2 -
                                AppBar().preferredSize.height -
                                MediaQuery.of(context).padding.top),
                            Text(
                              AppLocalizations.of(context)!.nosynclyrics,
                              textAlign: currentLyricsTextAlignment.value,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 29),
                            ),
                            Text(
                              AppLocalizations.of(context)!.wanttohelpoutlyrics,
                              textAlign: currentLyricsTextAlignment.value,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500, fontSize: 15),
                            ),
                          ],
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
                                      milliseconds:
                                          currentTimestamp.inMilliseconds -
                                              widget.syncTimeDelay,
                                    );
                                    audioServiceHandler.seek(duration);
                                  }
                                }
                              },
                              child: AutoScrollTag(
                                key: ValueKey(index),
                                controller: autoScrollController,
                                index: index,
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 0),
                                  child: Align(
                                    alignment: currentLyricsTextAlignment
                                                .value ==
                                            TextAlign.left
                                        ? Alignment.centerLeft
                                        : currentLyricsTextAlignment.value ==
                                                TextAlign.center
                                            ? Alignment.center
                                            : currentLyricsTextAlignment
                                                        .value ==
                                                    TextAlign.right
                                                ? Alignment.centerRight
                                                : Alignment.center,
                                    child: AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 250),
                                      child: Text(
                                        "${widget.lyrics[index].replaceAll(regExp, '')}\n\n\n"
                                            .trimLeft(),
                                        key: ValueKey<int>(
                                            currentLyricIndex == index ? 1 : 0),
                                        maxLines: null,
                                        softWrap: true,
                                        textAlign:
                                            currentLyricsTextAlignment.value,
                                        style: currentLyricIndex == index
                                            ? const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 35,
                                                height: 1,
                                              )
                                            : TextStyle(
                                                color:
                                                    Colors.white.withAlpha(100),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 35,
                                                height: 1,
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
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
