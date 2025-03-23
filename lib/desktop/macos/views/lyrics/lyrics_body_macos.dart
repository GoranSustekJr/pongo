import 'package:pongo/desktop/macos/views/lyrics/lyrics_desktop.dart';
import 'package:pongo/desktop/macos/views/lyrics/play_control_desktop.dart';
import 'package:pongo/desktop/macos/views/lyrics/track_progress_desktop.dart';
import 'package:pongo/exports.dart';
import 'package:pongo/shared/widgets/ui/image/image_desktop.dart';

class LyricsBodyMacos extends StatelessWidget {
  final MediaItemManager mediaItemManager;
  final MediaItem mediaItem;
  final AudioServiceHandler audioServiceHandler;
  final String artistJson;
  const LyricsBodyMacos({
    super.key,
    required this.mediaItem,
    required this.audioServiceHandler,
    required this.artistJson,
    required this.mediaItemManager,
  });

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Row(
      children: [
        SizedBox(
          width: (size.width - 200) / 2,
          height: size.height - 60,
          child: Column(
            children: [
              TrackImageDesktop(
                lyricsOn: false,
                image: mediaItem.artUri.toString(),
                stid: currentStid.value,
                audioServiceHandler: audioServiceHandler,
              ),
              Expanded(child: Container()),
              StreamBuilder(
                  key: ValueKey(mediaItem.id),
                  stream: audioServiceHandler.playbackState,
                  builder: (context, playbackState) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 5),
                      child: Column(
                        children: [
                          SizedBox(
                            width: size.width - 30,
                            child: AnimatedAlign(
                              alignment: playbackState.data != null
                                  ? playbackState.data!.playing
                                      ? Alignment.center
                                      : Alignment.centerLeft
                                  : Alignment.centerLeft,
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.fastEaseInToSlowEaseOut,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    Text(
                                      mediaItem.title,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: size.width - 30,
                            height: 22,
                            child: AnimatedAlign(
                              alignment: playbackState.data != null
                                  ? playbackState.data!.playing
                                      ? Alignment.center
                                      : Alignment.centerLeft
                                  : Alignment.centerLeft,
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.fastEaseInToSlowEaseOut,
                              child: ListView.builder(
                                shrinkWrap: true,
                                scrollDirection: Axis.horizontal,
                                itemCount: jsonDecode(artistJson).length,
                                itemBuilder: (context, index) {
                                  return Row(
                                    children: [
                                      textButton(
                                        jsonDecode(artistJson)[index]["name"],
                                        () {
                                          /* showArtist(
                                            jsonEncode(
                                                jsonDecode(artistJson)[index]),
                                          ); */
                                          // TODO: SHow artist
                                        },
                                        const TextStyle(
                                          fontSize: 18.5,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.white,
                                        ),
                                        edgeInsets: EdgeInsets.zero,
                                      ),
                                      if (index !=
                                          jsonDecode(artistJson).length - 1)
                                        const Text(
                                          ", ",
                                          style: TextStyle(
                                            fontSize: 18.5,
                                            fontWeight: FontWeight.w400,
                                            color: Colors.white,
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: DesktopTrackProgress(
                  album: mediaItem.album!,
                  duration: mediaItem.duration,
                  showAlbum: (_) {
                    //TODO: Show album
                  },
                ),
              ),
              if (size.height >= 685)
                StreamBuilder(
                    stream: audioServiceHandler.playbackState,
                    builder: (context, playbackState) {
                      return PlayControl(
                        mediaItem: mediaItem,
                        onTap: (_) {},
                        thisTrackPlaying:
                            currentStid.value == mediaItem.id.split('.')[2],
                        playbackState: playbackState,
                      );
                    }),
              Expanded(child: Container()),
            ],
          ),
        ),
        SizedBox(
          width: (size.width - 200) / 2,
          height: size.height - 60,
          child: Column(
            children: [
              LyricsDesktop(
                plainLyrics: mediaItemManager.plainLyrics.split('\n'),
                syncedLyrics: [
                  ...mediaItemManager.syncedLyrics.split('\n'),
                ],
                lyricsOn: mediaItemManager.lyricsOn,
                useSyncedLyrics: mediaItemManager.useSyncedLyric,
                syncTimeDelay: mediaItemManager.syncTimeDelay,
                stid: mediaItem.id.split('.')[2],
                onChangeUseSyncedLyrics: mediaItemManager.toggleUseSyncedLyrics,
                plus: mediaItemManager.increaseSyncTimeDelay,
                minus: mediaItemManager.decreaseSyncTimeDelay,
                resetSyncTimeDelay: mediaItemManager.resetSyncTimeDelay,
              ),
              if (size.height < 685)
                StreamBuilder(
                    stream: audioServiceHandler.playbackState,
                    builder: (context, playbackState) {
                      return PlayControl(
                        mediaItem: mediaItem,
                        onTap: (_) {},
                        thisTrackPlaying:
                            currentStid.value == mediaItem.id.split('.')[2],
                        playbackState: playbackState,
                      );
                    }),
            ],
          ),
        ),
      ],
    );
  }
}
