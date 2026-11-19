import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:pongo/data/services/audio/pongo_audio_handler.dart';
import 'package:pongo/data/services/device/volume_service.dart';

/// A player whose current index the test sets.
class _FakePlayer extends Fake implements AudioPlayer {
  final index = StreamController<int?>.broadcast(sync: true);
  final _volumes = StreamController<double>.broadcast(sync: true);

  @override
  double volume = 1;

  @override
  Stream<PlaybackEvent> get playbackEventStream => const Stream.empty();
  @override
  Stream<ProcessingState> get processingStateStream => const Stream.empty();
  @override
  Stream<int?> get currentIndexStream => index.stream;
  @override
  Stream<bool> get playingStream => const Stream.empty();
  @override
  Stream<Duration?> get durationStream => const Stream.empty();
  @override
  Stream<double> get volumeStream => _volumes.stream;

  @override
  Future<void> setVolume(double volume) async {
    this.volume = volume;
    _volumes.add(volume);
  }
}

MediaItem item(String stid) =>
    MediaItem(id: 'online.album:1.$stid', title: stid);

void main() {
  late _FakePlayer player;
  late PongoAudioHandler handler;

  setUp(() {
    player = _FakePlayer();
    handler = PongoAudioHandler(
      streamUrl: (stid, {caching = false}) => '',
      volumeService: VolumeService(),
      player: player,
      gainFor: (stid) async => {'loud': -6.0, 'quiet': 0.0}[stid],
    );
    handler.queue.add([item('loud'), item('quiet'), item('unknown')]);
  });

  test('plays each track at its gain under the volume the user set', () async {
    await handler.setVolume(0.5);
    player.index.add(0);
    await pumpEventQueue();
    expect(player.volume, closeTo(0.5 * 0.501, 0.001));

    player.index.add(1);
    await pumpEventQueue();
    expect(player.volume, 0.5);

    // A track without a known gain plays as it is
    player.index.add(0);
    await pumpEventQueue();
    player.index.add(2);
    await pumpEventQueue();
    expect(player.volume, 0.5);
  });

  test('a volume change keeps the gain of the current track', () async {
    player.index.add(0);
    await pumpEventQueue();
    await handler.setVolume(0.8);
    expect(player.volume, closeTo(0.8 * 0.501, 0.001));
  });

  test('reports the volume the user set, not the one with the gain', () async {
    player.index.add(0);
    await pumpEventQueue();
    final reported = handler.volumeStream.first;
    await handler.setVolume(0.6);
    expect(await reported, 0.6);
  });
}
