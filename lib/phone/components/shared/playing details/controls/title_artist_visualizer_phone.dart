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
            width: size.width - 30,
            child: /* AnimatedAlign(
              alignment: playbackState.data != null
                  ? playbackState.data!.playing
                      ? Alignment.center
                      : Alignment.centerLeft
                  : Alignment.centerLeft,
              duration: Duration(
                  milliseconds: playbackState.data != null
                      ? !playbackState.data!.playing
                          ? 500
                          : 250
                      : 250),
              curve: playbackState.data != null
                  ? playbackState.data!.playing
                      ? Curves.easeOutSine
                      : Curves.decelerate
                  : Curves.decelerate,
              child: */
                Column(
              /* crossAxisAlignment: playbackState.data != null
                  ? playbackState.data!.playing
                      ? CrossAxisAlignment.center
                      : CrossAxisAlignment.start
                  : CrossAxisAlignment.start, */
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
                    child: marquee(
                      name,
                      const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      null,
                      null,
                    ),
                  ),
                ),
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
                    child: marquee(
                      artist,
                      const TextStyle(
                        fontSize: 18.5,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                      ),
                      null,
                      null,
                    ),
                  ),
                ),
              ],
            ),
          ),
          //  ),
          //const Expanded(child: SizedBox()),
          /* const SizedBox(
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
              ), */
        ],
      ),
    );
  }
}
