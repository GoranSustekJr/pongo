import 'package:flutter/material.dart';

import 'package:pongo/core/constants/platform.dart';
import 'package:pongo/features/player/presentation/widgets/track_sync_lyrics.dart';

class TrackSyncLyricsPhone extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return TrackSyncLyrics(
      lyrics: lyrics,
      syncTimeDelay: syncTimeDelay,
      lyricsOn: lyricsOn,
      style: TrackSyncLyricsStyle(
        isVisible: (state) => state == AppLifecycleState.resumed,
        preferPosition: (size) => 1 - ((size.height - 385) / size.height),
        lyricsSize: (size) => size,
        switchDuration: const Duration(milliseconds: 250),
        fontSize: (size) => kIsApple ? 35 : 45,
        nextBlurOffset: 1,
        nextBlur: 2.75,
        farBlur: 3.5,
      ),
    );
  }
}
