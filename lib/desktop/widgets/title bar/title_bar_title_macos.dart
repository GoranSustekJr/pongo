// ignore_for_file: unrelated_type_equality_checks

import '../../../exports.dart';

class TitleBarTitleMacos extends StatelessWidget {
  final MediaItem currentMediaItem;
  const TitleBarTitleMacos({super.key, required this.currentMediaItem});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width -
          40 -
          15 -
          100 -
          15 -
          30 -
          40 -
          5 -
          100 -
          200 -
          140 -
          25,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RepaintBoundary(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Container(
                width: 50,
                height: 50,
                color: Col.primaryCard,
                child: currentMediaItem.artUri != null &&
                        currentMediaItem.artUri != "" &&
                        currentMediaItem.artUri != "null"
                    ? SizedBox(
                        height: 50,
                        width: 50,
                        child: ImageCompatible(
                          image: currentMediaItem.artUri.toString(),
                        ),
                      )
                    : Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: Col.primaryCard.withAlpha(150)),
                        child: Center(
                          child: Icon(
                            AppIcons.blankTrack,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                razh(2.5),
                marquee(
                  currentMediaItem.title,
                  TextStyle(
                    fontSize: kIsApple ? 17 : 18,
                    fontWeight: kIsApple ? FontWeight.w500 : FontWeight.w600,
                  ),
                  1,
                  TextOverflow.ellipsis,
                  height: 20,
                ),
                marquee(
                  currentMediaItem.artist!,
                  TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                    color: Colors.white.withAlpha(200),
                  ),
                  1,
                  TextOverflow.ellipsis,
                  height: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
