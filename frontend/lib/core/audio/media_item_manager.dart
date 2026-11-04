import 'dart:math';

import 'package:pongo/exports.dart';

class MediaItemManager with ChangeNotifier {
  final AudioServiceHandler audioServiceHandler;
  final BuildContext context;

  MediaItem? currentMediaItem;
  String? currentMediaItemId;
  String blurhash = AppConstants().BLURHASH;
  String syncedLyrics = "";
  String plainLyrics = "";
  bool lyricsOn = kIsDesktop;
  bool useSyncedLyric = true;
  bool showQueue = false;
  int syncTimeDelay = 0;
  String currentArtUri = "";
  bool lyricsExist = true;

  MediaItemManager(this.audioServiceHandler, this.context) {
    _init();
  }

  void startChangingBlurhash() {
    // Define the list of possible characters
    const allCharacters =
        "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz#%*+,-.:;=?@[]^_{|}~";

    // Create a random number generator
    Random random = Random();

    // Create a Timer that runs every second to modify the string
    Timer.periodic(const Duration(milliseconds: 5000), (timer) {
      if (blurhash.isNotEmpty && useDynamicBlurhash) {
        List<String> chars = blurhash.split('');

        // Replace at index 2
        if (blurhash.length > 2) {
          chars[2] = allCharacters[random.nextInt(allCharacters.length)];
        }

        // Replace at index 4
        if (blurhash.length > 4) {
          chars[4] = allCharacters[random.nextInt(allCharacters.length)];
        }

        // Replace at index 15
        if (blurhash.length > 15) {
          chars[15] = allCharacters[random.nextInt(allCharacters.length)];
        }

        // Join the list back into a string
        blurhash = chars.join();

        notifyListeners();
      }
    });
  }

  void _init() {
    useSyncedLyric = useSyncedLyrics.value;
    startChangingBlurhash();
    audioServiceHandler.mediaItem.listen((mediaItem) {
      _onMediaItemChanged(mediaItem);
    });
  }

  Future<void> _onMediaItemChanged(MediaItem? mediaItem) async {
    if (mediaItem == null) return;
    if (mediaItem.id.split('.')[2] == currentMediaItemId) return;

    currentMediaItemId = mediaItem.id.split(".")[2];
    currentStid.value = currentMediaItemId!;
    currentMediaItem = mediaItem;
    notifyListeners();

    // Blurhash
    try {
      if (mediaItem.artUri.toString() != currentArtUri) {
        currentArtUri = mediaItem.artUri.toString();
        notifyListeners();

        blurhash = mediaItem.artUri != null && mediaItem.artUri != Uri.parse("")
            ? await BlurhashFFI.encode(
                currentMediaItem!.artUri.toString().contains("file:///")
                    ? FileImage(File(currentMediaItem!.artUri!.toFilePath()))
                    : NetworkImage(currentMediaItem!.artUri.toString()),
                componentX: detailedBlurhash.value ? 3 : 2,
                componentY: detailedBlurhash.value ? 3 : 2)
            : AppConstants().BLURHASH;
        currentBlurhash.value = blurhash;
        notifyListeners();
      }
    } catch (e) {
      // print(e);
    }
    // Add to track history
    if (mediaItem.id.split(".")[1] != "mix" &&
        mediaItem.id.split(".")[2].length > 21) {
      await DatabaseHelper().insertLFHTracks(mediaItem.id.split(".")[2]);
    }

    // Fetch lyrics and update blurhash asynchronously.
    try {
      bool connected = true;
      if (kIsMobile) {
        final internetConnectivityHandler =
            Provider.of<InternetConnectivityHandler>(context, listen: false);
        connected = internetConnectivityHandler.isConnected;
      }
      if (enableLyrics.value && connected) {
        final lyrics = await TrackMetadata().getLyrics(
          context,
          mediaItem.title,
          mediaItem.artist ?? "",
          mediaItem.duration?.inSeconds.toDouble() ?? 0,
          mediaItem.album ?? "",
        );

        int? syncDelayDb =
            await DatabaseHelper().querySyncTimeDelay(currentMediaItemId!);
        syncTimeDelay = syncDelayDb ?? 0;

        plainLyrics = lyrics["plainLyrics"] ?? "";
        syncedLyrics = lyrics["syncedLyrics"] ?? "";
        lyricsExist = plainLyrics != "" && syncedLyrics != "";
      } else {
        plainLyrics = "";
        syncedLyrics = "";
        lyricsExist = false;
      }
    } catch (e) {
      plainLyrics = "";
      syncedLyrics = "";
      // print(e);
    }

    notifyListeners();
  }

  toggleLyricsOn() {
    lyricsOn = !lyricsOn;

    if (!lyricsExist) {
      Notifications().showNotification(
          context: context,
          title: AppLocalizations.of(context).nolyricsavailable,
          message: AppLocalizations.of(context).wanttohelpoutlyrics,
          icon: AppIcons.lyrics);
    }
    notifyListeners();
  }

  toggleUseSyncedLyrics() {
    useSyncedLyric = !useSyncedLyric;
    notifyListeners();
  }

  toggleShowQueue() {
    showQueue = !showQueue;
    notifyListeners();
  }

  resetSyncTimeDelay() {
    syncTimeDelay = 0;
    notifyListeners();
  }

  increaseSyncTimeDelay() {
    syncTimeDelay += 250;
    notifyListeners();
  }

  decreaseSyncTimeDelay() {
    syncTimeDelay -= 250;
    notifyListeners();
  }
}
