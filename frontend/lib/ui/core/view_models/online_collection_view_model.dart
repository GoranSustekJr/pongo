import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/repositories/player/player_repository.dart';
import '../../../data/services/media/blurhash_service.dart';
import '../../../domain/models/catalog/catalog_results.dart';
import '../../../domain/models/catalog/track.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';

/// A list of catalog tracks that plays as one collection, such as an album.
///
/// Subclasses load the tracks in [fetch]; this class keeps track of which
/// ones the server still has to fetch and plays them.
abstract class OnlineCollectionViewModel extends ChangeNotifier {
  /// Creates a view model for the collection with [collectionId].
  OnlineCollectionViewModel({
    required this.collectionId,
    required this._player,
    required this._blurhash,
  }) {
    load = Command0(_load)..execute();
    _player.fetchingTracks.addListener(notifyListeners);
    _fetched = _player.onTrackFetched.listen(_onTrackFetched);
  }

  /// The ID that marks queue entries started from this collection.
  final String collectionId;

  final PlayerRepository _player;
  final BlurhashService _blurhash;
  late final StreamSubscription<FetchedTrack> _fetched;

  /// Loads the tracks.
  late final Command0<void> load;

  bool _showBody = false;
  List<Track> _tracks = const [];
  final _durations = <String, double>{};
  final _missing = <String>[];
  String? _blurhashValue;

  /// Whether the tracks are loaded.
  bool get showBody => _showBody;

  /// The tracks.
  List<Track> get tracks => _tracks;

  /// Lengths in seconds of the tracks the server has.
  Map<String, double> get existingTracks => _durations;

  /// IDs of the tracks the server still has to fetch.
  List<String> get missingTracks => _missing;

  /// IDs of the tracks being fetched right now.
  List<String> get loading => _player.fetchingTracks.value.toList();

  /// The blurhash of the cover, or `null` for the default one.
  String? get blurhash => _blurhashValue;

  /// Whether shuffling is being prepared. Shuffle never waits here, so it's
  /// always `false`.
  bool get loadingShuffle => false;

  /// Loads the collection's tracks.
  @protected
  Future<Result<TrackListing>> fetch();

  /// The URL of the cover the background blurhash comes from.
  @protected
  String get coverUrl;

  Future<Result<void>> _load() async {
    final result = await fetch();
    switch (result) {
      case Error(:final error):
        return Result.error(error);
      case Ok(:final value):
        _tracks = value.tracks;
        _durations
          ..clear()
          ..addAll(value.availability.durations);
        _missing
          ..clear()
          ..addAll(value.availability.missing);
        _blurhashValue = await _encodeCover();
        _showBody = true;
        notifyListeners();
        return const Result.ok(null);
    }
  }

  Future<String?> _encodeCover() async {
    if (coverUrl.isEmpty) return null;
    try {
      return await _blurhash.encodeUrl(coverUrl);
    } on Exception {
      return null;
    }
  }

  void _onTrackFetched(FetchedTrack fetched) {
    final duration = fetched.duration;
    if (duration == null || !_missing.contains(fetched.stid)) return;
    _missing.remove(fetched.stid);
    _durations[fetched.stid] = duration;
    notifyListeners();
  }

  /// Plays the collection from the track at [index].
  Future<void> play({int index = 0}) => _player.playOnline(
    collectionId,
    _tracks,
    durations: _durations,
    index: index,
  );

  /// Plays the collection shuffled, once every track is available.
  Future<void> shuffle() async {
    if (_missing.isNotEmpty) return;
    await _player.playOnline(
      collectionId,
      _tracks,
      durations: _durations,
      shuffle: true,
    );
  }

  @override
  void dispose() {
    _player.fetchingTracks.removeListener(notifyListeners);
    unawaited(_fetched.cancel());
    load.dispose();
    super.dispose();
  }
}
