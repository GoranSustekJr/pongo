import '../../../domain/models/catalog/track.dart';
import '../../../domain/models/playlists/user_playlist.dart';
import '../../../utils/result.dart';

/// What happened when a track was downloaded.
enum DownloadOutcome {
  /// The track was saved to the device.
  downloaded,

  /// The track was already on the device.
  alreadyDownloaded,
}

/// Source of truth for tracks saved to the device.
abstract class DownloadsRepository {
  /// All downloaded tracks, sorted by title.
  Future<List<DownloadedTrack>> downloads();

  /// The number of downloaded tracks.
  Future<int> count();

  /// The IDs in [stids] that aren't downloaded.
  Future<List<String>> missing(List<String> stids);

  /// Downloads [track] to the device, with the cover at [cover], a URL or
  /// path, or else the track's best album image.
  Future<Result<DownloadOutcome>> download(Track track, {String? cover});

  /// Downloads several tracks, a few at a time, saving each as it arrives.
  ///
  /// Each entry of [tracks] gives the track and the URL or path of its cover.
  /// Returns whether any track was saved, or an error if every track failed.
  Future<Result<bool>> downloadAll(List<({Track track, String cover})> tracks);

  /// Deletes the tracks with [stids] and their files.
  Future<void> remove(List<String> stids);
}
