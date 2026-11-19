import 'package:flutter/material.dart';

import '../../widgets/track_plain_lyrics.dart';

class TrackPlainLyricsDesktop extends StatelessWidget {
  final List<String> lyrics;
  const TrackPlainLyricsDesktop({super.key, required this.lyrics});

  @override
  Widget build(BuildContext context) {
    return TrackPlainLyrics(
      lyrics: lyrics,
      height: (size) =>
          size.height < 685 ? size.height - 120 : size.height - 60,
      width: (size) => size.width - 60,
      lineWidth: (size) => (size.width - 220) / 2,
    );
  }
}
