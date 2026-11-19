import 'dart:async';
import 'dart:convert';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../../../domain/models/catalog/track.dart';
import '../../../domain/models/sleep_alarm/sleep_alarm.dart';
import '../../../utils/result.dart';
import '../../services/api/api_client.dart';
import '../../services/api/track_socket_service.dart';
import '../../services/audio/pongo_audio_handler.dart';
import '../../services/local/secure_storage_service.dart';
import 'media_items.dart';
import 'player_repository.dart';

/// A [PlayerRepository] that plays through [PongoAudioHandler].
class PlayerRepositoryAudio implements PlayerRepository {
  /// Creates a repository that plays through [_handler].
  PlayerRepositoryAudio({
    required this._handler,
    required this._apiClient,
    required this._socketService,
    required this._storage,
  }) {
    _handler.mediaItem.listen((item) => _currentItem.value = item);
    _handler.queue.listen((items) => _queue.value = items);
  }

  final PongoAudioHandler _handler;
  final ApiClient _apiClient;
  final TrackSocketService _socketService;
  final SecureStorageService _storage;

  final _currentItem = ValueNotifier<MediaItem?>(null);
  final _queue = ValueNotifier<List<MediaItem>>(const []);
  final _canShuffle = ValueNotifier(true);
  final _queueMatchesCollection = ValueNotifier(true);
  final _fetchingTracks = ValueNotifier<Set<String>>(const {});
  final _trackFetched = StreamController<FetchedTrack>.broadcast();

  // Incremented whenever a new queue starts, so older fills stop.
  int _generation = 0;
  StreamSubscription<MixEntry>? _mixSubscription;

  AudioPlayer get _player => _handler.player;

  @override
  ValueListenable<MediaItem?> get currentItem => _currentItem;

  @override
  Stream<MediaItem?> get currentItemStream => _handler.mediaItem;

  @override
  ValueListenable<List<MediaItem>> get queue => _queue;

  @override
  Stream<List<MediaItem>> get queueStream => _handler.queue;

  @override
  Stream<PlaybackState> get playbackState => _handler.playbackState;

  @override
  Stream<bool> get playingStream => _player.playingStream;

  @override
  bool get isPlaying => _player.playing;

  @override
  Stream<Duration> get positionStream => _player.positionStream;

  @override
  Duration get position => _player.position;

  @override
  Stream<Duration> get bufferedPositionStream => _player.bufferedPositionStream;

  @override
  Stream<Duration?> get durationStream => _player.durationStream;

  @override
  Stream<LoopMode> get loopModeStream => _player.loopModeStream;

  @override
  LoopMode get loopMode => _player.loopMode;

  @override
  Stream<bool> get shuffleEnabledStream => _player.shuffleModeEnabledStream;

  @override
  bool get shuffleEnabled => _player.shuffleModeEnabled;

  @override
  Stream<List<int>> get shuffleIndicesStream => _player.shuffleIndicesStream;

  @override
  List<int> get shuffleIndices => _player.shuffleIndices;

  @override
  Stream<double> get volumeStream => _player.volumeStream;

  @override
  int? get currentIndex => _player.currentIndex;

  @override
  ValueListenable<bool> get canShuffle => _canShuffle;

  @override
  ValueListenable<bool> get queueMatchesCollection => _queueMatchesCollection;

  @override
  ValueListenable<Set<String>> get fetchingTracks => _fetchingTracks;

  @override
  Stream<FetchedTrack> get onTrackFetched => _trackFetched.stream;

  @override
  Stream<PlayerMessage> get messages => _handler.messages;

  @override
  int get activeSleepAlarm => _handler.activeSleepAlarm;

  int _startNewQueue() {
    unawaited(_mixSubscription?.cancel());
    _mixSubscription = null;
    return ++_generation;
  }

  void _setFetching(String stid, {required bool fetching}) {
    final tracks = {..._fetchingTracks.value};
    fetching ? tracks.add(stid) : tracks.remove(stid);
    _fetchingTracks.value = tracks;
  }

  /// Waits until the server can stream the track with [stid] and returns its
  /// length in seconds, or `null` if it can't get it.
  Future<double?> _ensureAvailable(String stid) async {
    double? duration;
    await for (final state in _socketService.watchAvailability(stid)) {
      switch (state) {
        case TrackDownloading():
          _setFetching(stid, fetching: true);
        case TrackReady(:final durationSeconds):
          duration = durationSeconds;
        case TrackUnavailable():
          duration = null;
      }
    }
    _setFetching(stid, fetching: false);
    _trackFetched.add((stid: stid, duration: duration));
    return duration;
  }

