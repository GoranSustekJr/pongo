import 'package:blurhash_ffi/blurhash.dart';
import 'package:pongo/exports.dart';

class PlayingDetailsPhone extends StatefulWidget {
  final Function(String) showAlbum;
  const PlayingDetailsPhone({
    super.key,
    required this.showAlbum,
  });

  @override
  State<PlayingDetailsPhone> createState() => _PlayingDetailsPhoneState();
}

class _PlayingDetailsPhoneState extends State<PlayingDetailsPhone> {
  // Current media item
  MediaItem? currentMediaItem;

  // Current item id
  String? currentMediaItemId;

  // Sync lyrics manually
  int syncTimeDelay = 0;

  // Show lyrics
  bool lyricsOn = false;

  // Use Synced
  bool useSynced = false;

  // Show current song details | show queue
  bool showQueue = false;

  // Queue state key
  final GlobalKey<State<QueuePhone>> queueKey = GlobalKey<State<QueuePhone>>();

  // Blurhash
  String blurhash = AppConstants().BLURHASH;

  // Lyrics
  String syncedLyrics = "";
  String plainLyrics = "";

  // Volume controller
  InteractiveSliderController volumeController =
      InteractiveSliderController(VolumeManager().currentVolume);

  // Volume icon
  int iconKey = 0;

  @override
  void initState() {
    super.initState();
    useSynced = useSyncedLyrics.value;
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    final audioServiceHandler =
        Provider.of<AudioHandler>(context) as AudioServiceHandler;

    // Function to update the current media item safely
    void newMediaItem(String? stid, MediaItem? mediaItem) async {
      if (currentMediaItemId != stid) {
        final String blurHash = mediaItem!.artUri != null
            ? await BlurhashFFI.encode(
                NetworkImage(
                  mediaItem.artUri.toString(),
                ),
                componentX: 3,
                componentY: 3,
              )
            : AppConstants().BLURHASH;

        currentBlurhash.value = blurHash;
        final lyrics = await TrackMetadata().getLyrics(
          context,
          mediaItem.title,
          mediaItem.artist!.split(', ')[0],
          mediaItem.duration!.inSeconds.toDouble(),
          mediaItem.album!,
        );
        int syncDelay = 0;
        if (lyrics["duration"] != null && useSyncTimeDelay.value) {
          final int difference =
              ((lyrics["duration"]) - mediaItem.duration!.inSeconds.toDouble())
                  .toInt()
                  .abs();
          syncDelay = difference > 2
              ? ((lyrics["duration"]) -
                      mediaItem.duration!.inSeconds.toDouble())
                  .toInt()
              : 0;
        }

        setState(() {
          currentMediaItemId = stid;
          currentMediaItem = mediaItem;
          syncTimeDelay = syncDelay * 1000;
          blurhash = blurHash;
          plainLyrics = lyrics["plainLyrics"] ?? "";
          syncedLyrics = lyrics["syncedLyrics"] ?? "";
        });
      }
    }

    return Container(
      color: Colors.black,
      height: size.height,
      width: size.width,
      child: StreamBuilder<MediaItem?>(
        stream: audioServiceHandler.mediaItem.stream,
        builder: (context, snapshot) {
          // Check if data is available and if the media item has changed
          if (snapshot.hasData && snapshot.data != null) {
            String newId = snapshot.data!.id.split(".")[2];

            // Update the media item safely outside the build process
            WidgetsBinding.instance.addPostFrameCallback((_) {
              newMediaItem(newId, snapshot.data);
            });
          }

          return currentMediaItem != null
              ? Stack(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      switchInCurve: Curves.fastOutSlowIn,
                      switchOutCurve: Curves.fastEaseInToSlowEaseOut,
                      child: Blurhash(
                        key: ValueKey(currentMediaItemId),
                        blurhash: blurhash,
                        sigmaX: 10,
                        sigmaY: 10,
                        child: Container(),
                      ),
                    ),
                    Container(
                      color: Colors.black.withAlpha(45),
                    ),
                    LyricsPhone(
                      plainLyrics: plainLyrics.split('\n'),
                      syncedLyrics: [
                        ...syncedLyrics.split('\n'),
                      ],
                      lyricsOn: lyricsOn,
                      useSyncedLyrics: useSynced,
                      syncTimeDelay: syncTimeDelay,
                    ),
                    QueuePhone(
                      key: queueKey,
                      showQueue: showQueue,
                      lyricsOn: lyricsOn,
                      changeShowQueue: () {
                        setState(() {
                          showQueue = !showQueue;
                        });
                      },
                      changeLyricsOn: () {
                        setState(() {
                          lyricsOn = !lyricsOn;
                        });
                      },
                    ),
                    LyricsButtonPhone(
                      syncTimeDelay: syncTimeDelay,
                      lyricsOn: lyricsOn,
                      useSynced: useSynced,
                      changeLyricsOn: () {
                        setState(() {
                          lyricsOn = !lyricsOn;
                        });
                      },
                      changeUseSynced: () {
                        setState(() {
                          useSynced = !useSynced;
                        });
                      },
                      resetSyncTimeDelay: () {
                        setState(() {
                          syncTimeDelay = 0;
                        });
                      },
                      plus: () {
                        setState(() {
                          syncTimeDelay += 250;
                        });
                      },
                      minus: () {
                        setState(() {
                          syncTimeDelay -= 250;
                        });
                      },
                    ),
                    TrackControlsPhone(
                      currentMediaItem: currentMediaItem!,
                      lyricsOn: lyricsOn,
                      showQueue: showQueue,
                      changeLyricsOn: () {
                        setState(() {
                          lyricsOn = !lyricsOn;
                        });
                      },
                      changeShowQueue: () {
                        setState(() {
                          showQueue = !showQueue;
                        });
                      },
                      showAlbum: widget.showAlbum,
                    ),
                    TrackImagePhone(
                      lyricsOn: lyricsOn,
                      showQueue: showQueue,
                      audioServiceHandler: audioServiceHandler,
                      image: currentMediaItem!.artUri.toString(),
                    ),
                  ],
                )
              : const SizedBox();
        },
      ),
    );
  }
}
