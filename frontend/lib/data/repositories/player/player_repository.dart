import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../../../domain/models/catalog/track.dart';
import '../../../domain/models/sleep_alarm/sleep_alarm.dart';
import '../../services/audio/pongo_audio_handler.dart';

export '../../services/audio/pongo_audio_handler.dart' show PlayerMessage;

/// A track the server finished fetching, or failed to when its duration is
/// `null`.
typedef FetchedTrack = ({String stid, double? duration});

/// Source of truth for playback and the queue.
abstract class PlayerRepository {
  /// The entry being played, or `null` when the queue is empty.
  ValueListenable<MediaItem?> get currentItem;

  /// Emits the entry being played, starting with the current one.
  Stream<MediaItem?> get currentItemStream;

  /// The queue.
  ValueListenable<List<MediaItem>> get queue;

  /// Emits the queue, starting with the current one.
  Stream<List<MediaItem>> get queueStream;

  /// The audio handler's playback state.
  Stream<PlaybackState> get playbackState;

  /// Emits whether audio is playing.
  Stream<bool> get playingStream;

  /// Whether audio is playing.
  bool get isPlaying;

  /// Emits the playback position.
  Stream<Duration> get positionStream;

  /// The playback position.
  Duration get position;

  /// Emits the buffered position.
  Stream<Duration> get bufferedPositionStream;

  /// Emits the length of the current track.
  Stream<Duration?> get durationStream;

  /// Emits the loop mode.
  Stream<LoopMode> get loopModeStream;

  /// The loop mode.
  LoopMode get loopMode;

  /// Emits whether shuffle is on.
  Stream<bool> get shuffleEnabledStream;

  /// Whether shuffle is on.
  bool get shuffleEnabled;

  /// Emits the play order of the queue when shuffle is on.
  Stream<List<int>> get shuffleIndicesStream;

  /// The play order of the queue when shuffle is on.
  List<int> get shuffleIndices;

  /// Emits the player volume.
  Stream<double> get volumeStream;

  /// The index of the current entry in the queue.
  int? get currentIndex;

  /// Whether the queue can be shuffled, which it can't while tracks are still
  /// being fetched into it.
  ValueListenable<bool> get canShuffle;

  /// Whether the queue still lists a collection's tracks in their order, so
  /// tapping a track can skip to it instead of restarting the collection.
  ValueListenable<bool> get queueMatchesCollection;

  /// IDs of the tracks the server is fetching for playback.
  ValueListenable<Set<String>> get fetchingTracks;

  /// Emits each track the server finished fetching.
  Stream<FetchedTrack> get onTrackFetched;

  /// Messages for the user from the player.
  Stream<PlayerMessage> get messages;

  /// The ID of the running sleep alarm, or -1 if none is running.
  int get activeSleepAlarm;

  /// Plays the catalog [tracks] started from [collectionId].
  ///
  /// [durations] holds the length in seconds of tracks the server already
  /// has; the others are fetched first. Starts at [index], or at a random
  /// track if [shuffle].
  Future<void> playOnline(
    String collectionId,
    List<Track> tracks, {
    required Map<String, double> durations,
    int? index,
    bool shuffle = false,
  });

  /// Plays the downloaded [tracks] started from [collectionId].
  ///
  /// [durations] holds the length of each track in milliseconds.
  Future<void> playOffline(
    String collectionId,
    List<Track> tracks, {
    required Map<String, int> durations,
    int? index,
    bool shuffle = false,
  });

  /// Plays [track] alone, or toggles playback if it's already current.
  ///
  /// When [startMix] is set, similar tracks are queued after it.
  Future<void> playSingle(
    Track track, {
    required String collectionId,
    bool startMix = false,
  });

  /// Handles a tap on the track at [index] of a collection.
  ///
  /// Starts the collection with [playCollection] unless it's already playing,
  /// skips to the track if the queue still matches the collection, and
  /// otherwise toggles playback.
  Future<void> playCollectionTrack({
    required String collectionId,
    required String stid,
    required int index,
    required Future<void> Function() playCollection,
  });

  /// Inserts [track] after the current entry.
  Future<void> addNext(Track track, {required String collectionId});

  /// Appends [track] to the queue.
  Future<void> addLast(Track track, {required String collectionId});

  /// Removes the entries at [indexes], except the one playing.
  Future<void> removeFromQueue(List<int> indexes);

  /// Moves the entry at [oldIndex] to [newIndex], counted before removal.
  Future<void> moveInQueue(int oldIndex, int newIndex);

  /// Resumes playback.
  Future<void> play();

  /// Pauses playback.
  Future<void> pause();

  /// Plays if paused and pauses if playing.
  Future<void> togglePlayback();

  /// Seeks to [position] in the current track.
  Future<void> seek(Duration position);

  /// Plays the entry at [index].
  Future<void> skipToIndex(int index);

  /// Plays the next entry.
  Future<void> skipToNext();

  /// Restarts the track, or plays the previous entry near its start.
  Future<void> skipToPrevious();

  /// Sets how the queue repeats.
  Future<void> setRepeatMode(AudioServiceRepeatMode mode);

  /// Turns shuffle on or off.
  Future<void> setShuffle({required bool enabled});

  /// Sets the player volume.
  Future<void> setVolume(double volume);

  /// Stops playback and clears the queue unless a sleep alarm is running.
  ///
  /// Returns whether the player stopped.
  Future<bool> halt();

  /// Starts [alarm].
  Future<void> startSleepAlarm(SleepAlarm alarm);

  /// Stops the running sleep alarm.
  Future<void> stopSleepAlarm();

  /// Restores the queue and modes saved by [saveState].
  Future<void> restoreState();

  /// Saves the queue, position and modes so the next launch can resume.
  Future<void> saveState();
}
