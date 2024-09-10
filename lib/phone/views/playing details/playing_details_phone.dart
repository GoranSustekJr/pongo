import 'package:pongo/exports.dart';
import 'package:pongo/phone/components/shared/playing%20details/track_controls_phone.dart';
import 'package:pongo/phone/components/shared/playing%20details/track_image_phone.dart';

class PlayingDetailsPhone extends StatefulWidget {
  const PlayingDetailsPhone({super.key});

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
  bool useSynced = true;

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    final audioServiceHandler =
        Provider.of<AudioHandler>(context) as AudioServiceHandler;

    // Function to update the current media item safely
    void newMediaItem(String? stid, MediaItem? mediaItem) {
      // Only update if the new media item is different
      if (currentMediaItemId != stid) {
        setState(() {
          currentMediaItemId = stid;
          currentMediaItem = mediaItem;
          if (mediaItem != null) {
            // TODO: Add this as an option in settings
            syncTimeDelay =
                int.parse(mediaItem.extras!["syncTimeDelay"]!) * 1000;
          }
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

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 750),
            switchInCurve: Curves.fastOutSlowIn,
            switchOutCurve: Curves.fastEaseInToSlowEaseOut,
            child: currentMediaItem != null
                ? Blurhash(
                    key: ValueKey(currentMediaItemId),
                    blurhash: currentMediaItem!.extras?["blurhash"] ??
                        AppConstants().BLURHASH,
                    sigmaX: 10,
                    sigmaY: 10,
                    child: Container(
                      color: Colors.black.withAlpha(45),
                      child: Stack(
                        children: [
                          LyricsPhone(
                            plainLyrics: currentMediaItem!
                                .extras!["plainLyrics"]!
                                .split('\n'),
                            syncedLyrics: [
                              ...["{#¶€[”„’‘¤ß÷×¤ß#˘¸}"],
                              ...currentMediaItem!.extras!["syncedLyrics"]!
                                  .split('\n')
                            ],
                            lyricsOn: lyricsOn,
                            useSyncedLyrics: useSynced,
                            syncTimeDelay: syncTimeDelay,
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
                            changeLyricsOn: () {
                              setState(() {
                                lyricsOn = !lyricsOn;
                              });
                            },
                          ),
                          TrackImagePhone(
                            lyricsOn: lyricsOn,
                            image: currentMediaItem!.artUri.toString(),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox(),
          );
        },
      ),
    );
  }
}
