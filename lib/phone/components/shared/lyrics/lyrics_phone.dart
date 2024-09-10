import 'package:pongo/phone/components/shared/lyrics/track_plain_lyrics_phone.dart';
import 'package:pongo/phone/components/shared/lyrics/track_sync_lyrics_phone.dart';
import '../../../../exports.dart';

class LyricsPhone extends StatefulWidget {
  final List<dynamic> plainLyrics;
  final List<dynamic> syncedLyrics;
  final bool lyricsOn;
  final bool useSyncedLyrics;
  final int syncTimeDelay;
  const LyricsPhone({
    super.key,
    required this.plainLyrics,
    required this.syncedLyrics,
    required this.lyricsOn,
    required this.useSyncedLyrics,
    required this.syncTimeDelay,
  });

  @override
  State<LyricsPhone> createState() => _LyricsPhoneState();
}

class _LyricsPhoneState extends State<LyricsPhone> {
  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 0),
      top: widget.lyricsOn ? 0 : MediaQuery.of(context).size.height,
      child: AnimatedOpacity(
        opacity: widget.lyricsOn ? 1 : 0,
        duration: Duration(milliseconds: widget.lyricsOn ? 500 : 150),
        child: AnimatedSwitcher(
          duration: Duration(
            milliseconds:
                widget.plainLyrics.isNotEmpty || widget.syncedLyrics.isNotEmpty
                    ? widget.plainLyrics[0] == null ||
                            widget.syncedLyrics[0] == null
                        ? 0
                        : 500
                    : 500,
          ),
          child: !widget.useSyncedLyrics
              ? TrackPlainLyricsPhone(
                  key: const ValueKey(true), lyrics: widget.plainLyrics)
              : TrackSyncLyricsPhone(
                  key: const ValueKey(false),
                  lyrics: widget.syncedLyrics,
                  syncTimeDelay: widget.syncTimeDelay,
                ),
        ),
      ),
    );
  }
}
