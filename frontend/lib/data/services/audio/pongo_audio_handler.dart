import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../../../domain/models/sleep_alarm/sleep_alarm.dart';
import '../device/volume_service.dart';
import 'sleep_alarm_log.dart';

/// Something the player wants to tell the user.
enum PlayerMessage {
  /// A sleep alarm started; the app must stay open for it to work.
  keepAppOpen,

  /// Play or pause was blocked because an alarm is waiting to wake the user.
  sleepAlarmEnabled,

  /// The player couldn't be stopped because a sleep alarm is active.
  cannotHaltDuringSleepAlarm,

  /// Repeat was turned off.
  repeatOff,

  /// The current track repeats.
  repeatOne,

  /// The queue repeats.
  repeatAll,
}

/// Builds the URL the native player streams a track from.
typedef StreamUrlBuilder = String Function(String stid, {bool caching});

/// Settings the player reads while it plays.
typedef AudioPreferences = ({
  bool useCachingSource,
  bool linearSleepIn,
  bool linearWakeUp,
  double alarmDeviceVolume,
});

/// The background audio handler that plays the queue.
///
/// Media item IDs have the form `<source>.<collection>.<stid>`; the last
/// part is the track ID the audio is streamed by.
class PongoAudioHandler extends BaseAudioHandler {
  /// Creates a handler that plays through [player].
  PongoAudioHandler({
    required this._streamUrl,
    required this._volumeService,
    AudioPlayer? player,
    this._alarmLog,
  }) : player = player ?? AudioPlayer() {
    this.player.playbackEventStream.listen(
      (_) => _broadcastState(),
      onError: (Object _, StackTrace _) {},
    );
    this.player.processingStateStream.listen(_onProcessingStateChanged);
    this.player.currentIndexStream.listen(_onCurrentIndexChanged);
    this.player.playingStream.listen((playing) {
      if (_activeSleepAlarm != -1) _log('playing $playing');
    });
  }

  void _log(String message) => _alarmLog?.add(message);

  /// The underlying player.
  final AudioPlayer player;

  final StreamUrlBuilder _streamUrl;
  final VolumeService _volumeService;
  final SleepAlarmLog? _alarmLog;
  final _messages = StreamController<PlayerMessage>.broadcast();

  /// Settings read while playing, kept current by the settings repository.
  AudioPreferences preferences = (
    useCachingSource: false,
    linearSleepIn: true,
    linearWakeUp: true,
    alarmDeviceVolume: 0.5,
  );

  double _volume = 1;
  double _fadeVolume = 1;
  Timer? _volumeTimer;
  Timer? _wakeTimer;
  bool _blockPlayback = false;
  int _activeSleepAlarm = -1;
  bool _replacingQueue = false;

  /// Messages for the user, such as why a command was ignored.
  Stream<PlayerMessage> get messages => _messages.stream;

  /// The ID of the running sleep alarm, or -1 if none is running.
  int get activeSleepAlarm => _activeSleepAlarm;

  /// Emits the playback position.
  Stream<Duration> get positionStream => player.positionStream;

  /// Emits the buffered position.
  Stream<Duration> get bufferStream => player.bufferedPositionStream;

  /// Emits the length of the current track.
  Stream<Duration?> get durationStream => player.durationStream;

  /// Emits the loop mode.
  Stream<LoopMode> get loopModeStream => player.loopModeStream;

  /// Emits the player volume.
  Stream<double> get volumeStream => player.volumeStream;

  void _onProcessingStateChanged(ProcessingState state) {
    if (state != ProcessingState.completed) return;
    if (queue.value.length - 1 == player.currentIndex) {
      unawaited(skipToQueueItem(0).then((_) => pause()));
    } else {
      unawaited(skipToNext());
    }
  }

  void _onCurrentIndexChanged(int? index) {
    final items = queue.value;
    if (_replacingQueue || index == null || index >= items.length) return;
    mediaItem.add(items[index]);
  }

  /// The audio source that plays [item].
  AudioSource audioSourceFor(MediaItem item) {
    final stid = item.id.split('.')[2];
    if (item.extras?['downloaded'] == 'true') {
      return AudioSource.file(item.extras!['audio'] as String, tag: item);
    }
    if (preferences.useCachingSource) {
      // The caching source is still experimental in just_audio but has been
      // reliable for streaming tracks.
      // ignore: experimental_member_use
      return LockCachingAudioSource(
        Uri.parse(_streamUrl(stid, caching: true)),
        tag: item,
      );
    }
    return AudioSource.uri(Uri.parse(_streamUrl(stid)), tag: item);
  }

