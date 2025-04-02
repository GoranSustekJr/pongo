import 'package:custom_sliding_segmented_control/custom_sliding_segmented_control.dart';
import 'package:flutter/cupertino.dart';
import 'package:pongo/desktop/macos/views/lyrics/track_plain_lyrics_desktop.dart';
import 'package:pongo/desktop/macos/views/lyrics/track_sync_lyrics_desktop.dart';
import 'package:pongo/exports.dart';

class LyricsDesktop extends StatefulWidget {
  final List<dynamic> plainLyrics;
  final List<dynamic> syncedLyrics;
  final bool lyricsOn;
  final bool useSyncedLyrics;
  final int syncTimeDelay;
  final bool fullscreenPlaying;
  final String stid;
  final Function() onChangeUseSyncedLyrics;
  final Function() plus;
  final Function() minus;
  final Function() resetSyncTimeDelay;
  const LyricsDesktop({
    super.key,
    required this.plainLyrics,
    required this.syncedLyrics,
    required this.lyricsOn,
    required this.useSyncedLyrics,
    required this.syncTimeDelay,
    required this.stid,
    required this.onChangeUseSyncedLyrics,
    required this.plus,
    required this.minus,
    required this.resetSyncTimeDelay,
    required this.fullscreenPlaying,
  });

  @override
  State<LyricsDesktop> createState() => _LyricsDesktopState();
}

class _LyricsDesktopState extends State<LyricsDesktop> {
  late List<dynamic> currentLyrics;

  @override
  void initState() {
    super.initState();
    currentLyrics = widget.plainLyrics;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: SizedBox(
        key: ValueKey("${widget.plainLyrics}${enableLyrics.value}"),
        width: MediaQuery.of(context).size.width,
        child: AnimatedOpacity(
            opacity: widget.lyricsOn ? 1 : 0,
            duration: Duration(milliseconds: widget.lyricsOn ? 500 : 200),
            child: Stack(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  child: widget.lyricsOn
                      ? SizedBox(
                          key: const ValueKey(true),
                          child: !enableLyrics.value
                              ? Center(
                                  child: Text(
                                    AppLocalizations.of(context).lyricsdisabled,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 25),
                                  ),
                                )
                              : !widget.useSyncedLyrics
                                  ? TrackPlainLyricsDesktop(
                                      key: const ValueKey(true),
                                      lyrics: widget.plainLyrics)
                                  : SizedBox(
                                      width: MediaQuery.of(context).size.width,
                                      child: Center(
                                        child: TrackSyncLyricsDesktop(
                                          key: const ValueKey(false),
                                          lyricsOn: widget.lyricsOn,
                                          lyrics: widget.syncedLyrics,
                                          syncTimeDelay: widget.syncTimeDelay,
                                          fullscreenPlaying:
                                              widget.fullscreenPlaying,
                                        ),
                                      ),
                                    ),
                        )
                      : const SizedBox(
                          key: ValueKey(false),
                        ),
                ),
                Padding(
                  padding: EdgeInsets.only(
                      top: widget.fullscreenPlaying ? 5 : 15,
                      right: widget.fullscreenPlaying ? 5 : 0),
                  child: Material(
                    color: Col.transp,
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Column(
                          children: [
                            if (!widget.fullscreenPlaying)
                              Theme(
                                data: ThemeData(
                                  splashColor: Col.transp,
                                  hoverColor: Col.transp,
                                  highlightColor: Col.transp,
                                ),
                                child: SizedBox(
                                  width: 115,
                                  height: 30,
                                  child: CustomSlidingSegmentedControl<int>(
                                    fixedWidth: 55,
                                    initialValue:
                                        widget.useSyncedLyrics ? 0 : 1,
                                    children: {
                                      0: SizedBox(
                                        width: 55,
                                        child: Center(
                                          child: Text(
                                            AppLocalizations.of(context).sync,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.white),
                                          ),
                                        ),
                                      ),
                                      1: SizedBox(
                                        width: 55,
                                        child: Center(
                                            child: Text(
                                          AppLocalizations.of(context).plain,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.white),
                                        )),
                                      ),
                                    },
                                    decoration: BoxDecoration(
                                      color: const MacosColor.fromRGBO(
                                          40, 40, 40, 1),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    thumbDecoration: BoxDecoration(
                                      color: const MacosColor.fromRGBO(
                                          30, 30, 30, 1),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInToLinear,
                                    onValueChanged: (v) {
                                      if (widget.useSyncedLyrics && v == 1) {
                                        widget.onChangeUseSyncedLyrics();
                                      } else if (!widget.useSyncedLyrics &&
                                          v == 0) {
                                        widget.onChangeUseSyncedLyrics();
                                      }
                                    },
                                  ),
                                ),
                              ),
                            razh(5),
                            AnimatedOpacity(
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.decelerate,
                              opacity: widget.useSyncedLyrics ? 1 : 0,
                              child: Theme(
                                data: ThemeData(
                                  splashColor: Col.transp,
                                  hoverColor: Col.transp,
                                  highlightColor: Col.transp,
                                ),
                                child: SizedBox(
                                  child: Container(
                                    height: 30,
                                    width: 125,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(60),
                                      color: kIsDesktop &&
                                              !widget.fullscreenPlaying
                                          ? const MacosColor.fromRGBO(40, 40,
                                              40, 0.8) // Add transparency here
                                          : useBlur.value
                                              ? Col.transp
                                              : Col.realBackground.withAlpha(
                                                  AppConstants().noBlur),
                                    ),
                                    child: Row(
                                      children: [
                                        GestureDetector(
                                          child: CupertinoButton(
                                            padding: const EdgeInsets.only(),
                                            child: const Icon(
                                              CupertinoIcons.minus,
                                              color: Colors.white,
                                            ),
                                            onPressed: () {
                                              widget.minus();
                                            },
                                          ),
                                        ),
                                        Expanded(child: Container()),
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: GestureDetector(
                                            onLongPress: () async {
                                              await DatabaseHelper()
                                                  .insertSyncTimeDelay(
                                                      widget.stid,
                                                      widget.syncTimeDelay);
                                              Notifications()
                                                  .showSpecialNotification(
                                                context,
                                                AppLocalizations.of(context)
                                                    .successful,
                                                AppLocalizations.of(context)
                                                    .successfullysavedsynctimedelay,
                                                CupertinoIcons.time,
                                              );
                                            },
                                            child: CupertinoButton(
                                              padding: EdgeInsets.zero,
                                              onPressed:
                                                  widget.resetSyncTimeDelay,
                                              child: Text(
                                                "${widget.syncTimeDelay / 1000} s",
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                overflow: TextOverflow.fade,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Expanded(child: Container()),
                                        CupertinoButton(
                                          padding: const EdgeInsets.only(),
                                          child: const Icon(
                                            CupertinoIcons.plus,
                                            color: Colors.white,
                                          ),
                                          onPressed: () {
                                            widget.plus();
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )),
      ),
    );
  }
}
