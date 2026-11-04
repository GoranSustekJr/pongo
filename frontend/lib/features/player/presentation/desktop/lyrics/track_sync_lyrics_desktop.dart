import 'package:flutter/material.dart';

import 'package:pongo/app/theme/colors.dart';
import 'package:pongo/features/player/presentation/widgets/track_sync_lyrics.dart';

class TrackSyncLyricsDesktop extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return TrackSyncLyrics(
      lyrics: lyrics,
      syncTimeDelay: syncTimeDelay,
      lyricsOn: lyricsOn,
      style: TrackSyncLyricsStyle(
        isVisible: (state) => state != AppLifecycleState.hidden,
        preferPosition: (size) => 0.5,
        lyricsSize: (size) => Size(
          fullscreenPlaying ? size.width / 2 : size.width,
          fullscreenPlaying
              ? size.height
              : size.height < 685
                  ? size.height - 120
                  : size.height - 60,
        ),
        tagColor: Col.transp,
        switchDuration: const Duration(milliseconds: 150),
        fontSize: (size) => 35 * (size.height / 625),
        nextBlurOffset: -2,
        nextBlur: 3.75,
        farBlur: 4.5,
      ),
    );
  }
}
