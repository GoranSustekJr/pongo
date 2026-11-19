import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:pongo/data/services/audio/pongo_audio_handler.dart';
import 'package:pongo/data/services/device/volume_service.dart';

/// A player whose sources and processing state the test controls; every
/// change emits a playback event, as just_audio does.
class _FakePlayer extends Fake implements AudioPlayer {
  final _events = StreamController<PlaybackEvent>.broadcast(sync: true);

  @override
  ProcessingState processingState = ProcessingState.idle;
  @override
  bool playing = true;
  @override
  int? currentIndex;
  @override
  LoopMode loopMode = LoopMode.all;
  @override
  bool shuffleModeEnabled = false;
  @override
  Duration position = Duration.zero;
  @override
  Duration bufferedPosition = Duration.zero;
  @override
  double speed = 1;

  void emit(ProcessingState state) {
    processingState = state;
    _events.add(PlaybackEvent(processingState: state));
  }

  @override
  Stream<PlaybackEvent> get playbackEventStream => _events.stream;
  @override
  Stream<ProcessingState> get processingStateStream => const Stream.empty();
  @override
  Stream<int?> get currentIndexStream => const Stream.empty();
  @override
  Stream<bool> get playingStream => const Stream.empty();

  @override
  Future<void> clearAudioSources() async {
    currentIndex = null;
    emit(ProcessingState.idle);
  }

  @override
  Future<void> addAudioSources(List<AudioSource> sources) async {
    currentIndex = 0;
    emit(ProcessingState.loading);
  }

  @override
  Future<void> stop() async {
    playing = false;
    emit(ProcessingState.idle);
  }
}

MediaItem _item(String stid) => MediaItem(
  id: 'library.locals.$stid',
  title: 'Song $stid',
  extras: const {'downloaded': 'true', 'audio': '/tmp/song.mp3'},
);

void main() {
  late _FakePlayer player;
  late PongoAudioHandler handler;
  late List<AudioProcessingState> reported;

  setUp(() {
    player = _FakePlayer();
    handler = PongoAudioHandler(
      streamUrl: (stid, {caching = false}) => '',
      volumeService: VolumeService(),
      player: player,
    );
    reported = [];
    handler.playbackState.listen(
      (state) => reported.add(state.processingState),
    );
  });

  // audio_service clears the lock screen and Control Center whenever idle is
  // reported, and on iOS they stay empty afterwards.
  test('starting a song never reports idle', () async {
    await handler.setQueue([_item('a')]);
    player.emit(ProcessingState.ready);
    reported.clear();

    await handler.setQueue([_item('b'), _item('c')]);
    player.emit(ProcessingState.ready);

    await pumpEventQueue();
    expect(reported, isNot(contains(AudioProcessingState.idle)));
    expect(handler.mediaItem.value?.title, 'Song b');
  });

  test('the first song after launch never reports idle', () async {
    reported.clear();
    await handler.setQueue([_item('a')]);
    await pumpEventQueue();
    expect(reported, isNot(contains(AudioProcessingState.idle)));
  });

  test('halting reports idle so the system removes the player', () async {
    await handler.setQueue([_item('a')]);
    await handler.halt();
    expect(
      handler.playbackState.value.processingState,
      AudioProcessingState.idle,
    );
    expect(handler.mediaItem.value, isNull);
  });
}
