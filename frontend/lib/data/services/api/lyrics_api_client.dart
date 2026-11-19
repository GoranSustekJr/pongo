import 'dart:convert';

import 'package:http/http.dart' as http;

/// Plain and time synced lyrics of a track.
typedef Lyrics = ({String plain, String synced});

/// Calls to the LRCLIB lyrics database.
class LyricsApiClient {
  /// Creates a client.
  LyricsApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _empty = (plain: '', synced: '');

  /// The lyrics of a track, or empty lyrics if none are found.
  ///
  /// Looks the track up exactly first and falls back to a search that
  /// prefers synced lyrics with the closest duration.
  Future<Lyrics> fetch({
    required String name,
    required String artist,
    required String album,
    required int durationSeconds,
  }) async {
    try {
      final response = await _client.get(
        Uri.https('lrclib.net', '/api/get', {
          'artist_name': artist,
          'track_name': name,
          'duration': durationSeconds.toString(),
          'album_name': album,
        }),
      );
      if (response.statusCode == 200) {
        final data = _decode(response) as Map<String, dynamic>;
        if (data['syncedLyrics'] != null && data['plainLyrics'] != null) {
          return _lyrics(data);
        }
      }
    } on Exception {
      // Fall back to searching.
    }
    return _search(name, artist, durationSeconds);
  }

  Future<Lyrics> _search(String name, String artist, int duration) async {
    try {
      final response = await _client.get(
        Uri.https('lrclib.net', '/api/search', {'q': '$name - $artist'}),
      );
      if (response.statusCode != 200) return _empty;
      final results = (_decode(response) as List).cast<Map<String, dynamic>>();
      if (results.isEmpty) return _empty;

      final synced = results.where((r) => r['syncedLyrics'] != null).toList();
      if (synced.isEmpty) return _lyrics(results.first);

      double distance(Map<String, dynamic> r) =>
          ((r['duration'] as num).toInt() - duration).abs().toDouble();
      return _lyrics(
        synced.reduce((a, b) => distance(a) < distance(b) ? a : b),
      );
    } on Exception {
      return _empty;
    }
  }

  Object? _decode(http.Response response) =>
      jsonDecode(utf8.decode(response.bodyBytes));

  Lyrics _lyrics(Map<String, dynamic> data) => (
    plain: data['plainLyrics'] as String? ?? '',
    synced: data['syncedLyrics'] as String? ?? '',
  );
}
