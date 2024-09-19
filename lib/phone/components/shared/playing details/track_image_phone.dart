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
        duration: const Duration(milliseconds: 1000),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: size.width - 60,
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: CachedNetworkImage(
                      imageUrl: image,
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
