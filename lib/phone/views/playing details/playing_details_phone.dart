import 'package:blurhash_ffi/blurhash.dart';
import 'package:pongo/exports.dart';
import 'package:http/http.dart' as http;

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

  // Experimental visualizer
  List freqs = [50, 120, 210, 320, 400, 480];
  List<dynamic> frequencies = [];

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
        /*   final response = await http.post(
          Uri.parse("https://gogodom.ddns.net:9090/get_visualizer_data"),
        );

        if (response.statusCode == 200) {
          List<dynamic> data = jsonDecode(response.body);

          // Check if the data is not empty and contains valid frequency data
          if (data.isNotEmpty) {
            // Extract the last result and convert it to a List<double>

            // Ensure to convert each value to double explicitly
            print(freqs[0]);
            setState(() {
              frequencies = data;
            });
          }
        } else {
          throw Exception('Failed to load visualizer data');
        } */
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
        if (enableLyrics.value) {
          final lyrics = await TrackMetadata().getLyrics(
            context,
            mediaItem.title,
            mediaItem.artist!.split(', ')[0],
            mediaItem.duration!.inSeconds.toDouble(),
            mediaItem.album!,
          );
          int? syncLyrDelay = await DatabaseHelper().querySyncTimeDelay(stid!);
          int syncDelay = 0;
          if (syncLyrDelay != null) {
            syncDelay = (syncLyrDelay / 1000).toInt();
          } else if (lyrics["duration"] != null && useSyncTimeDelay.value) {
            final int difference = ((lyrics["duration"]) -
                    mediaItem.duration!.inSeconds.toDouble())
                .toInt()
                .abs();
            syncDelay = difference > 2
                ? ((lyrics["duration"]) -
                        mediaItem.duration!.inSeconds.toDouble())
                    .toInt()
                : 0;
          }

          setState(() {
            syncTimeDelay = syncDelay * 1000;
            plainLyrics = lyrics["plainLyrics"] ?? "";
            syncedLyrics = lyrics["syncedLyrics"] ?? "";
          });
        } else {
          setState(() {
            plainLyrics = "";
            syncedLyrics = "";
          });
        }
        setState(() {
          currentMediaItemId = stid;
          currentMediaItem = mediaItem;

          blurhash = blurHash;
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
                      stid: currentMediaItem!.id.split('.')[2],
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
                      syncLyrics: useSynced,
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
                      frequency: frequencies,
                      audioServiceHandler: audioServiceHandler,
                      image: currentMediaItem!.artUri.toString(),
                    ),
                    /* Positioned(
                      top: 40,
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: StreamBuilder(
                          stream: audioServiceHandler.positionStream,
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const SizedBox();
                            }
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ...freqs.asMap().entries.map((entry) {
                                  final hm = frequencies[
                                      (snapshot.data!.inMilliseconds / 200)
                                          .toInt()];
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                        left: 1, right: 1),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      curve: Curves.bounceInOut,
                                      height: hm["${entry.value}"] *
                                          1, // Height based on the frequency value
                                      width: 5,
                                      decoration: BoxDecoration(
                                          color: Colors.blue,
                                          borderRadius:
                                              BorderRadius.circular(600)),
                                    ),
                                  );
                                }),
                              ],
                            );
                          }),
                    ) */
                  ],
                )
              : const SizedBox();
        },
      ),
    );
  }
}
