import 'package:pongo/exports.dart';

class MediaItemManager with ChangeNotifier {
  final AudioServiceHandler audioServiceHandler;
  final BuildContext context;

  MediaItem? currentMediaItem;
  String? currentMediaItemId;
  String blurhash = AppConstants().BLURHASH;
  String syncedLyrics = "";
  String plainLyrics = "";
  bool lyricsOn = false;
  bool useSyncedLyric = true;
  bool showQueue = false;
  int syncTimeDelay = 0;

  MediaItemManager(this.audioServiceHandler, this.context) {
    _init();
  }

  void _init() {
    useSyncedLyric = useSyncedLyrics.value;
    audioServiceHandler.mediaItem.listen((mediaItem) {
      _onMediaItemChanged(mediaItem);
    });
  }

  Future<void> _onMediaItemChanged(MediaItem? mediaItem) async {
    if (mediaItem == null) return;
    print("Mediaitem; $mediaItem");
    if (mediaItem.id.split('.')[2] == currentMediaItemId) return;

    currentMediaItemId = mediaItem.id.split(".")[2];
    currentMediaItem = mediaItem;

    // Blurhash
    try {
      blurhash = mediaItem.artUri != null
          ? await BlurhashFFI.encode(
              currentMediaItem!.artUri.toString().contains("file:///")
                  ? FileImage(File(currentMediaItem!.artUri!.toFilePath()))
                  : NetworkImage(currentMediaItem!.artUri.toString()),
              componentX: 3,
              componentY: 3)
          : AppConstants().BLURHASH;
      currentBlurhash.value = blurhash;
    } catch (e) {
      print(e);
    }
    // Add to track history
    await DatabaseHelper().insertLFHTracks(mediaItem.id.split(".")[2]);

    final internetConnectivityHandler =
        Provider.of<InternetConnectivityHandler>(context, listen: false);

    // Fetch lyrics and update blurhash asynchronously.
    try {
      if (enableLyrics.value && internetConnectivityHandler.isConnected) {
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
      } else {
        plainLyrics = "";
        syncedLyrics = "";
      }
    } catch (e) {
      plainLyrics = "";
      syncedLyrics = "";
      print(e);
    }

    notifyListeners();
  }

  toggleLyricsOn() {
    lyricsOn = !lyricsOn;
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
