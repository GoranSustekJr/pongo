import 'package:pongo/exports.dart';

class TitleArtistVisualizerPhone extends StatelessWidget {
  final String name;
  final String artist;
  final AsyncSnapshot<PlaybackState> playbackState;
  const TitleArtistVisualizerPhone({
    super.key,
    required this.name,
    required this.artist,
    required this.playbackState,
  });

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return SizedBox(
      width: size.width,
      child: Row(
        children: [
          SizedBox(
            width: size.width - 70,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                marquee(
                  name,
                  const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  null,
                  null,
                ),
                marquee(
                  artist,
                  const TextStyle(
                    fontSize: 18.5,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                  ),
                  null,
                  null,
                ),
              ],
            ),
          ),
          const Expanded(child: SizedBox()),
          const SizedBox(
              height: 45,
              width: 30,
              child:
                  SizedBox() /*  MiniMusicVisualizer(
              animate: playbackState.data != null
                  ? playbackState.data!.playing
                  : false,
              radius: 60,
              width: 7.5,
              height: 45,
              color: Colors.white,

              // shadows: [BoxShadow(blurRadius: 50)],
            ), */
              ),
        ],
      ),
    );
  }
}
