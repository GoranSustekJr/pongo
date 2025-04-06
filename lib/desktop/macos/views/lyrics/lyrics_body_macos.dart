import 'package:flutter/cupertino.dart';
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
  final Size size;
  const LyricsBodyMacos({
    super.key,
    required this.mediaItem,
    required this.audioServiceHandler,
    required this.artistJson,
    required this.mediaItemManager,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            width: (size.width - 200) / 2,
            height: size.height - 60,
            child: Column(
              children: [
                SizedBox(
                  height: size.height > 685
                      ? (size.height - 60) - 190 < (size.width - 200) / 2
                          ? (size.height - 60) - 190
                          : null
                      : (size.height - 60) - 130 < (size.width - 200) / 2
                          ? (size.height - 60) - 130
                          : null,
                  child: TrackImageDesktop(
                    lyricsOn: false,
                    fullscreenPlay: false,
                    image: mediaItem.artUri.toString(),
                    stid: currentStid.value,
                    audioServiceHandler: audioServiceHandler,
                  ),
                ),
                Expanded(child: Container()),
                StreamBuilder(
                    key: ValueKey(mediaItem.id),
                    stream: audioServiceHandler.playbackState,
                    builder: (context, playbackState) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 5),
                        child: Stack(
                          children: [
                            Column(
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
                                    child: SingleChildScrollView(
                                      scrollDirection:
                                          Axis.horizontal, // Prevents wrapping
                                      child: Row(
                                        children: List.generate(
                                          jsonDecode(artistJson).length,
                                          (index) {
                                            var artist =
                                                jsonDecode(artistJson)[index];
                                            return CupertinoButton(
                                              padding: EdgeInsets.zero,
                                              onPressed: () async {
                                                Map artistData =
                                                    await ArtistSpotify()
                                                        .getImage(context,
                                                            artist["id"]);
                                                showMacosSheet(
                                                  context: context,
                                                  builder: (_) => ArtistPhone(
                                                    artist: Artist(
                                                      id: artist["id"],
                                                      name: artist["name"],
                                                      image:
                                                          calculateBestImageForTrack(
                                                        (artistData["images"]
                                                                as List<
                                                                    dynamic>)
                                                            .map((image) =>
                                                                AlbumImagesTrack(
                                                                  url: image[
                                                                      "url"],
                                                                  height: image[
                                                                      "height"],
                                                                  width: image[
                                                                      "width"],
                                                                ))
                                                            .toList(),
                                                      ),
                                                    ),
                                                    context: context,
                                                  ),
                                                );
                                              },
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    artist["name"],
                                                    style: const TextStyle(
                                                      fontSize: 18.5,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  if (index !=
                                                      jsonDecode(artistJson)
                                                              .length -
                                                          1)
                                                    const Text(
                                                      ", ",
                                                      style: TextStyle(
                                                        fontSize: 18.5,
                                                        fontWeight:
                                                            FontWeight.w400,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Positioned(
                              left: 0,
                              top: 0,
                              child: Tooltip(
                                message:
                                    AppLocalizations.of(context).fullscreen,
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(60),
                                      boxShadow: [
                                        BoxShadow(
                                            color: Colors.black.withAlpha(200),
                                            spreadRadius: 3,
                                            blurRadius: 10),
                                      ]),
                                  child: iconButton(
                                      CupertinoIcons.fullscreen, Colors.white,
                                      () {
                                    fullscreenPlaying.value = true;
                                  }, edgeInsets: EdgeInsets.zero),
                                ),
                              ),
                            )
                          ],
                        ),
                      );
                    }),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: DesktopTrackProgress(
                    fullscreen: false,
                    album: mediaItem.album!,
                    duration: mediaItem.duration,
                    showAlbum: (_) async {
                      if (mediaItem.album != null) {
                        Map album = await AlbumSpotify().getData(
                            context, mediaItem.album!.split("..Ææ..")[0]);

                        showMacosSheet(
                            context: context,
                            builder: (_) => AlbumPhone(
                                album: Album(
                                    id: album["id"],
                                    name: album["name"],
                                    type: album["album_type"],
                                    artists: album["artists"].map((artist) {
                                      return artist[
                                          "name"]; //{artist["id"]: artist["name"]};
                                    }).toList(),
                                    image: calculateWantedResolution(
                                        album["images"], 300, 300)),
                                context: context));
                      }
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
        ),
        Flexible(
          child: SizedBox(
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
                  fullscreenPlaying: false,
                  onChangeUseSyncedLyrics:
                      mediaItemManager.toggleUseSyncedLyrics,
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
        ),
      ],
    );
  }
}
