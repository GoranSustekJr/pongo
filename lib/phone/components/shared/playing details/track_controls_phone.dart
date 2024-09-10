import 'dart:ui';
import 'controls.dart';

class TrackControlsPhone extends StatelessWidget {
  final MediaItem currentMediaItem;
  final bool lyricsOn;
  final Function() changeLyricsOn;
  const TrackControlsPhone({
    super.key,
    required this.currentMediaItem,
    required this.lyricsOn,
    required this.changeLyricsOn,
  });

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    final audioServiceHandler =
        Provider.of<AudioHandler>(context) as AudioServiceHandler;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 750),
      curve: Curves.decelerate,
      bottom: lyricsOn
          ? -50
          : (size.height -
                  (size.width - 60) -
                  380 -
                  MediaQuery.of(context).padding.top) /
              2,
      child: SizedBox(
        width: size.width,
        height: 330,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 7.5, sigmaY: 7.5),
            blendMode: BlendMode.src,
            child: Padding(
              padding: const EdgeInsets.only(
                left: 15,
                right: 15,
                top: 10,
              ),
              child: StreamBuilder(
                  stream: audioServiceHandler.playbackState,
                  builder: (context, playbackState) {
                    return Column(
                      children: [
                        TitleArtistVisualizerPhone(
                          name: currentMediaItem.title,
                          artist: currentMediaItem.artist!,
                          playbackState: playbackState,
                        ),
                        TrackProgressPhone(
                          album: currentMediaItem.album!,
                          released: currentMediaItem.extras!["released"]!,
                          duration: currentMediaItem.duration,
                        ),
                        PlayControlPhone(
                          mediaItem: currentMediaItem,
                          playbackState: playbackState,
                          onTap: (_) {},
                        ),
                        const VolumeControlPhone(),
                        OtherControlsPhone(
                          lyricsOn: lyricsOn,
                          trackId: currentMediaItem.id,
                          downloadTrack: () {},
                          changeLyricsOn: changeLyricsOn,
                        ),
                      ],
                    );
                  }),
            ),
          ),
        ),
      ),
    );
  }
}
