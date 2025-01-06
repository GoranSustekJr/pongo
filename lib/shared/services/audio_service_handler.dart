import '../../exports.dart';
import 'package:path_provider/path_provider.dart' as syspaths;

class AudioServiceHandler extends BaseAudioHandler
    implements QueueHandler, CompositeAudioHandler, SeekHandler {
  // AudioPlayer instance
  final AudioPlayer audioPlayer = AudioPlayer();

  // Fade in/out stream subscription
  // late StreamSubscription<Duration> positionSubscription;

  // Volume
  double volume = 1.0;
  double tempVolume = 1.0;

  // Ad
  InterstitialAd? interstitialAd;
  String adUnitId = "ca-app-pub-3940256099942544/4411468910";

  // Playlist
  ConcatenatingAudioSource playlist = ConcatenatingAudioSource(children: []);

  AudioServiceHandler() {
    importSettings(); // import audio player settings
    try {
      audioPlayer.playbackEventStream.listen(broadcastState);
      audioPlayer.setAudioSource(playlist);
      //listenForNewTracks();
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
    } catch (e) {
      print(e);
    }
  }

  void importSettings() async {
    // Loop mode
    AudioServiceRepeatMode loopMde = await Storage().getLoopMode();
    setRepeatMode(loopMde, notify: false);

    // Shuffle mode
    AudioServiceShuffleMode shuffleMde = await Storage().getShuffleMode();
    setShuffleMode(shuffleMde);

    // Queue, queue index and position
    List<MediaItem> queueList = await Storage().getQueue();
    int queueIndex = await Storage().getQueueIndex();
    Duration position = await Storage().getCurrentPlayingPosition();
    print(queueList);
    print(queueIndex);
    print(position);
    await initSongs(songs: queueList);
    if (queueIndex != -1) {
      skipToQueueItem(queueIndex, playAuto: false);
    }
    seek(position);
  }

  // Create audio source from media item
  AudioSource createAudioSource(MediaItem item) {
    print(item.extras);
    /* final accessTokenHandler =
        Provider.of<AccessToken>(searchScreenContext.value!, listen: false); */
    return item.extras!["downloaded"] == "true"
        ? AudioSource.file(item.extras!["audio"])
        : useCacheAudioSource.value
            ? LockCachingAudioSource(
                Uri.parse(
                    "${AppConstants.SERVER_URL}play_song_caching/${item.id.split(".")[2]}"),
                /* headers: {
                  "Authorization": "${accessTokenHandler.accessToken}",
                  "Content-Type": "application/json",
                }, */
                tag: item,
              )
            : AudioSource.uri(
                Uri.parse(
                    "${AppConstants.SERVER_URL}play_song/${item.id.split(".")[2]}"),
                /*  headers: {
                  "Authorization": "${accessTokenHandler.accessToken}",
                  "Content-Type": "application/json",
                }, */
                tag: item,
              ) as AudioSource;
  }

  // Listen for changes in the current song index and update the media item
  void listenForCurrentSongIndexChanges() {
    audioPlayer.currentIndexStream.listen((index) {
      final playlist = queue.value;
      if (index == null || playlist.isEmpty) return;
      mediaItem.add(playlist[index]);
    });

    /* MediaItem? tempMediaItem;

    mediaItem.stream.listen(
      (mediaItem) async {
if (mediaItem != null){
        print("SHIT ${mediaItem.id != tempMediaItem?.id}");
        print("One; $mediaItem");
        print("Two: $tempMediaItem");

        if (mediaItem.id != tempMediaItem?.id) {
          tempMediaItem = mediaItem;
          print(tempMediaItem);

          await DatabaseHelper().insertLFHTracks(mediaItem.id.split(".")[2]);
                }
      }}
    ); */
  }

  void listenForNewTracks() async {
    audioPlayer.positionStream.listen(
      (Duration position) async {
        print(position);
        if (position == audioPlayer.duration) {
          print("object");
          await InterstitialAd.load(
              adUnitId: adUnitId,
              request: const AdRequest(),
              adLoadCallback: InterstitialAdLoadCallback(
                // Called when an ad is successfully received.
                onAdLoaded: (ad) {
                  ad.fullScreenContentCallback = FullScreenContentCallback(
                      // Called when the ad showed the full screen content.
                      onAdShowedFullScreenContent: (ad) {
                        pause();
                      },
                      // Called when an impression occurs on the ad.
                      onAdImpression: (ad) {},
                      // Called when the ad failed to show full screen content.
                      onAdFailedToShowFullScreenContent: (ad, err) {
                        // Dispose the ad here to free resources.
                        ad.dispose();
                      },
                      // Called when the ad dismissed full screen content.
                      onAdDismissedFullScreenContent: (ad) {
                        // Dispose the ad here to free resources.
                        play();
                        ad.dispose();
                      },
                      // Called when a click is recorded for an ad.
                      onAdClicked: (ad) {});

                  debugPrint('$ad loaded.');
                  // Keep a reference to the ad so you can show it later.
                  interstitialAd = ad;
                },
                // Called when an ad request failed.
                onAdFailedToLoad: (LoadAdError error) {
                  debugPrint('InterstitialAd failed to load: $error');
                },
              ));
          if (interstitialAd != null) {
            await interstitialAd!.show();
          }
        }
      },
    );
  }

  void reorderQueue(AudioServiceHandler audioServiceHandler, int oldIndex,
      int newIndex) async {
    newIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
    // Retrieve the current queue
    final currentQueue = audioServiceHandler.queue.value;

    // Check if the indices are valid
    if (oldIndex < 0 ||
        oldIndex >= currentQueue.length ||
        newIndex < 0 ||
        newIndex >= currentQueue.length) {
      return; // Exit if indices are out of bounds
    }

    // Remove the item from the old index
    final itemToMove = currentQueue.removeAt(oldIndex);

    // Insert the item at the new index
    currentQueue.insert(newIndex, itemToMove);

    // Update the queue in the audio service handler
    audioServiceHandler.queue.value = currentQueue;

    // Move index in the playlist
    await playlist.move(oldIndex, newIndex);
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
    Duration fadeDuration = const Duration(milliseconds: 500);
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

/*   // Clear and play
  Future<void> clearAndPlay({required List<MediaItem> songs}) async {
    // First clear the playlista and the mediaItem queue
    playlist.clear();
    queue.value.clear();

    // Start playing
    playlist.addAll(songs.map(createAudioSource).toList());
    queue.add(songs);
  } */

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
    // Add track to history

    // Create a list of audio sources from the provided songs
    await playlist.clear();
    queue.value.clear();
    await playlist.addAll(songs.map(createAudioSource).toList());
    // Set the audio source of the audio player to the concatenation of the audio sources
    // Add the songs to the queue
    queue.add(songs);
    //await audioPlayer.setAudioSource(playlist);
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
  Future<void> skipToQueueItem(int index, {bool playAuto = true}) async {
    try {
      await audioPlayer.seek(Duration.zero, index: index);
      if (playAuto) {
        play();
      }
    } catch (e) {
      print("Erorrr; $e");
    }
  }

  // Skip to the next item in the queue
  @override
  Future<void> skipToNext() async => audioPlayer.seekToNext();

  // Skip to the previous item in the queue
  @override
  Future<void> skipToPrevious() async {
    if (audioPlayer.position.inSeconds < 5) {
      await audioPlayer.seekToPrevious();
    } else {
      await seek(const Duration(seconds: 0));
    }
  }

  // Set repeat mode
  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode,
      {bool notify = true}) async {
    switch (repeatMode) {
      case AudioServiceRepeatMode.none:
        audioPlayer.setLoopMode(LoopMode.off);
        if (notify) {
          Notifications().showSpecialNotification(
            notificationsContext.value!,
            AppLocalizations.of(notificationsContext.value!)!.successful,
            AppLocalizations.of(notificationsContext.value!)!.repeatoff,
            AppIcons.repeat,
            iconColor: Colors.white.withAlpha(150),
          );
        }
        break;
      case AudioServiceRepeatMode.one:
        audioPlayer.setLoopMode(LoopMode.one);
        if (notify) {
          Notifications().showSpecialNotification(
            notificationsContext.value!,
            AppLocalizations.of(notificationsContext.value!)!.successful,
            AppLocalizations.of(notificationsContext.value!)!.repeatthissong,
            AppIcons.repeatOne,
          );
        }
      case AudioServiceRepeatMode.group:
      case AudioServiceRepeatMode.all:
        audioPlayer.setLoopMode(LoopMode.all);
        if (notify) {
          Notifications().showSpecialNotification(
            notificationsContext.value!,
            AppLocalizations.of(notificationsContext.value!)!.successful,
            AppLocalizations.of(notificationsContext.value!)!.repeatthequeue,
            AppIcons.repeat,
          );
        }
        break;
    }
  }

  // Set the shuffle mode
  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    if (shuffleMode == AudioServiceShuffleMode.none) {
      await audioPlayer.setShuffleModeEnabled(false);
      await super.setShuffleMode(AudioServiceShuffleMode.none);
    } else if (shuffleMode == AudioServiceShuffleMode.all) {
      await audioPlayer.setShuffleModeEnabled(true);
      await super.setShuffleMode(AudioServiceShuffleMode.all);
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
