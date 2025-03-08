import 'package:pongo/exports.dart';

class PlayingDetailsPhone extends StatelessWidget {
  final Function(String) showAlbum;
  final Function(String) showArtist;
  const PlayingDetailsPhone(
      {super.key, required this.showAlbum, required this.showArtist});

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return ChangeNotifierProvider(
      create: (_) => MediaItemManager(
        Provider.of<AudioHandler>(context, listen: false)
            as AudioServiceHandler,
        context,
      ),
      child: Consumer<MediaItemManager>(
        builder: (context, mediaItemManager, child) {
          return mediaItemManager.currentMediaItem != null
              ? ValueListenableBuilder(
                  valueListenable: currentTrackHeight,
                  builder: (context, index, child) {
                    return AnimatedSwitcher(
                      key: ValueKey(currentTrackHeight),
                      duration: const Duration(milliseconds: 250),
                      child: currentTrackHeight.value != 0
                          ? Stack(
                              key: const ValueKey(true),
                              children: [
                                Container(
                                  color: Colors.black,
                                ),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 500),
                                  switchInCurve: Curves.fastOutSlowIn,
                                  switchOutCurve:
                                      Curves.fastEaseInToSlowEaseOut,
                                  child: BlurHashh(
                                    key: ValueKey(
                                        "${mediaItemManager.blurhash}${mediaItemManager.currentMediaItemId}"),
                                    hash: mediaItemManager.blurhash,
                                  ),
                                ),
                                Container(
                                  color: Colors.black.withAlpha(65),
                                ),
                                LyricsPhone(
                                  plainLyrics:
                                      mediaItemManager.plainLyrics.split('\n'),
                                  syncedLyrics: [
                                    ...mediaItemManager.syncedLyrics
                                        .split('\n'),
                                  ],
                                  lyricsOn: mediaItemManager.lyricsOn,
                                  useSyncedLyrics:
                                      mediaItemManager.useSyncedLyric,
                                  syncTimeDelay: mediaItemManager.syncTimeDelay,
                                ),
                                if (!mediaItemManager.lyricsOn)
                                  SizedBox(
                                    height: size.height,
                                    width: size.width,
                                    child: const Text(""),
                                  ),
                                QueuePhone(
                                  //  key: queueKey,
                                  showQueue: mediaItemManager.showQueue,
                                  lyricsOn: mediaItemManager.lyricsOn,
                                  changeShowQueue:
                                      mediaItemManager.toggleShowQueue,
                                  changeLyricsOn:
                                      mediaItemManager.toggleLyricsOn,
                                ),
                                LyricsButtonPhone(
                                  stid: mediaItemManager.currentMediaItem!.id
                                      .split('.')[2],
                                  syncTimeDelay: mediaItemManager.syncTimeDelay,
                                  lyricsOn: mediaItemManager.lyricsOn,
                                  useSynced: mediaItemManager.useSyncedLyric,
                                  changeLyricsOn:
                                      mediaItemManager.toggleLyricsOn,
                                  changeUseSynced:
                                      mediaItemManager.toggleUseSyncedLyrics,
                                  resetSyncTimeDelay:
                                      mediaItemManager.resetSyncTimeDelay,
                                  plus: mediaItemManager.increaseSyncTimeDelay,
                                  minus: mediaItemManager.decreaseSyncTimeDelay,
                                ),
                                TrackControlsPhone(
                                  currentMediaItem:
                                      mediaItemManager.currentMediaItem!,
                                  lyricsOn: mediaItemManager.lyricsOn,
                                  showQueue: mediaItemManager.showQueue,
                                  syncLyrics: mediaItemManager.useSyncedLyric,
                                  changeLyricsOn:
                                      mediaItemManager.toggleLyricsOn,
                                  changeShowQueue:
                                      mediaItemManager.toggleShowQueue,
                                  showAlbum: showAlbum,
                                  showArtist: showArtist,
                                ),
                                TrackImagePhone(
                                  lyricsOn: mediaItemManager.lyricsOn,
                                  showQueue: mediaItemManager.showQueue,
                                  audioServiceHandler:
                                      mediaItemManager.audioServiceHandler,
                                  image: mediaItemManager
                                      .currentMediaItem!.artUri
                                      .toString(),
                                ),
                              ],
                            )
                          : Container(
                              key: const ValueKey(false),
                              color: Colors.transparent,
                            ),
                    );
                  })
              : const SizedBox();
        },
      ),
    );
  }
}
