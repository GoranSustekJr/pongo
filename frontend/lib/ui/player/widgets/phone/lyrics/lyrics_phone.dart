import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../app/view_models/app_settings_view_model.dart';
import 'track_plain_lyrics_phone.dart';
import 'track_sync_lyrics_phone.dart';

class LyricsPhone extends StatefulWidget {
  final List<String> plainLyrics;
  final List<String> syncedLyrics;
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
        key: ValueKey(
          '${widget.plainLyrics}${context.readSettings.enableLyrics}',
        ),
        width: MediaQuery.of(context).size.width,
        child: AnimatedOpacity(
          opacity: widget.lyricsOn ? 1 : 0,
          duration: Duration(milliseconds: widget.lyricsOn ? 500 : 200),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: widget.lyricsOn
                ? SizedBox(
                    key: const ValueKey(true),
                    child: !context.readSettings.enableLyrics
                        ? Center(
                            child: Text(
                              AppLocalizations.of(context).lyricsdisabled,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 25,
                              ),
                            ),
                          )
                        : !widget.useSyncedLyrics
                        ? TrackPlainLyricsPhone(
                            key: const ValueKey(true),
                            lyrics: widget.plainLyrics,
                          )
                        : TrackSyncLyricsPhone(
                            key: const ValueKey(false),
                            lyricsOn: widget.lyricsOn,
                            lyrics: widget.syncedLyrics,
                            syncTimeDelay: widget.syncTimeDelay,
                          ),
                  )
                : const SizedBox(key: ValueKey(false)),
          ),
        ),
      ),
    );
  }
}