  /// Replaces the queue with [items].
  Future<void> setQueue(List<MediaItem> items) async {
    _replacingQueue = true;
    try {
      // Publish the queue first so the brief idle state while the sources are
      // swapped isn't reported (see _processingState).
      queue.add(List.of(items));
      await player.clearAudioSources();
      await player.addAudioSources(items.map(audioSourceFor).toList());
    } finally {
      _replacingQueue = false;
    }
    _onCurrentIndexChanged(player.currentIndex);
  }

  /// Appends [item] to the queue.
  Future<void> appendToQueue(MediaItem item) async {
    queue.add([...queue.value, item]);
    await player.addAudioSource(audioSourceFor(item));
  }

  /// Inserts [item] right after the current track.
  Future<void> insertNext(MediaItem item) async {
    final index = player.currentIndex == null ? 0 : player.currentIndex! + 1;
    queue.add([...queue.value]..insert(index, item));
    await player.insertAudioSource(index, audioSourceFor(item));
  }

  /// Removes the queue item at [index].
  @override
  Future<void> removeQueueItemAt(int index) async {
    queue.add([...queue.value]..removeAt(index));
    await player.removeAudioSourceAt(index);
  }

  /// Moves the queue item at [oldIndex] to [newIndex], where [newIndex] is
  /// the position before the item is removed.
  Future<void> moveQueueItem(int oldIndex, int newIndex) async {
    final target = newIndex > oldIndex ? newIndex - 1 : newIndex;
    final items = [...queue.value];
    if (oldIndex < 0 ||
        oldIndex >= items.length ||
        target < 0 ||
        target >= items.length) {
      return;
    }
    items.insert(target, items.removeAt(oldIndex));
    queue.add(items);
    await player.moveAudioSource(oldIndex, target);
  }

  /// Stops playback and empties the queue, unless a sleep alarm is running.
  ///
  /// Returns whether the player stopped.
  Future<bool> halt() async {
    if (_activeSleepAlarm != -1) {
      _messages.add(PlayerMessage.cannotHaltDuringSleepAlarm);
      return false;
    }
    await player.stop();
    await player.clearAudioSources();
    queue.add(const []);
    _volumeTimer?.cancel();
    mediaItem.add(null);
    // Now that the queue is empty, report idle so the system clears the
    // player from the lock screen.
    _broadcastState();
    return true;
  }

  @override
  Future<void> play() async {
    if (_blockPlayback) {
      _messages.add(PlayerMessage.sleepAlarmEnabled);
      return;
    }
    unawaited(player.play());
    unawaited(_fadeIn());
  }

  @override
  Future<void> pause() async {
    if (_blockPlayback) {
      _messages.add(PlayerMessage.sleepAlarmEnabled);
      return;
    }
    await _fadeOut();
    unawaited(player.pause());
  }

  /// Sets the player volume to [volume].
  Future<void> setVolume(double volume) async {
    await player.setVolume(volume);
    _volume = volume;
  }

  @override
  Future<void> seek(Duration position) => player.seek(position);

  @override
  Future<void> skipToQueueItem(int index) async {
    await player.seek(Duration.zero, index: index);
    await play();
  }

  @override
  Future<void> skipToNext() => player.seekToNext();

  @override
  Future<void> skipToPrevious() async {
    if (player.position.inSeconds < 5) {
      await player.seekToPrevious();
    } else {
      await seek(Duration.zero);
    }
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) =>
      _setRepeatMode(repeatMode, announce: true);

  /// Sets [repeatMode] without telling the user, such as when restoring it.
  Future<void> restoreRepeatMode(AudioServiceRepeatMode repeatMode) =>
      _setRepeatMode(repeatMode, announce: false);

