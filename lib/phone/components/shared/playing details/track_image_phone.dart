import 'package:pongo/exports.dart';

class TrackImagePhone extends StatelessWidget {
  final bool lyricsOn;
  final String image;
  const TrackImagePhone({
    super.key,
    required this.lyricsOn,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    print(image);
    Size size = MediaQuery.of(context).size;
    return AnimatedPositioned(
      duration: Duration(milliseconds: lyricsOn ? 200 : 600),
      //top: lyricsOn ? 0 : MediaQuery.of(context).padding.top + 30,
      bottom: lyricsOn
          ? size.height
          : size.height -
              (MediaQuery.of(context).padding.top + 30 + size.width - 60),
      curve: Curves.decelerate,
      child: AnimatedOpacity(
        opacity: lyricsOn ? 0 : 1,
        duration: Duration(milliseconds: lyricsOn ? 1000 : 1000),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: lyricsOn ? 0 : size.width - 60,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(7.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(100),
                        spreadRadius: 5,
                        blurRadius: 15,
                      ),
                    ]),
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7.5),
                    child: CachedNetworkImage(
                      imageUrl:
                          image, //  "REMOVEDtrack_art/${currentMediaItem.id.split(".")[2]}.png",
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
