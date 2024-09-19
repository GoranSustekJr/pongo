import '../../exports.dart';
import 'package:path_provider/path_provider.dart' as syspaths;

class AudioServiceHandler extends BaseAudioHandler
    implements AudioHandler, QueueHandler, SeekHandler {
  // AudioPlayer instance
  final AudioPlayer audioPlayer = AudioPlayer();

  // Fade in/out stream subscription
  late StreamSubscription<Duration> positionSubscription;

  // Volume
  double volume = 1.0;
  double tempVolume = 1.0;

  // TODO:
  ConcatenatingAudioSource playlist = ConcatenatingAudioSource(children: []);

  AudioServiceHandler() {
    audioPlayer.playbackEventStream.listen(broadcastState);
    audioPlayer.setAudioSource(playlist);
    audioPlayer.processingStateStream.listen((state) async {
      if (state == ProcessingState.completed) {
        if (queue.value.length - 1 == audioPlayer.currentIndex) {
          await skipToQueueItem(0);
          pause();
        } else {
          skipToNext();
        }
      }
    });
  }

  exists(MediaItem item) async {
    File file = File(item.artHeaders!["audio"]!);

    // Check if the file exists
    bool fileExists = await file.exists();

    if (fileExists) {
      print('File exists!');
    } else {
      print('File does not exist!');
    }
  }

  // Create audio source from media item
  AudioSource createAudioSource(MediaItem item) {
    return item.extras!["downloaded"] == "true"
        ? AudioSource.file(item.extras!["audio"]!)
        : LockCachingAudioSource(
            Uri.parse(
                "${AppConstants.SERVER_URL}play_song/${item.id.split(".")[2]}"),
          );
  }

  // Listen for changes in the current song index and update the media item
  void listenForCurrentSongIndexChanges() {
    audioPlayer.currentIndexStream.listen((index) {
      final playlist = queue.value;
      if (index == null || playlist.isEmpty) return;
      mediaItem.add(playlist[index]);
    });
  }

  Future<void> startFadeOut() async {
    tempVolume = volume;
    Duration fadeDuration = const Duration(milliseconds: 101);
    int steps = 10; // Number of steps in the fade
    double stepSize = tempVolume / steps;
    int stepTime = (fadeDuration.inMilliseconds / steps).round();

    for (int i = 0; i < steps; i++) {
      audioPlayer.setVolume(tempVolume - stepSize * (i + 1));
      await Future.delayed(Duration(milliseconds: stepTime));
    }
    audioPlayer.setVolume(0.0); // Ensure volume is zero at the end
  }

  Future<void> startFadeIn() async {
    Duration fadeDuration = const Duration(milliseconds: 400);
    int steps = 10;
    double stepSize = tempVolume / steps;
    int stepTime = (fadeDuration.inMilliseconds / steps).round();

    for (int i = 0; i < steps; i++) {
      audioPlayer.setVolume(stepSize * (i + 1));
      await Future.delayed(Duration(milliseconds: stepTime));
    }
    audioPlayer.setVolume(tempVolume);
  }

  // Broadcast the current playback state based on the received PlaybackEvent
  void broadcastState(PlaybackEvent event) {
    audioPlayer.playbackEventStream.listen((PlaybackEvent event) {
      final playing = audioPlayer.playing;
      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.stop,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
        },
        androidCompactActionIndices: const [0, 1, 3],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[audioPlayer.processingState]!,
        repeatMode: const {
          LoopMode.off: AudioServiceRepeatMode.none,
          LoopMode.one: AudioServiceRepeatMode.one,
          LoopMode.all: AudioServiceRepeatMode.all,
        }[audioPlayer.loopMode]!,
        shuffleMode: (audioPlayer.shuffleModeEnabled)
            ? AudioServiceShuffleMode.all
            : AudioServiceShuffleMode.none,
        playing: playing,
        updatePosition: audioPlayer.position,
        bufferedPosition: audioPlayer.bufferedPosition,
        speed: audioPlayer.speed,
        queueIndex: event.currentIndex,
      ));
    });
  }

  // Clear and play
  Future<void> clearAndPlay({required List<MediaItem> songs}) async {
    // First clear the playlista and the mediaItem queue
    playlist.clear();
    queue.value.clear();

    // Start playing
    playlist.addAll(songs.map(createAudioSource).toList());
    queue.add(songs);
  }

  // Halt audio player
  Future<void> halt() async {
    // Stop the audio player
    await audioPlayer.stop();

    // Empty playlist and queue
    playlist.clear();
    playlist.sequence.clear();
    playlist.shuffleIndices.clear();
    queue.value.clear();
    if (audioPlayer.sequence != null) {
      audioPlayer.sequence!.clear();
    }

    // Remove current media item
    mediaItem.value = null;

    // Init empty playlist
    audioPlayer.setAudioSource(playlist);
  }

  // Function to initialize the songs and set up the audio player
  Future<void> initSongs({required List<MediaItem> songs}) async {
    // Listen for playback events and broadcast the state

    // Create a list of audio sources from the provided songs
    await playlist.clear();
    queue.value.clear();

    await playlist.addAll(songs.map(createAudioSource).toList());
    // Set the audio source of the audio player to the concatenation of the audio sources
    // Add the songs to the queue
    queue.add(songs);
    await audioPlayer.setAudioSource(playlist);
    // Listen for changes in the current song index
    listenForCurrentSongIndexChanges();

    // Listen for processing state changes and skip to the next song when completed
  }

  // Play function to start playback
  @override
  Future<void> play() async {
    audioPlayer.play();
    startFadeIn();
  }

  // Pause function to pause playback
  @override
  Future<void> pause() async {
    await startFadeOut();
    audioPlayer.pause();
  }

  // Set volume
  Future<void> setVolume(double volume) async {
    await audioPlayer.setVolume(volume);
    this.volume = volume;
  }

  // Seek function to change the playback position
  @override
  Future<void> seek(Duration position) async => audioPlayer.seek(position);

  // Skip to a specific item in the queue and start playback
  @override
  Future<void> skipToQueueItem(int index) async {
    try {
      await audioPlayer.seek(Duration.zero, index: index);
      play();
    } catch (e) {
      print("Erorrr; $e");
    }
  }

  // Skip to the next item in the queue
  @override
  Future<void> skipToNext() async => audioPlayer.seekToNext();

  // Skip to the previous item in the queue
  @override
  Future<void> skipToPrevious() async => audioPlayer.seekToPrevious();

  // Set repeat mode
  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    switch (repeatMode) {
      case AudioServiceRepeatMode.none:
        audioPlayer.setLoopMode(LoopMode.off);
        break;
      case AudioServiceRepeatMode.one:
      case AudioServiceRepeatMode.group:
      case AudioServiceRepeatMode.all:
        audioPlayer.setLoopMode(LoopMode.all);
        break;
    }
  }

  // Set the shuffle mode
  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    if (shuffleMode == AudioServiceShuffleMode.none) {
      audioPlayer.setShuffleModeEnabled(false);
      await super.setShuffleMode(AudioServiceShuffleMode.none);
      print("Shuffle mdoe, OFF");
    } else if (shuffleMode == AudioServiceShuffleMode.all) {
      audioPlayer.setShuffleModeEnabled(true);
      await super.setShuffleMode(AudioServiceShuffleMode.all);
      print("Shuffle mdoe, ON");
    }
    broadcastState(PlaybackEvent());
  }

  // Get current mediaItem list, a.k.a. the queue

  // Position stream
  Stream<Duration> get positionStream {
    return audioPlayer.positionStream;
  }

  // Buffer Stream
  Stream<Duration> get bufferStream {
    return audioPlayer.bufferedPositionStream;
  }

  // Duration Stream
  Stream<Duration?> get durationStream {
    return audioPlayer.durationStream;
  }

  // Loop Mode Stream
  Stream<LoopMode> get loopModeStream {
    return audioPlayer.loopModeStream;
  }

  Stream<double> get volumeStream {
    return audioPlayer.volumeStream;
  }
}

class MemoryAudioSource extends StreamAudioSource {
  final List<int> bytes;
  MemoryAudioSource(this.bytes);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= bytes.length;
    return StreamAudioResponse(
      sourceLength: bytes.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(bytes.sublist(start, end)),
      contentType: 'audio/mpeg',
    );
  }
}
