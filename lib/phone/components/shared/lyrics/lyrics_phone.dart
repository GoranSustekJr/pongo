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
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: SizedBox(
        key: ValueKey("${widget.plainLyrics}"),
        width: MediaQuery.of(context).size.width,
        child: AnimatedOpacity(
          key: ValueKey("${widget.plainLyrics}${widget.lyricsOn}"),
          opacity: widget.lyricsOn ? 1 : 0,
          duration: Duration(milliseconds: widget.lyricsOn ? 500 : 150),
          child: AnimatedSwitcher(
            duration: Duration(
              milliseconds: widget.plainLyrics.isNotEmpty ||
                      widget.syncedLyrics.isNotEmpty
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
                    lyricsOn: widget.lyricsOn,
                    lyrics: widget.syncedLyrics,
                    syncTimeDelay: widget.syncTimeDelay,
                  ),
          ),
        ),
      ),
    );
  }
}
