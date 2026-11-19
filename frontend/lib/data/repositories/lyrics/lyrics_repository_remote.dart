import '../../services/api/lyrics_api_client.dart';
import '../../services/database/database_service.dart';
import 'lyrics_repository.dart';

/// A [LyricsRepository] that fetches lyrics from LRCLIB and keeps offsets in
/// the device database.
class LyricsRepositoryRemote implements LyricsRepository {
  /// Creates a repository.
  LyricsRepositoryRemote({required this._client, required this._database});

  final LyricsApiClient _client;
  final DatabaseService _database;

  @override
  Future<Lyrics> lyrics({
    required String name,
    required String artist,
    required String album,
    required Duration duration,
  }) => _client.fetch(
    name: name,
    artist: artist,
    album: album,
    durationSeconds: duration.inSeconds,
  );

  @override
  Future<int> syncDelay(String stid) async =>
      await _database.lyricsSyncDelays.query(stid) ?? 0;

  @override
  Future<void> saveSyncDelay(String stid, int milliseconds) =>
      _database.lyricsSyncDelays.upsert(stid, milliseconds);
}