  Duration _seconds(double seconds) =>
      Duration(milliseconds: (seconds * 1000).toInt());

  Future<void> _startQueue(
    List<MediaItem> items, {
    int? index,
    required bool shuffle,
  }) async {
    await setShuffle(enabled: shuffle);
    await _handler.setQueue(items);
    if (index != null || shuffle) {
      await _handler.skipToQueueItem(index ?? _player.shuffleIndices.first);
    } else {
      await _handler.play();
    }
    _canShuffle.value = true;
  }

  @override
  Future<void> playOnline(
    String collectionId,
    List<Track> tracks, {
    required Map<String, double> durations,
    int? index,
    bool shuffle = false,
  }) async {
    final generation = _startNewQueue();
    final missing = [
      for (final track in tracks)
        if (!durations.containsKey(track.id)) track.id,
    ];
    if (missing.isEmpty) {
      await _startQueue(
        [
          for (final track in tracks)
            mediaItemFor(
              track,
              collectionId: collectionId,
              duration: _seconds(durations[track.id]!),
            ),
        ],
        index: index,
        shuffle: shuffle,
      );
      return;
    }

    // Tracks are queued in order while the server fetches the missing ones.
    _canShuffle.value = false;
    await _handler.halt();
    final session = _socketService.openBatch(missing);
    var started = false;
    try {
      for (final track in tracks) {
        if (generation != _generation) return;
        var duration = durations[track.id];
        if (duration == null) {
          _setFetching(track.id, fetching: true);
          duration = await session.next();
          _setFetching(track.id, fetching: false);
          _trackFetched.add((stid: track.id, duration: duration));
          if (duration == null || generation != _generation) continue;
        }
        final item = mediaItemFor(
          track,
          collectionId: collectionId,
          duration: _seconds(duration),
        );
        if (started) {
          await _handler.appendToQueue(item);
        } else {
          started = true;
          await _handler.setQueue([item]);
          await _handler.play();
        }
      }
    } on Exception catch (e) {
      debugPrint('Filling the queue failed: $e');
    } finally {
      await session.close();
      if (generation == _generation) _canShuffle.value = true;
    }
  }

  @override
  Future<void> playOffline(
    String collectionId,
    List<Track> tracks, {
    required Map<String, int> durations,
    int? index,
    bool shuffle = false,
  }) async {
    _startNewQueue();
    await _startQueue(
      [
        for (final track in tracks)
          mediaItemFor(
            track,
            collectionId: collectionId,
            duration: Duration(milliseconds: durations[track.id]!),
          ),
      ],
      index: index,
      shuffle: shuffle,
    );
  }

  @override
  Future<void> playSingle(
    Track track, {
    required String collectionId,
    bool startMix = false,
  }) async {
    if (_currentItem.value?.stid == track.id) {
      await togglePlayback();
      return;
    }
    final generation = _startNewQueue();
    _canShuffle.value = true;

    final duration = await _ensureAvailable(track.id);
    if (duration == null || generation != _generation) return;
    await _handler.setQueue([
      mediaItemFor(
        track,
        collectionId: collectionId,
        duration: _seconds(duration),
      ),
    ]);
    await _handler.play();
    if (startMix) await _startMix(track);
  }

  Future<void> _startMix(Track track) async {
    await setShuffle(enabled: false);
    _mixSubscription = _socketService.watchMix(track.id).listen((entry) async {
      final items = _queue.value;
      if (items.isEmpty || items.first.title != track.name) return;
      final mixTrack = Track.fromMap(entry.track);
      _queueMatchesCollection.value = false;
      await _handler.appendToQueue(
        mediaItemFor(
          mixTrack,
          collectionId: 'online.mix',
          duration: _seconds(entry.durationSeconds),
          mix: true,
        ),
      );
    }, onError: (Object e) => debugPrint('Mix failed: $e'));
  }

  @override
  Future<void> playCollectionTrack({
    required String collectionId,
    required String stid,
    required int index,
    required Future<void> Function() playCollection,
  }) async {
    final current = _currentItem.value;
    if (current == null || current.collectionId != collectionId) {
      _queueMatchesCollection.value = true;
      await playCollection();
    } else if (current.stid != stid &&
        _queue.value.length > index &&
        _queueMatchesCollection.value) {
      await skipToIndex(index);
    } else {
      await togglePlayback();
    }
  }

