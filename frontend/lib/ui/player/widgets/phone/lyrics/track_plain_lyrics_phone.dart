import 'package:flutter/material.dart';

import '../../widgets/track_plain_lyrics.dart';

class TrackPlainLyricsPhone extends StatelessWidget {
  final List<String> lyrics;
  const TrackPlainLyricsPhone({super.key, required this.lyrics});

  @override
  Widget build(BuildContext context) {
    return TrackPlainLyrics(
      lyrics: lyrics,
      height: (size) => size.height,
      width: (size) => size.width - 20,
      lineWidth: (size) => size.width - 20,
    );
  }
}
