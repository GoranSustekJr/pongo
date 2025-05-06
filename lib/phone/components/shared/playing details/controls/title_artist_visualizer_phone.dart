import 'package:flutter/cupertino.dart';
import 'package:pongo/exports.dart';
import 'package:pongo/shared/utils/API%20requests/shazam.dart';

class TitleArtistVisualizerPhone extends StatelessWidget {
  final String name;
  final String stid;
  final String artistJson;
  final bool smallImage;
  final AsyncSnapshot<PlaybackState> playbackState;
  final bool mix;
  final Function(String) showArtist;
  const TitleArtistVisualizerPhone({
    super.key,
    required this.name,
    required this.artistJson,
    required this.playbackState,
    required this.mix,
    required this.stid,
    required this.showArtist,
    required this.smallImage,
  });

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return SizedBox(
      width: size.width,
      child: Stack(
        children: [
          Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                width: smallImage ? 60 : 0,
              ),
              Expanded(
                child: Column(
                  children: [
                    SizedBox(
                      width: size.width - 30,
                      child: AnimatedAlign(
                        alignment: playbackState.data != null && !smallImage
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
                      height: 22,
                      child: AnimatedAlign(
                        alignment: playbackState.data != null && !smallImage
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
                                CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: () {
                                    showArtist(
                                      jsonEncode(jsonDecode(artistJson)[index]),
                                    );
                                  },
                                  child: Text(
                                    jsonDecode(artistJson)[index]["name"],
                                    style: const TextStyle(
                                      fontSize: 18.5,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.white,
                                    ),
                                  ),
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
          Positioned(
              right: 5,
              bottom: 0,
              child: Container(
                  width: mix ? 30 : 0,
                  height: mix ? 30 : 0,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(60),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withAlpha(200),
                            spreadRadius: 3,
                            blurRadius: 10),
                      ]),
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () async {
                      if (!shazaming) {
                        await Shazam().shazamIt(context, stid);
                      }
                    },
                    child: Image.asset(
                      'assets/icons/shazam.png',
                      color: Colors.white,
                    ),
                  )))
        ],
      ),
    );
  }
}