  Future<void> _setRepeatMode(
    AudioServiceRepeatMode repeatMode, {
    required bool announce,
  }) async {
    final (loopMode, message) = switch (repeatMode) {
      AudioServiceRepeatMode.none => (LoopMode.off, PlayerMessage.repeatOff),
      AudioServiceRepeatMode.one => (LoopMode.one, PlayerMessage.repeatOne),
      AudioServiceRepeatMode.group ||
      AudioServiceRepeatMode.all => (LoopMode.all, PlayerMessage.repeatAll),
    };
    await player.setLoopMode(loopMode);
    if (announce) _messages.add(message);
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    await player.setShuffleModeEnabled(
      shuffleMode != AudioServiceShuffleMode.none,
    );
    _broadcastState();
  }

  Future<void> _fadeOut() async {
    _fadeVolume = _volume;
    const steps = 10;
    final stepSize = _fadeVolume / steps;
    for (var i = 0; i < steps; i++) {
      unawaited(player.setVolume(_fadeVolume - stepSize * (i + 1)));
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    unawaited(player.setVolume(0));
  }

  Future<void> _fadeIn() async {
    const steps = 10;
    final stepSize = _fadeVolume / steps;
    for (var i = 0; i < steps; i++) {
      unawaited(player.setVolume(stepSize * (i + 1)));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    unawaited(player.setVolume(_fadeVolume));
  }

  /// Starts [alarm]: fades the music out and, if set, wakes the user later.
  ///
  /// Playback never stops between falling asleep and waking up: iOS suspends
  /// a backgrounded app once its audio stops, which would keep the alarm from
  /// ever firing. While waiting, the music plays at volume 0 instead.
  Future<void> startSleepAlarm(SleepAlarm alarm) async {
    _alarmLog?.clear();
    _log('start $alarm, playing ${player.playing}, volume ${player.volume}');
    _cancelSleepAlarmTimers();
    _activeSleepAlarm = alarm.id;
    if (player.loopMode == LoopMode.off) {
      await setRepeatMode(AudioServiceRepeatMode.all);
    }
    _messages.add(PlayerMessage.keepAppOpen);
    if (alarm.sleep) {
      _fadeToSleep(alarm);
    } else if (alarm.alarmClock) {
      await _waitToWakeUp(alarm);
    }
  }

  /// Stops the running sleep alarm and pauses playback.
  Future<void> stopSleepAlarm() async {
    if (_activeSleepAlarm != -1) _log('stopped by the user');
    _activeSleepAlarm = -1;
    _cancelSleepAlarmTimers();
    _blockPlayback = false;
    await player.pause();
    await player.setVolume(1);
  }

  void _cancelSleepAlarmTimers() {
    _volumeTimer?.cancel();
    _wakeTimer?.cancel();
  }

  void _fadeToSleep(SleepAlarm alarm) {
    var volume = player.volume;
    final stepMilliseconds = (alarm.sleepDuration * 60 / 100 * 1000).toInt();
    // play() completes only once playback pauses again, so don't wait for it.
    unawaited(player.play());

    _volumeTimer = Timer.periodic(Duration(milliseconds: stepMilliseconds), (
      timer,
    ) async {
      if (!player.playing) return;
      if (volume == 0) {
        timer.cancel();
        _log('asleep');
        if (alarm.alarmClock) {
          await _waitToWakeUp(alarm);
        } else {
          await player.pause();
          await player.setVolume(1);
          _activeSleepAlarm = -1;
        }
        return;
      }
      volume = _step(volume, down: true, linear: preferences.linearSleepIn);
      await player.setVolume(volume);
    });
  }

  /// Keeps playing silently until the fade in of [alarm] is due, then starts
  /// it.
  Future<void> _waitToWakeUp(SleepAlarm alarm) async {
    final (:fadeInAt, :fadeIn) = wakeUpSchedule(alarm, clock.now());
    _log('fade in at $fadeInAt for $fadeIn');
    _blockPlayback = true;
    await player.setVolume(0);
    unawaited(player.play());
    var lastHeartbeat = clock.now();

    // Check the clock instead of waiting once: timers can fire late if the
    // system pauses the app for a moment.
    _wakeTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_activeSleepAlarm != alarm.id) {
        timer.cancel();
        return;
      }
      if (clock.now().difference(lastHeartbeat) >=
          const Duration(minutes: 15)) {
        lastHeartbeat = clock.now();
        _log('waiting, playing ${player.playing}, volume ${player.volume}');
      }
      // Keep the app alive if something like a call paused the music.
      if (!player.playing) {
        _log('restarting paused music');
        unawaited(player.play());
      }
      if (clock.now().isBefore(fadeInAt)) return;
      timer.cancel();
      unawaited(_wakeUp(fadeIn));
    });
  }

  Future<void> _wakeUp(Duration fadeIn) async {
    _log('waking up, playing ${player.playing}, volume ${player.volume}');
    _blockPlayback = false;
    if (!player.playing) unawaited(player.play());
    // The fade in mustn't depend on this: it goes through a system volume
    // view that may not respond while the phone is locked.
    unawaited(
      _volumeService
          .setVolume(preferences.alarmDeviceVolume)
          .then(
            (_) => _log('device volume ${preferences.alarmDeviceVolume}'),
            onError: (Object error) => _log('device volume failed: $error'),
          ),
    );

    var volume = 0.0;
    final stepMilliseconds = fadeIn.inMilliseconds ~/ 100;
    _volumeTimer?.cancel();
    _volumeTimer = Timer.periodic(Duration(milliseconds: stepMilliseconds), (
      timer,
    ) async {
      volume = _step(volume, down: false, linear: preferences.linearWakeUp);
      await player.setVolume(volume);
      if ((volume * 100).round() % 25 == 0) {
        _log('volume $volume, player ${player.volume}');
      }
      if (volume == 1) {
        timer.cancel();
        _log('awake');
        _activeSleepAlarm = -1;
      }
    });
  }

  /// When the fade in of [alarm] starts, as seen at [now], and how long it
  /// takes to reach full volume at the wake time.
  ///
  /// The wake time is the next one to come. If its fade in should already
  /// have started, it starts now and takes the time that's left; otherwise an
  /// alarm set to wake in a minute with a minute's fade in would wait a day.
  @visibleForTesting
  static ({DateTime fadeInAt, Duration fadeIn}) wakeUpSchedule(
    SleepAlarm alarm,
    DateTime now,
  ) {
    var wakeAt = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(Duration(minutes: alarm.wakeTime));
    if (!wakeAt.isAfter(now)) wakeAt = wakeAt.add(const Duration(days: 1));
    final fadeIn = Duration(minutes: alarm.beforeEndTimeMin);
    final fadeInAt = wakeAt.subtract(fadeIn);
    return fadeInAt.isAfter(now)
        ? (fadeInAt: fadeInAt, fadeIn: fadeIn)
        : (fadeInAt: now, fadeIn: wakeAt.difference(now));
  }

  /// The next fade volume after [volume], moving slower as it gets quieter
  /// unless [linear].
  double _step(double volume, {required bool down, required bool linear}) {
    final step = linear
        ? 0.01
        : volume > 0.67
        ? 0.03
        : volume > 0.4
        ? 0.02
        : 0.00533;
    return (down ? volume - step : volume + step).clamp(0.0, 1.0);
  }

  /// The processing state reported to the system.
  ///
  /// The player is briefly idle whenever the queue is replaced. Reporting that
  /// makes audio_service stop the service, which clears the lock screen and
  /// Control Center, and on iOS they then stay empty while the music plays.
  /// So idle is only reported once the queue is empty.
  AudioProcessingState get _processingState => switch (player.processingState) {
    ProcessingState.idle when queue.value.isNotEmpty =>
      AudioProcessingState.ready,
    ProcessingState.idle => AudioProcessingState.idle,
    ProcessingState.loading => AudioProcessingState.loading,
    ProcessingState.buffering => AudioProcessingState.buffering,
    ProcessingState.ready => AudioProcessingState.ready,
    ProcessingState.completed => AudioProcessingState.completed,
  };

  void _broadcastState() {
    final playing = player.playing;
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.stop,
          MediaControl.skipToNext,
        ],
        systemActions: const {MediaAction.seek},
        androidCompactActionIndices: const [0, 1, 3],
        processingState: _processingState,
        repeatMode: const {
          LoopMode.off: AudioServiceRepeatMode.none,
          LoopMode.one: AudioServiceRepeatMode.one,
          LoopMode.all: AudioServiceRepeatMode.all,
        }[player.loopMode]!,
        shuffleMode: player.shuffleModeEnabled
            ? AudioServiceShuffleMode.all
            : AudioServiceShuffleMode.none,
        playing: playing,
        updatePosition: player.position,
        bufferedPosition: player.bufferedPosition,
        speed: player.speed,
        queueIndex: player.currentIndex,
      ),
    );
  }
}