  Future<MediaItem?> _queueEntryFor(Track track, String collectionId) async {
    final result = await _apiClient.post('get_track_duration', {
      'stid': track.id,
    });
    var duration = switch (result) {
      Ok(:final value) => (value['duration'] as num?)?.toDouble(),
      Error() => null,
    };
    duration ??= await _ensureAvailable(track.id);
    if (duration == null) return null;
    return mediaItemFor(
      track,
      collectionId: collectionId,
      duration: _seconds(duration),
    );
  }

  @override
  Future<void> addNext(Track track, {required String collectionId}) async {
    final item = await _queueEntryFor(track, collectionId);
    if (item == null) return;
    _queueMatchesCollection.value = false;
    await _handler.insertNext(item);
  }

  @override
  Future<void> addLast(Track track, {required String collectionId}) async {
    final item = await _queueEntryFor(track, collectionId);
    if (item == null) return;
    _queueMatchesCollection.value = false;
    await _handler.appendToQueue(item);
  }

  @override
  Future<void> removeFromQueue(List<int> indexes) async {
    for (final index in [...indexes]..sort((a, b) => b.compareTo(a))) {
      if (index != _player.currentIndex) {
        await _handler.removeQueueItemAt(index);
      }
    }
    _queueMatchesCollection.value = false;
  }

  @override
  Future<void> moveInQueue(int oldIndex, int newIndex) async {
    await _handler.moveQueueItem(oldIndex, newIndex);
    _queueMatchesCollection.value = false;
  }

  @override
  Future<void> play() => _handler.play();

  @override
  Future<void> pause() => _handler.pause();

  @override
  Future<void> togglePlayback() =>
      _player.playing ? _handler.pause() : _handler.play();

  @override
  Future<void> seek(Duration position) => _handler.seek(position);

  @override
  Future<void> skipToIndex(int index) => _handler.skipToQueueItem(index);

  @override
  Future<void> skipToNext() => _handler.skipToNext();

  @override
  Future<void> skipToPrevious() => _handler.skipToPrevious();

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode mode) =>
      _handler.setRepeatMode(mode);

  @override
  Future<void> setShuffle({required bool enabled}) => _handler.setShuffleMode(
    enabled ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none,
  );

  @override
  Future<void> setVolume(double volume) => _handler.setVolume(volume);

  @override
  Future<bool> halt() async {
    final halted = await _handler.halt();
    if (halted) _startNewQueue();
    return halted;
  }

  @override
  Future<void> startSleepAlarm(SleepAlarm alarm) =>
      _handler.startSleepAlarm(alarm);

  @override
  Future<void> stopSleepAlarm() => _handler.stopSleepAlarm();

  @override
  Future<void> restoreState() async {
    final loopMode = await _storage.read(StorageKeys.loopMode);
    await _handler.restoreRepeatMode(switch (loopMode) {
      'LoopMode.off' => AudioServiceRepeatMode.none,
      'LoopMode.one' => AudioServiceRepeatMode.one,
      _ => AudioServiceRepeatMode.all,
    });
    final shuffleMode = await _storage.read(StorageKeys.shuffleMode);
    await setShuffle(enabled: shuffleMode == 'AudioServiceShuffleMode.all');

    final saved = await _storage.read(StorageKeys.queue);
    if (saved == null) return;
    final items = [
      for (final json in jsonDecode(saved) as List)
        mediaItemFromJson((json as Map).cast<String, dynamic>()),
    ];
    if (items.isEmpty) return;

    final index = await _storage.readInt(StorageKeys.queueIndex, fallback: -1);
    final position = Duration(
      microseconds: await _storage.readInt(
        StorageKeys.playingPosition,
        fallback: 0,
      ),
    );
    await _handler.setQueue(items);
    await _player.seek(position, index: index == -1 ? null : index);
  }

  @override
  Future<void> saveState() async {
    await _storage.write(StorageKeys.loopMode, _player.loopMode.toString());
    await _storage.write(
      StorageKeys.shuffleMode,
      (_player.shuffleModeEnabled
              ? AudioServiceShuffleMode.all
              : AudioServiceShuffleMode.none)
          .toString(),
    );
    await _storage.write(
      StorageKeys.queue,
      jsonEncode([for (final item in _queue.value) mediaItemToJson(item)]),
    );
    await _storage.writeInt(StorageKeys.queueIndex, _player.currentIndex ?? -1);
    await _storage.writeInt(
      StorageKeys.playingPosition,
      _player.position.inMicroseconds,
    );
  }
}
