import 'package:pongo/exports.dart';
import 'package:pongo/shared/utils/managers/media_item_manager.dart';

class PlayingDetailsPhone extends StatelessWidget {
  final Function(String) showAlbum;

  PlayingDetailsPhone({super.key, required this.showAlbum});
  final GlobalKey<State<QueuePhone>> queueKey = GlobalKey<State<QueuePhone>>();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MediaItemManager(
        Provider.of<AudioHandler>(context, listen: false)
            as AudioServiceHandler,
        context,
      ),
      child: Consumer<MediaItemManager>(
        builder: (context, mediaItemManager, child) {
          return mediaItemManager.currentMediaItem != null
              ? Stack(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      switchInCurve: Curves.fastOutSlowIn,
                      switchOutCurve: Curves.fastEaseInToSlowEaseOut,
                      child: Blurhash(
                        key: ValueKey(
                            "${mediaItemManager.blurhash}${mediaItemManager.currentMediaItemId}"),
                        blurhash: mediaItemManager.blurhash,
                        sigmaX: 10,
                        sigmaY: 10,
                        child: Container(),
                      ),
                    ),
                    Container(
                      color: Colors.black.withAlpha(45),
                    ),
                    LyricsPhone(
                      plainLyrics: mediaItemManager.plainLyrics.split('\n'),
                      syncedLyrics: [
                        ...mediaItemManager.syncedLyrics.split('\n'),
                      ],
                      lyricsOn: mediaItemManager.lyricsOn,
                      useSyncedLyrics: mediaItemManager.useSyncedLyric,
                      syncTimeDelay: mediaItemManager.syncTimeDelay,
                    ),
                    QueuePhone(
                      key: queueKey,
                      showQueue: mediaItemManager.showQueue,
                      lyricsOn: mediaItemManager.lyricsOn,
                      changeShowQueue: mediaItemManager.toggleShowQueue,
                      changeLyricsOn: mediaItemManager.toggleLyricsOn,
                    ),
                    LyricsButtonPhone(
                      stid: mediaItemManager.currentMediaItem!.id.split('.')[2],
                      syncTimeDelay: mediaItemManager.syncTimeDelay,
                      lyricsOn: mediaItemManager.lyricsOn,
                      useSynced: mediaItemManager.useSyncedLyric,
                      changeLyricsOn: mediaItemManager.toggleLyricsOn,
                      changeUseSynced: mediaItemManager.toggleUseSyncedLyrics,
                      resetSyncTimeDelay: mediaItemManager.resetSyncTimeDelay,
                      plus: mediaItemManager.increaseSyncTimeDelay,
                      minus: mediaItemManager.decreaseSyncTimeDelay,
                    ),
                    TrackControlsPhone(
                      currentMediaItem: mediaItemManager.currentMediaItem!,
                      lyricsOn: mediaItemManager.lyricsOn,
                      showQueue: mediaItemManager.showQueue,
                      syncLyrics: mediaItemManager.useSyncedLyric,
                      changeLyricsOn: mediaItemManager.toggleLyricsOn,
                      changeShowQueue: mediaItemManager.toggleShowQueue,
                      showAlbum: showAlbum,
                    ),
                    TrackImagePhone(
                      lyricsOn: mediaItemManager.lyricsOn,
                      showQueue: mediaItemManager.showQueue,
                      audioServiceHandler: mediaItemManager.audioServiceHandler,
                      image:
                          mediaItemManager.currentMediaItem!.artUri.toString(),
                    ),
                  ],
                )
              : const SizedBox();
        },
      ),
    );
  }
}
