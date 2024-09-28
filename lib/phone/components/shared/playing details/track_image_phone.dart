import 'package:pongo/exports.dart';

class TrackImagePhone extends StatelessWidget {
  final bool lyricsOn;
  final bool showQueue;
  final String image;
  const TrackImagePhone({
    super.key,
    required this.lyricsOn,
    required this.image,
    required this.showQueue,
  });

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return AnimatedPositioned(
      duration: Duration(milliseconds: lyricsOn || showQueue ? 200 : 600),
      //top: lyricsOn || showQueue ? 0 : MediaQuery.of(context).padding.top + 30,
      bottom: lyricsOn || showQueue
          ? size.height
          : size.height -
              (MediaQuery.of(context).padding.top + 30 + size.width - 60),
      curve: Curves.decelerate,
      child: AnimatedOpacity(
        opacity: lyricsOn || showQueue ? 0 : 1,
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
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      switchInCurve: Curves.fastOutSlowIn,
                      switchOutCurve: Curves.fastEaseInToSlowEaseOut,
                      child: CachedNetworkImage(
                        key: ValueKey(image),
                        imageUrl: image,
                      ),
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
