import 'package:blurhash_ffi/blurhash.dart';
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
    if (mediaItem == null || mediaItem.id == currentMediaItemId) return;

    currentMediaItemId = mediaItem.id.split(".")[2];
    currentMediaItem = mediaItem;

    // Fetch lyrics and update blurhash asynchronously.
    if (enableLyrics.value) {
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

    blurhash = mediaItem.artUri != null
        ? await BlurhashFFI.encode(NetworkImage(mediaItem.artUri.toString()),
            componentX: 3, componentY: 3)
        : AppConstants().BLURHASH;
    currentBlurhash.value = blurhash;

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
