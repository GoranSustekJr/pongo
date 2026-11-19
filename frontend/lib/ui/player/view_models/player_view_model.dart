import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/history/history_repository.dart';
import '../../../data/repositories/player/media_items.dart';
import '../../../data/repositories/player/player_repository.dart';
import '../../../data/repositories/settings/settings_repository.dart';
import '../../../data/services/media/blurhash_service.dart';
import '../../../domain/models/catalog/track.dart';
import '../../../domain/models/sleep_alarm/sleep_alarm.dart';
import '../../core/app_icons.dart';
import '../../core/messages/app_message.dart';
import '../../core/messages/message_center.dart';

/// Playback state and controls shared by every screen.
class PlayerViewModel extends ChangeNotifier {
  /// Creates a view model for [_player].
  PlayerViewModel({
    required this._player,
    required this._history,
    required this._settings,
    required this._blurhash,
    required this._messages,
  }) {
    _player.currentItem.addListener(_onItemChanged);
    _messageSubscription = _player.messages.listen(_onPlayerMessage);
    _onItemChanged();
  }

  final PlayerRepository _player;
  final HistoryRepository _history;
  final SettingsRepository _settings;
  final BlurhashService _blurhash;
  final MessageCenter _messages;
  late final StreamSubscription<PlayerMessage> _messageSubscription;

  final _currentStid = ValueNotifier('');
  final _currentBlurhash = ValueNotifier<String?>(null);
  String? _artUri;

  /// The entry being played.
  ValueListenable<MediaItem?> get currentItem => _player.currentItem;

  /// The ID of the track being played, empty if none.
  ValueListenable<String> get currentStid => _currentStid;

  /// The blurhash of the current artwork, or `null` for the default one.
  ValueListenable<String?> get currentBlurhash => _currentBlurhash;

  /// Emits the entry being played, starting with the current one.
  Stream<MediaItem?> get currentItemStream => _player.currentItemStream;

  /// The queue.
  ValueListenable<List<MediaItem>> get queue => _player.queue;

  /// Emits the queue, starting with the current one.
  Stream<List<MediaItem>> get queueStream => _player.queueStream;

  /// The audio handler's playback state.
  Stream<PlaybackState> get playbackState => _player.playbackState;

  /// Emits whether audio is playing.
  Stream<bool> get playingStream => _player.playingStream;

  /// Whether audio is playing.
  bool get isPlaying => _player.isPlaying;

  /// Emits the playback position.
  Stream<Duration> get positionStream => _player.positionStream;

  /// The playback position.
  Duration get position => _player.position;

  /// Emits the buffered position.
  Stream<Duration> get bufferedPositionStream => _player.bufferedPositionStream;

  /// Emits the length of the current track.
  Stream<Duration?> get durationStream => _player.durationStream;

  /// Emits the loop mode.
  Stream<LoopMode> get loopModeStream => _player.loopModeStream;

  /// The loop mode.
  LoopMode get loopMode => _player.loopMode;

  /// Emits whether shuffle is on.
  Stream<bool> get shuffleEnabledStream => _player.shuffleEnabledStream;

  /// Whether shuffle is on.
  bool get shuffleEnabled => _player.shuffleEnabled;

  /// Emits the play order when shuffle is on.
  Stream<List<int>> get shuffleIndicesStream => _player.shuffleIndicesStream;

  /// The play order when shuffle is on.
  List<int> get shuffleIndices => _player.shuffleIndices;

  /// Emits the player volume.
  Stream<double> get volumeStream => _player.volumeStream;

  /// The index of the current entry.
  int? get currentIndex => _player.currentIndex;

  /// Whether the queue can be shuffled.
  ValueListenable<bool> get canShuffle => _player.canShuffle;

  /// Whether tapping a track of the playing collection skips to it.
  ValueListenable<bool> get queueMatchesCollection =>
      _player.queueMatchesCollection;

  /// IDs of the tracks being fetched for playback.
  ValueListenable<Set<String>> get fetchingTracks => _player.fetchingTracks;

  /// Emits each track the server finished fetching.
  Stream<FetchedTrack> get onTrackFetched => _player.onTrackFetched;

  /// The ID of the running sleep alarm, or -1.
  int get activeSleepAlarm => _player.activeSleepAlarm;

  /// Whether [collectionId] is the collection playing.
  bool isPlayingCollection(String collectionId) =>
      currentItem.value?.collectionId == collectionId;

  /// Whether the entry at [index] of [collectionId] is the one playing.
  bool isPlayingEntry(String collectionId, String stid, int index) {
    final item = currentItem.value;
    return item != null &&
        item.collectionId == collectionId &&
        item.stid == stid &&
        currentIndex == index;
  }

  /// See [PlayerRepository.playOnline].
  Future<void> playOnline(
    String collectionId,
    List<Track> tracks, {
    required Map<String, double> durations,
    int? index,
    bool shuffle = false,
  }) => _player.playOnline(
    collectionId,
    tracks,
    durations: durations,
    index: index,
    shuffle: shuffle,
  );

  /// See [PlayerRepository.playOffline].
  Future<void> playOffline(
    String collectionId,
    List<Track> tracks, {
    required Map<String, int> durations,
    int? index,
    bool shuffle = false,
  }) => _player.playOffline(
    collectionId,
    tracks,
    durations: durations,
    index: index,
    shuffle: shuffle,
  );

