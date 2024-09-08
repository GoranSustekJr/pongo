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

  @override
  Widget build(BuildContext context) {
    final audioServiceHandler =
        Provider.of<AudioHandler>(context) as AudioServiceHandler;

    // Function to update the current media item safely
    void newMediaItem(String? stid, MediaItem? mediaItem) {
      // Only update if the new media item is different
      if (currentMediaItemId != stid) {
        setState(() {
          currentMediaItemId = stid;
          currentMediaItem = mediaItem;
        });
      }
    }

    return SizedBox(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
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
            duration: const Duration(milliseconds: 350),
            child: currentMediaItem != null
                ? Blurhash(
                    key: ValueKey(currentMediaItemId),
                    blurhash: currentMediaItem!.artHeaders?["blurhash"] ??
                        AppConstants().BLURHASH,
                    sigmaX: 0,
                    sigmaY: 0,
                    child: Stack(
                      children: [
                        TrackControlsPhone(
                          currentMediaItem: currentMediaItem!,
                          lyricsOn: false,
                        ),
                        TrackImagePhone(
                          lyricsOn: false,
                          image: currentMediaItem!.artUri.toString(),
                        ),
                      ],
                    ),
                  )
                : const SizedBox(), // Empty placeholder when no media item is available
          );
        },
      ),
    );
  }
}
