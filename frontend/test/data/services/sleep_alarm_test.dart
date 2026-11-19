import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:pongo/data/services/audio/pongo_audio_handler.dart';
import 'package:pongo/data/services/device/volume_service.dart';
import 'package:pongo/domain/models/sleep_alarm/sleep_alarm.dart';

/// A player that records play, pause and volume changes.
class _FakePlayer extends Fake implements AudioPlayer {
  @override
  bool playing = true;
  @override
  double volume = 1;
  @override
  LoopMode loopMode = LoopMode.all;

  /// Every time playback was paused.
  int pauses = 0;

  @override
  Stream<PlaybackEvent> get playbackEventStream => const Stream.empty();
  @override
  Stream<ProcessingState> get processingStateStream => const Stream.empty();
  @override
  Stream<int?> get currentIndexStream => const Stream.empty();
  @override
  Stream<bool> get playingStream => const Stream.empty();

  @override
  Future<void> play() async {
    playing = true;
    // Like just_audio, completes only once playback pauses again.
    await Completer<void>().future;
  }

  @override
  Future<void> pause() async {
    playing = false;
    pauses++;
  }

  @override
  Future<void> setVolume(double volume) async => this.volume = volume;

  @override
  Future<void> setLoopMode(LoopMode mode) async => loopMode = mode;
}

class _FakeVolume extends VolumeService {
  double? deviceVolume;

  @override
  Future<void> setVolume(double volume) async => deviceVolume = volume;
}

void main() {
  late _FakePlayer player;
  late _FakeVolume device;
  late PongoAudioHandler handler;

  setUp(() {
    player = _FakePlayer();
    device = _FakeVolume();
    handler =
        PongoAudioHandler(
            streamUrl: (stid, {caching = false}) => '',
            volumeService: device,
            player: player,
          )
          ..preferences = (
            useCachingSource: false,
            linearSleepIn: true,
            linearWakeUp: true,
            alarmDeviceVolume: 0.7,
          );
  });

  test('fades out, keeps playing silently and fades back in', () {
    // 22:00; the alarm ends at 22:30 after a 10 minute fade in.
    fakeAsync((async) {
      const alarm = SleepAlarm(
        id: 1,
        sleepDuration: 10,
        alarmClock: true,
        wakeTime: 22 * 60 + 30,
        beforeEndTimeMin: 10,
      );
      unawaited(handler.startSleepAlarm(alarm));

      async.elapse(const Duration(minutes: 5));
      expect(player.volume, closeTo(0.5, 0.02));

      async.elapse(const Duration(minutes: 6));
      expect(player.volume, 0);
      expect(player.playing, isTrue, reason: 'iOS suspends a silent app');
      expect(player.pauses, 0);
      expect(handler.activeSleepAlarm, 1);

      // The fade in starts at 22:20.
      async.elapse(const Duration(minutes: 8));
      expect(player.volume, 0);
      async.elapse(const Duration(minutes: 6));
      expect(device.deviceVolume, 0.7);
      expect(player.volume, greaterThan(0.3));
      expect(player.volume, lessThan(0.7));

      async.elapse(const Duration(minutes: 6));
      expect(player.volume, 1);
      expect(player.playing, isTrue);
      expect(player.pauses, 0);
      expect(handler.activeSleepAlarm, -1);
    }, initialTime: DateTime(2026, 11, 10, 22));
  });

  test('a wake-up alarm restarts the music if something paused it', () {
    fakeAsync((async) {
      const alarm = SleepAlarm(
        id: 2,
        sleep: false,
        alarmClock: true,
        wakeTime: 7 * 60 + 30,
        beforeEndTimeMin: 10,
      );
      unawaited(handler.startSleepAlarm(alarm));
      async.flushMicrotasks();
      expect(player.volume, 0);
      expect(player.playing, isTrue);

      player.playing = false; // An interruption, such as a call.
      async.elapse(const Duration(seconds: 10));
      expect(player.playing, isTrue);

      async.elapse(const Duration(hours: 1, minutes: 30));
      expect(player.volume, 1);
      expect(handler.activeSleepAlarm, -1);
    }, initialTime: DateTime(2026, 11, 10, 6));
  });

  test('stopping an alarm cancels its wake up', () {
    fakeAsync((async) {
      const alarm = SleepAlarm(
        id: 3,
        sleep: false,
        alarmClock: true,
        wakeTime: 7 * 60,
        beforeEndTimeMin: 10,
      );
      unawaited(handler.startSleepAlarm(alarm));
      async.flushMicrotasks();
      unawaited(handler.stopSleepAlarm());
      async.elapse(const Duration(hours: 2));
      expect(device.deviceVolume, isNull);
      expect(player.playing, isFalse);
    }, initialTime: DateTime(2026, 11, 10, 6));
  });

  group('wake-up schedule', () {
    SleepAlarm alarm(int hour, int minute, {int fadeIn = 1}) => SleepAlarm(
      id: 1,
      sleep: false,
      alarmClock: true,
      wakeTime: hour * 60 + minute,
      beforeEndTimeMin: fadeIn,
    );

    test('waking in a minute with a minute of fade in starts now', () {
      // The case from the phone: started at 18:44:03 to wake at 18:45.
      final now = DateTime(2026, 11, 11, 18, 44, 3);
      final schedule = PongoAudioHandler.wakeUpSchedule(alarm(18, 45), now);
      expect(schedule.fadeInAt, now);
      expect(schedule.fadeIn, const Duration(seconds: 57));
    });

    test('a later wake time fades in for its full duration', () {
      final schedule = PongoAudioHandler.wakeUpSchedule(
        alarm(7, 30, fadeIn: 30),
        DateTime(2026, 11, 11, 23, 15),
      );
      expect(schedule.fadeInAt, DateTime(2026, 11, 12, 7));
      expect(schedule.fadeIn, const Duration(minutes: 30));
    });

    test('a wake time that has passed is tomorrow', () {
      final schedule = PongoAudioHandler.wakeUpSchedule(
        alarm(18, 45),
        DateTime(2026, 11, 11, 18, 45),
      );
      expect(schedule.fadeInAt, DateTime(2026, 11, 12, 18, 44));
    });
  });
}
