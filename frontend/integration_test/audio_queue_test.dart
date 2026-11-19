// Runs on a phone against the API on this Mac, using the stream token the app
// stored when signing in: flutter test integration_test -d <device>
import 'package:audio_service/audio_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:pongo/config/app_config.dart';
import 'package:pongo/data/services/audio/pongo_audio_handler.dart';
import 'package:pongo/data/services/device/volume_service.dart';
import 'package:pongo/data/services/local/secure_storage_service.dart';
import 'package:pongo/utils/platform.dart';

MediaItem item(String id) => MediaItem(
  id: 'online.mix.$id',
  title: 'Track $id',
  extras: const {'downloaded': 'false', 'artists': '[]'},
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('plays and edits the queue', (tester) async {
    await tester.runAsync(() async {
      await dotenv.load();
      final config = AppConfig.fromEnvironment();
      final streamToken =
          await SecureStorageService().read(StorageKeys.streamToken) ?? '';
      expect(streamToken, isNotEmpty, reason: 'sign in on the phone first');

      final handler = PongoAudioHandler(
        volumeService: VolumeService(),
        streamUrl: (stid, {caching = false}) =>
            '${config.serverUrl}play_song/'
            '${kIsApple ? '' : 'android/'}$stid?st=$streamToken',
      );
      final player = handler.player;
      await player.setVolume(0);

      Future<void> advances() async {
        await player.playerStateStream
            .firstWhere(
              (state) =>
                  state.processingState == ProcessingState.ready &&
                  state.playing,
            )
            .timeout(const Duration(seconds: 60));
        final start = player.position;
        await Future<void>.delayed(const Duration(seconds: 2));
        expect(player.position, greaterThan(start));
      }

      await handler.setQueue([item('2911955931'), item('971054032')]);
      expect(player.audioSources.length, 2);
      await handler.play();
      await advances();

      // Queue edits while playing
      await handler.insertNext(item('971054032'));
      expect(player.audioSources.length, 3);
      await handler.moveQueueItem(1, 2);
      await handler.removeQueueItemAt(2);
      expect(player.audioSources.length, 2);
      await handler.appendToQueue(item('971054032'));
      expect(player.sequence.length, 3);

      // Shuffle and loop, which failed on the disposed player
      await handler.setShuffleMode(AudioServiceShuffleMode.all);
      await handler.setShuffleMode(AudioServiceShuffleMode.none);
      await player.setLoopMode(LoopMode.off);

      // The next track and a fresh start of the queue both still play
      await handler.skipToQueueItem(1);
      await advances();
      await handler.setQueue([item('2911955931')]);
      await handler.play();
      await advances();

      await player.stop();
      await player.clearAudioSources();
      expect(player.audioSources, isEmpty);
    });
  });
}