  /// Plays [track] alone, followed by a mix if the user enabled mixes.
  Future<void> playSingle(Track track, {required String collectionId}) =>
      _player.playSingle(
        track,
        collectionId: collectionId,
        startMix: _settings.settings.useMix,
      );

  /// See [PlayerRepository.playCollectionTrack].
  Future<void> playCollectionTrack({
    required String collectionId,
    required String stid,
    required int index,
    required Future<void> Function() playCollection,
  }) => _player.playCollectionTrack(
    collectionId: collectionId,
    stid: stid,
    index: index,
    playCollection: playCollection,
  );

  /// Inserts [track] after the current entry.
  Future<void> addNext(Track track, {required String collectionId}) =>
      _player.addNext(track, collectionId: collectionId);

  /// Appends [track] to the queue.
  Future<void> addLast(Track track, {required String collectionId}) =>
      _player.addLast(track, collectionId: collectionId);

  /// Removes the entries at [indexes].
  Future<void> removeFromQueue(List<int> indexes) =>
      _player.removeFromQueue(indexes);

  /// Moves a queue entry.
  Future<void> moveInQueue(int oldIndex, int newIndex) =>
      _player.moveInQueue(oldIndex, newIndex);

  /// Resumes playback.
  Future<void> play() => _player.play();

  /// Pauses playback.
  Future<void> pause() => _player.pause();

  /// Toggles playback.
  Future<void> togglePlayback() => _player.togglePlayback();

  /// Seeks in the current track.
  Future<void> seek(Duration position) => _player.seek(position);

  /// Plays the entry at [index].
  Future<void> skipToIndex(int index) => _player.skipToIndex(index);

  /// Plays the next entry.
  Future<void> skipToNext() => _player.skipToNext();

  /// Plays the previous entry.
  Future<void> skipToPrevious() => _player.skipToPrevious();

  /// Sets how the queue repeats.
  Future<void> setRepeatMode(AudioServiceRepeatMode mode) =>
      _player.setRepeatMode(mode);

  /// Moves to the next repeat mode: off, all, one.
  Future<void> cycleRepeatMode() => setRepeatMode(switch (loopMode) {
    LoopMode.off => AudioServiceRepeatMode.all,
    LoopMode.all => AudioServiceRepeatMode.one,
    LoopMode.one => AudioServiceRepeatMode.none,
  });

  /// Turns shuffle on or off.
  Future<void> setShuffle({required bool enabled}) =>
      _player.setShuffle(enabled: enabled);

  /// Sets the player volume.
  Future<void> setVolume(double volume) => _player.setVolume(volume);

  /// Stops playback unless a sleep alarm is running.
  Future<void> halt() => _player.halt();

  /// Starts [alarm].
  Future<void> startSleepAlarm(SleepAlarm alarm) =>
      _player.startSleepAlarm(alarm);

  /// Stops the running sleep alarm.
  Future<void> stopSleepAlarm() => _player.stopSleepAlarm();

  /// Saves the queue so the next launch can resume it.
  Future<void> saveState() => _player.saveState();

  Future<void> _onItemChanged() async {
    final item = _player.currentItem.value;
    if (item == null || item.stid == _currentStid.value) return;
    _currentStid.value = item.stid;
    notifyListeners();

    final artUri = item.artUri?.toString() ?? '';
    if (artUri != _artUri) {
      _artUri = artUri;
      try {
        _currentBlurhash.value = artUri.isEmpty
            ? null
            : await _blurhash.encodeUrl(
                artUri,
                detailed: _settings.settings.useDetailedBlurhash,
              );
      } on Exception catch (e) {
        debugPrint('Blurhash failed: $e');
      }
    }

    if (!item.isMix && int.tryParse(item.stid) != null) {
      await _history.addPlayedTrack(item.stid);
    }
  }

  void _onPlayerMessage(PlayerMessage message) {
    _messages.show(switch (message) {
      PlayerMessage.keepAppOpen => WarningMessage(
        (l10n) => l10n.donotterminatetheapp,
      ),
      PlayerMessage.sleepAlarmEnabled => WarningMessage(
        (l10n) => l10n.sleepalarmisenabled,
      ),
      PlayerMessage.cannotHaltDuringSleepAlarm => ErrorMessage(
        title: (l10n) => l10n.unabletohaltthemusicplayer,
        body: (l10n) =>
            l10n.unabletohaltthemusicplayerbecausesleepalarmiscurrentlyon,
      ),
      PlayerMessage.repeatOff => InfoMessage(
        title: (l10n) => l10n.successful,
        body: (l10n) => l10n.repeatoff,
        icon: AppIcons.repeat,
        iconColor: const Color(0x96FFFFFF),
      ),
      PlayerMessage.repeatOne => InfoMessage(
        title: (l10n) => l10n.successful,
        body: (l10n) => l10n.repeatthissong,
        icon: AppIcons.repeatOne,
      ),
      PlayerMessage.repeatAll => InfoMessage(
        title: (l10n) => l10n.successful,
        body: (l10n) => l10n.repeatthequeue,
        icon: AppIcons.repeat,
      ),
    });
  }

  @override
  void dispose() {
    _player.currentItem.removeListener(_onItemChanged);
    unawaited(_messageSubscription.cancel());
    _currentStid.dispose();
    _currentBlurhash.dispose();
    super.dispose();
  }
}

/// Access to the [PlayerViewModel] from widgets.
extension PlayerContext on BuildContext {
  /// The shared player view model.
  PlayerViewModel get player => read<PlayerViewModel>();
}
