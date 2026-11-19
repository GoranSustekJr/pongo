import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../../domain/models/catalog/track.dart';
import '../../../domain/models/playlists/user_playlist.dart';
import '../../../utils/image_resolution.dart';
import '../../../utils/result.dart';
import '../../services/api/api_client.dart';
import '../../services/api/track_socket_service.dart';
import '../../services/database/database_service.dart';
import 'downloads_repository.dart';

/// A [DownloadsRepository] that saves files in the app's documents directory.
class DownloadsRepositoryLocal implements DownloadsRepository {
  /// Creates a repository.
  DownloadsRepositoryLocal({
    required this._apiClient,
    required this._socketService,
    required this._database,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  final ApiClient _apiClient;
  final TrackSocketService _socketService;
  final DatabaseService _database;
  final http.Client _httpClient;

  static const _parallelDownloads = 4;

  @override
  Future<List<DownloadedTrack>> downloads() async => [
    for (final row in await _database.downloadedTracks.queryAll())
      DownloadedTrack.fromRow(row),
  ];

  @override
  Future<int> count() => _database.downloadedTracks.count();

  @override
  Future<List<String>> missing(List<String> stids) =>
      _database.downloadedTracks.queryMissing(stids);

  @override
  Future<Result<DownloadOutcome>> download(Track track, {String? cover}) async {
    if (await _database.downloadedTracks.contains(track.id)) {
      return const Result.ok(DownloadOutcome.alreadyDownloaded);
    }

    // The server has to have the track before it can send the file.
    TrackAvailability? availability;
    await for (final state in _socketService.watchAvailability(track.id)) {
      availability = state;
    }
    if (availability is! TrackReady) {
      return Result.error(Exception('Track ${track.id} is unavailable'));
    }

    final response = await _apiClient.postForResponse(
      'download_track/${track.id}',
      {},
      headers: {'Connection': 'keep-alive'},
    );
    switch (response) {
      case Error(:final error):
        return Result.error(error);
      case Ok(:final value):
        try {
          await _save(
            track,
            audio: value.bodyBytes,
            durationSeconds: availability.durationSeconds,
            cover:
                cover ??
                (track.album == null
                    ? null
                    : bestImageUrl(track.album!.images)),
          );
          return const Result.ok(DownloadOutcome.downloaded);
        } on Exception catch (e) {
          return Result.error(e);
        }
    }
  }

  @override
  Future<Result<bool>> downloadAll(
    List<({Track track, String cover})> tracks,
  ) async {
    var saved = 0;
    Exception? firstError;
    var next = 0;
    // The server fetches as many tracks at once; more workers would only wait
    Future<void> worker() async {
      while (next < tracks.length) {
        final entry = tracks[next++];
        switch (await download(entry.track, cover: entry.cover)) {
          case Ok(value: DownloadOutcome.downloaded):
            saved++;
          case Ok():
            break;
          case Error(:final error):
            firstError ??= error;
        }
      }
    }

    await Future.wait([for (var i = 0; i < _parallelDownloads; i++) worker()]);
    if (saved == 0 && firstError != null) return Result.error(firstError!);
    return Result.ok(saved > 0);
  }

  Future<void> _save(
    Track track, {
    required Uint8List audio,
    required double durationSeconds,
    required String? cover,
  }) async {
    if (await _database.downloadedTracks.contains(track.id)) return;
    final directory = (await getApplicationDocumentsDirectory()).path;
    final audioFile = File('$directory/${track.id}.m4a');
    await audioFile.writeAsBytes(audio);

    final imageFile = File('$directory/${track.id}.png');
    if (cover != null && cover.isNotEmpty) {
      final uri = Uri.parse(cover);
      final bytes = uri.scheme.startsWith('http')
          ? (await _httpClient.get(uri)).bodyBytes
          : await File(cover).readAsBytes();
      await imageFile.writeAsBytes(bytes);
    }

    await _database.downloadedTracks.insert(
      stid: track.id,
      audioPath: audioFile.path,
      artists: [for (final artist in track.artists) artist.toJson()],
      title: track.name,
      durationMilliseconds: (durationSeconds * 1000).toInt(),
      imagePath: imageFile.path,
    );
  }

  @override
  Future<void> remove(List<String> stids) async {
    await _database.downloadedTracks.removeAll(stids);
    final directory = (await getApplicationDocumentsDirectory()).path;
    for (final stid in stids) {
      final file = File('$directory/$stid.m4a');
      if (file.existsSync()) await file.delete();
    }
  }
}
