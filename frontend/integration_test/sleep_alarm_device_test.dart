// Runs a short sleep alarm on a phone with the real player and volume
// plugins: flutter test integration_test/sleep_alarm_device_test.dart \
//   -d <device> --no-uninstall
// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pongo/data/services/audio/pongo_audio_handler.dart';
import 'package:pongo/data/services/device/volume_service.dart';
import 'package:pongo/domain/models/sleep_alarm/sleep_alarm.dart';

/// Writes a quiet 30 second tone as a WAV file and returns its path.
Future<String> writeTone() async {
  const rate = 22050;
  const seconds = 30;
  final samples = Int16List(rate * seconds);
  for (var i = 0; i < samples.length; i++) {
    samples[i] = (sin(2 * pi * 440 * i / rate) * 2000).toInt();
  }
  final data = samples.buffer.asUint8List();
  final header = ByteData(44)
    ..setUint32(0, 0x52494646) // RIFF
    ..setUint32(4, 36 + data.length, Endian.little)
    ..setUint32(8, 0x57415645) // WAVE
    ..setUint32(12, 0x666d7420) // fmt
    ..setUint32(16, 16, Endian.little)
    ..setUint16(20, 1, Endian.little)
    ..setUint16(22, 1, Endian.little)
    ..setUint32(24, rate, Endian.little)
    ..setUint32(28, rate * 2, Endian.little)
    ..setUint16(32, 2, Endian.little)
    ..setUint16(34, 16, Endian.little)
    ..setUint32(36, 0x64617461) // data
    ..setUint32(40, data.length, Endian.little);
  final file = File('${(await getTemporaryDirectory()).path}/tone.wav');
  await file.writeAsBytes([...header.buffer.asUint8List(), ...data]);
  return file.path;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'sleeps and wakes up',
    timeout: const Timeout(Duration(minutes: 8)),
    (tester) async {
      await tester.runAsync(() async {
        final session = await AudioSession.instance;
        await session.configure(const AudioSessionConfiguration.music());
        final volume = VolumeService();
        await volume.start();
        print('ALARM device volume at start ${volume.volume}');

        final handler =
            PongoAudioHandler(
                volumeService: volume,
                streamUrl: (stid, {caching = false}) => '',
              )
              ..preferences = (
                useCachingSource: false,
                linearSleepIn: true,
                linearWakeUp: true,
                alarmDeviceVolume: 0.3,
              );
        final player = handler.player;
        await handler.setQueue([
          MediaItem(
            id: 'library.locals.tone',
            title: 'Tone',
            extras: {'downloaded': 'true', 'audio': await writeTone()},
          ),
        ]);
        await handler.play();

        // The bug only shows while the phone is locked, so wait for that.
        print('ALARM lock the phone now');
        final locked = DateTime.now().add(const Duration(minutes: 5));
        while (WidgetsBinding.instance.lifecycleState ==
                AppLifecycleState.resumed &&
            DateTime.now().isBefore(locked)) {
          await Future<void>.delayed(const Duration(seconds: 1));
        }
        print('ALARM app state ${WidgetsBinding.instance.lifecycleState}');

        // Fades out over a minute, then fades in over the minute before the
        // wake time, three or four minutes from now.
        final now = DateTime.now();
        final alarm = SleepAlarm(
          id: 99,
          sleepDuration: 1,
          alarmClock: true,
          wakeTime: now.hour * 60 + now.minute + 4,
          beforeEndTimeMin: 1,
        );
        await handler.startSleepAlarm(alarm);
        print(
          'ALARM started at $now, wake ${alarm.wakeTime ~/ 60}:'
          '${alarm.wakeTime % 60}',
        );

        var heardAfterSilence = false;
        var wasSilent = false;
        final end = now.add(const Duration(minutes: 6));
        while (DateTime.now().isBefore(end)) {
          await Future<void>.delayed(const Duration(seconds: 10));
          print(
            'ALARM ${DateTime.now().toIso8601String().substring(11, 19)} '
            'player ${player.volume.toStringAsFixed(2)} '
            'playing ${player.playing} device ${volume.volume} '
            'active ${handler.activeSleepAlarm}',
          );
          if (player.volume == 0) wasSilent = true;
          if (wasSilent && player.volume > 0.5) heardAfterSilence = true;
          if (handler.activeSleepAlarm == -1 && heardAfterSilence) break;
        }
        await handler.stopSleepAlarm();
        expect(wasSilent, isTrue);
        expect(heardAfterSilence, isTrue);
      });
    },
  );
}
