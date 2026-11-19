import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:pongo/data/services/audio/pongo_audio_handler.dart';
import 'package:pongo/data/services/device/volume_service.dart';

/// A player that keeps its sources in a list and reports what it's told to.
class _FakePlayer extends Fake implements AudioPlayer {
  final events = StreamController<PlaybackEvent>.broadcast();
  final durations = StreamController<Duration?>.broadcast();
  final sources = <AudioSource>[];
  final seeks = <(Duration?, int?)>[];

  @override
  bool playing = false;
  @override
  int? currentIndex;
  @override
  Duration position = const Duration(seconds: 42);

  @override
  Stream<PlaybackEvent> get playbackEventStream => events.stream;
  @override
  Stream<ProcessingState> get processingStateStream => const Stream.empty();
  @override
  Stream<int?> get currentIndexStream => const Stream.empty();
  @override
  Stream<bool> get playingStream => const Stream.empty();
  @override
  Stream<Duration?> get durationStream => durations.stream;

  @override
  Future<void> clearAudioSources() async => sources.clear();
  @override
  Future<void> addAudioSources(List<AudioSource> added) async {
    sources.addAll(added);
    currentIndex ??= 0;
  }

  @override
  Future<void> removeAudioSourceAt(int index) async => sources.removeAt(index);
  @override
  Future<void> insertAudioSource(int index, AudioSource source) async =>
      sources.insert(index, source);
  @override
  Future<void> seek(Duration? position, {int? index}) async =>
      seeks.add((position, index));
  @override
  Future<void> play() async => playing = true;
}

MediaItem _item(String stid, {Duration duration = Duration.zero}) => MediaItem(
  id: 'online.album:1.$stid',
  title: stid,
  duration: duration,
  extras: const {'online': true},
);

String _url(AudioSource source) => (source as UriAudioSource).uri.toString();

void main() {
  late _FakePlayer player;
  late PongoAudioHandler handler;

  setUp(() {
    player = _FakePlayer();
    handler =
        PongoAudioHandler(
            streamUrl: (stid, {caching = false}) => 'library/$stid',
            downloadStreamUrl: (stid) => 'download/$stid/index.m3u8',
            volumeService: VolumeService(),
            player: player,
          )
          ..preferences = (
            useCachingSource: false,
            linearSleepIn: true,
            linearWakeUp: true,
            alarmDeviceVolume: 0,
          );
  });

  test('plays a downloading track from its stream, then from the library', () {
    handler.streamWhileDownloading('7');
    expect(_url(handler.audioSourceFor(_item('7'))), 'download/7/index.m3u8');
    expect(_url(handler.audioSourceFor(_item('8'))), 'library/8');

    handler.downloadFinished('7', available: true);
    expect(_url(handler.audioSourceFor(_item('7'))), 'library/7');
  });

  test('fills in the length once the player knows it', () async {
    handler.streamWhileDownloading('7');
    await handler.setQueue([_item('7')]);
    player.durations.add(const Duration(minutes: 3));
    await pumpEventQueue();

    expect(handler.queue.value.single.duration, const Duration(minutes: 3));
    // Known lengths stay
    player.durations.add(const Duration(minutes: 1));
    await pumpEventQueue();
    expect(handler.queue.value.single.duration, const Duration(minutes: 3));
  });

  test('a failed stream carries on from the library once downloaded', () async {
    handler.streamWhileDownloading('7');
    await handler.setQueue([_item('7')]);
    handler.mediaItem.add(handler.queue.value.single);
    player.playing = true;

    player.events.addError(PlayerException(404, 'Not streamable', 0));
    await pumpEventQueue();
    // Still downloading, so there's nothing to play yet
    expect(_url(player.sources.single), 'download/7/index.m3u8');

    await handler.downloadFinished('7', available: true);
    expect(_url(player.sources.single), 'library/7');
    expect(player.seeks.single, (const Duration(seconds: 42), 0));
  });

  test(
    'a stream that fails after the download plays from the library',
    () async {
      handler.streamWhileDownloading('7');
      await handler.setQueue([_item('7')]);
      handler.mediaItem.add(handler.queue.value.single);
      await handler.downloadFinished('7', available: true);

      player.events.addError(PlayerException(404, 'Gone', 0));
      await pumpEventQueue();
      expect(_url(player.sources.single), 'library/7');
    },
  );

  test("errors of tracks that aren't streamed are left alone", () async {
    await handler.setQueue([_item('8', duration: const Duration(minutes: 2))]);
    handler.mediaItem.add(handler.queue.value.single);

    player.events.addError(PlayerException(404, 'Not found', 0));
    await pumpEventQueue();
    expect(player.seeks, isEmpty);
  });
}
