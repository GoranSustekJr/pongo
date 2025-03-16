// ignore_for_file: unused_import

import '../../exports.dart';
import 'dart:math';
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

  // Songs played
  int songsPlayed = 0;

  // Timer for sleep mode
  Timer volumeTimer = Timer(const Duration(seconds: 0), () {});
  int activeSleepAlarm = -1;
  bool stopSleepAlarm = false;
  bool mutePlay = false;

  // Ad
  InterstitialAd? interstitialAd;
  String adUnitId = "ca-app-pub-3940256099942544/4411468910";
  //"ca-app-pub-3931049547680648~4426620774"; // Ios test id "ca-app-pub-3940256099942544/4411468910";

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
          checkToShowAdd();

          if (queue.value.length - 1 == audioPlayer.currentIndex) {
            await skipToQueueItem(0);
            showAdd();
            pause();
          } else {
            skipToNext();
          }
        }
      });
    } catch (e) {
      //print(e);
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

    if (queueList.isNotEmpty) {
      await initSongs(songs: queueList);
      await audioPlayer.setAudioSource(playlist);

      if (queueIndex != -1) {
        await audioPlayer.seek(position, index: queueIndex);
      } else {
        await audioPlayer.seek(position);
      }
    }
  }

  //

  // Create audio source from media item
  AudioSource createAudioSource(MediaItem item) {
    /* final accessTokenHandler =
        Provider.of<AccessToken>(searchScreenContext.value!, listen: false); */
    return item.extras!["downloaded"] == "true"
        ? AudioSource.file(item.extras!["audio"])
        : useCacheAudioSource.value
            ? LockCachingAudioSource(
                Uri.parse(
                    "${AppConstants.SERVER_URL}play_song_caching/${kIsApple ? "" : "android/"}${item.id.split(".")[2]}"),
                /* headers: {
                  "Authorization": "${accessTokenHandler.accessToken}",
                  "Content-Type": "application/json",
                }, */
                tag: item,
              )
            : AudioSource.uri(
                Uri.parse(
                    "${AppConstants.SERVER_URL}play_song/${kIsApple ? "" : "android/"}${item.id.split(".")[2]}"),
                /*  headers: {
                  "Authorization": "${accessTokenHandler.accessToken}",
                  "Content-Type": "application/json",
                }, */
                tag: item,
              ) as AudioSource;
  }

  // Check if to show add
  void checkToShowAdd() async {
    if (!premium.value) {
      songsPlayed++;

      if (songsPlayed > 1) {
        showAdd();
        songsPlayed = 0;
      }
    }
  }

  void showAdd() async {
    await InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) async {
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

          if (interstitialAd != null) {
            await interstitialAd!.show();
          }
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('InterstitialAd failed to load: $error');
        },
      ),
    );
  }

  // Sleep mode --> Every minute turn a volume down 1% until it reaches 0% => pause the song and return volume to 100%
  void sleep(SleepAlarm sleepAlarm) async {
    if (audioPlayer.loopMode == LoopMode.off) {
      setRepeatMode(AudioServiceRepeatMode.all);
    }
    Notifications().showWarningNotification(
      notificationsContext.value!,
      AppLocalizations.of(notificationsContext.value!)!.donotterminatetheapp,
    );
    if (sleepAlarm.sleep) {
      sleepIn(sleepAlarm);
    } else if (sleepAlarm.alarmClock) {
      alarmClockFunction(sleepAlarm);
    }
  }

  void stopSleep() async {
    // Cancel previous timer if it exists and is active
    if (volumeTimer.isActive) {
      volumeTimer.cancel(); // Properly cancel the old timer
    }
    await audioPlayer.pause();
    await audioPlayer.setVolume(1);
    mutePlay = false;
  }

  void sleepIn(SleepAlarm sleepAlarm) async {
    double currentVolume = audioPlayer.volume; // Get current volume

    int totalIterations = 100; // Fixed number of iterations
    double timePerStep = (sleepAlarm.sleepDuration * 60) /
        totalIterations; // Time per iteration in seconds

    // Cancel the old timer before assigning a new one
    if (volumeTimer.isActive) {
      volumeTimer.cancel();
    }

    // Start playback (assuming this is what you want to do here)
    await audioPlayer.play();

    // Now, create and assign the new periodic timer
    volumeTimer = Timer.periodic(
      Duration(
          milliseconds: (timePerStep * 1000).toInt()), // Period for the timer
      (timer) async {
        volumeTimer = timer;

        if (audioPlayer.playing) {
          if (currentVolume == 0) {
            timer.cancel(); // Cancel the timer if volume is 0
            await audioPlayer.setVolume(0); // Mute the audio
            await audioPlayer.pause(); // Pause playback

            if (sleepAlarm.alarmClock) {
              alarmClockFunction(sleepAlarm); // Perform additional action
            } else {
              await audioPlayer.setVolume(1); // Reset volume for next play
              activeSleepAlarm = -1;
            }
          } else {
            // Adjust the volume depending on the settings
            if (sleepAlarm.sleepLinear) {
              currentVolume =
                  (currentVolume - 0.01).clamp(0.0, 1.0); // Linear decrease
            } else {
              if (currentVolume > 0.67) {
                currentVolume = (currentVolume - 0.03).clamp(0, 1.0);
              } else if (currentVolume > 0.4) {
                currentVolume = (currentVolume - 0.02).clamp(0, 1.0);
              } else {
                currentVolume = (currentVolume - 0.00533).clamp(0, 1.0);
              }
            }

            // Apply the updated volume
            await audioPlayer.setVolume(currentVolume);
          }
        }
      },
    );
  }

  void alarmClockFunction(SleepAlarm sleepAlarm) async {
    int now = DateTime.now().second +
        TimeOfDay.now().minute * 60 +
        TimeOfDay.now().hour * 3600;

    int awake = sleepAlarm.wakeTime;

    mutePlay = true; // Enable pausing for the wake person

    // Play at 0 volume so that the app does not self terminate
    await audioPlayer.pause();
    await audioPlayer.setVolume(0);
    audioPlayer.play();

    Future.delayed(
      Duration(
          seconds: awake * 60 - now - sleepAlarm.beforeEndTimeMin * 60 < 0
              ? 24 * 3600 + awake * 60 - now - sleepAlarm.beforeEndTimeMin * 60
              : awake * 60 - now - sleepAlarm.beforeEndTimeMin * 60),
      () async {
        try {
          if (activeSleepAlarm == sleepAlarm.id) {
            await audioPlayer.pause();
            mutePlay = false;
            // Set volume to zero
            audioPlayer.setVolume(0);

            // Turn up the volume on the device
            final volumeManager = Provider.of<VolumeManager>(
                notificationsContext.value!,
                listen: false);
            volumeManager.setVolume(sleepAlarmDevVolume);

            audioPlayer.play();
            double currentVolume = audioPlayer.volume; // Get current volume
            volumeTimer.cancel(); // Cancel if one runs
            volumeTimer = Timer.periodic(
              Duration(
                  milliseconds:
                      ((sleepAlarm.beforeEndTimeMin * 60 / 100) * 1000)
                          .toInt()),
              (timer) async {
                try {
                  volumeTimer = timer;
                  if (currentVolume == 1) {
                    timer.cancel();
                    activeSleepAlarm = -1;
                    mutePlay = false;
                  }

                  if (sleepAlarm.alarmClockLinear) {
                    currentVolume = (currentVolume + 0.01).clamp(0.0, 1.0);
                  } else {
                    if (currentVolume > 0.67) {
                      currentVolume = (currentVolume + 0.03).clamp(0, 1.0);
                    } else if (currentVolume > 0.4) {
                      currentVolume = (currentVolume + 0.02).clamp(0, 1.0);
                    } else {
                      currentVolume = (currentVolume + 0.00533).clamp(0, 1.0);
                    }
                  }

                  await audioPlayer
                      .setVolume(currentVolume); // Apply new volume
                } catch (e) {
                  // print("INSIDE ERROR: $e");
                }
              },
            );
          }
        } catch (e) {
          // print("ERRROR: $e");
        }
      },
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

  void listenForNewTracks() async {
    audioPlayer.positionStream.listen(
      (Duration position) async {
        if (position == audioPlayer.duration) {
          await InterstitialAd.load(
              adUnitId: adUnitId,
              request: const AdRequest(),
              adLoadCallback: InterstitialAdLoadCallback(
                // Called when an ad is successfully received.
                onAdLoaded: (ad) async {
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

                  if (interstitialAd != null) {
                    await interstitialAd!.show();
                  }
                },
                // Called when an ad request failed.
                onAdFailedToLoad: (LoadAdError error) {
                  debugPrint('InterstitialAd failed to load: $error');
                },
              ));
          /* if (interstitialAd != null) {
            await interstitialAd!.show();
          } */
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
    if (activeSleepAlarm != -1) {
      Notifications().showErrorNotification(
          notificationsContext.value!,
          AppLocalizations.of(notificationsContext.value!)!
              .unabletohaltthemusicplayer,
          AppLocalizations.of(notificationsContext.value!)!
              .unabletohaltthemusicplayerbecausesleepalarmiscurrentlyon);
    } else {
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

      volumeTimer.cancel();

      // Remove current media item
      mediaItem.value = null;

      // Init empty playlist
      audioPlayer.setAudioSource(playlist);
    }
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
    if (!mutePlay) {
      audioPlayer.play();
      startFadeIn();
    } else {
      Notifications().showWarningNotification(
          notificationsContext.value!,
          AppLocalizations.of(notificationsContext.value!)!
              .sleepalarmisenabled);
    }
  }

  // Pause function to pause playback
  @override
  Future<void> pause() async {
    if (!mutePlay) {
      await startFadeOut();
      audioPlayer.pause();
    } else {
      Notifications().showWarningNotification(
          notificationsContext.value!,
          AppLocalizations.of(notificationsContext.value!)!
              .sleepalarmisenabled);
    }
  }

  // Set volume
  Future<void> setVolume(double volume) async {
    await audioPlayer.setVolume(volume);
    this.volume = volume;
  }

  // Seek function to change the playback position
  @override
  Future<void> seek(Duration position) async =>
      premium.value ? audioPlayer.seek(position) : null;

  // Skip to a specific item in the queue and start playback
  @override
  Future<void> skipToQueueItem(int index, {bool playAuto = true}) async {
    try {
      await audioPlayer.seek(Duration.zero, index: index);
      if (playAuto) {
        play();
      }
    } catch (e) {
      //print("Erorrr; $e");
    }
  }

  // Skip to the next item in the queue
  @override
  Future<void> skipToNext() async {
    await audioPlayer.seekToNext();
    checkToShowAdd();
  }

  // Skip to the previous item in the queue
  @override
  Future<void> skipToPrevious() async {
    if (audioPlayer.position.inSeconds < 5) {
      await audioPlayer.seekToPrevious();
    } else {
      await seek(const Duration(seconds: 0));
    }
    checkToShowAdd();
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
