import 'package:pongo/exports.dart';

class TitleArtistVisualizerPhone extends StatelessWidget {
  final String name;
  final String artistJson;
  final AsyncSnapshot<PlaybackState> playbackState;
  final Function(String) showArtist;
  const TitleArtistVisualizerPhone({
    super.key,
    required this.name,
    required this.artistJson,
    required this.playbackState,
    required this.showArtist,
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
                            name,
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
                  height: 20,
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
                                showArtist(
                                  jsonEncode(jsonDecode(artistJson)[index]),
                                );
                              },
                              const TextStyle(
                                fontSize: 18.5,
                                fontWeight: FontWeight.w400,
                                color: Colors.white,
                              ),
                              edgeInsets: EdgeInsets.zero,
                            ),
                            if (index != jsonDecode(artistJson).length - 1)
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
          ),
        ],
      ),
    );
  }
}
