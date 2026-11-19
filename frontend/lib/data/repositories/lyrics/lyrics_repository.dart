import '../../services/api/lyrics_api_client.dart';

export '../../services/api/lyrics_api_client.dart' show Lyrics;

/// Source of truth for lyrics and their sync offsets.
abstract class LyricsRepository {
  /// The lyrics of a track, empty if none are found.
  Future<Lyrics> lyrics({
    required String name,
    required String artist,
    required String album,
    required Duration duration,
  });

  /// The saved lyrics offset of the track with [stid] in milliseconds.
  Future<int> syncDelay(String stid);

  /// Saves [milliseconds] as the lyrics offset of the track with [stid].
  Future<void> saveSyncDelay(String stid, int milliseconds);
}
