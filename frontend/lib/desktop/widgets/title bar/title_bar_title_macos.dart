// ignore_for_file: unrelated_type_equality_checks

import 'package:flutter/cupertino.dart';

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
                SizedBox(
                  height: 20,
                  child: Text(
                    currentMediaItem.title,
                    style: TextStyle(
                      fontSize: kIsApple ? 17 : 18,
                      fontWeight: kIsApple ? FontWeight.w500 : FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(
                  height: 20,
                  child: SingleChildScrollView(
                    scrollDirection: Axis
                        .horizontal, // Ensures horizontal scrolling instead of wrapping
                    child: Row(
                      children: List.generate(
                        jsonDecode(currentMediaItem.extras?["artists"]).length,
                        (index) {
                          var artist = jsonDecode(
                              currentMediaItem.extras?["artists"])[index];
                          return CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () async {
                              Map artistData = await ArtistSpotify()
                                  .getImage(context, artist["id"]);
                              showMacosSheet(
                                context: context,
                                builder: (_) => ArtistPhone(
                                  artist: Artist(
                                    id: artist["id"],
                                    name: artist["name"],
                                    image: calculateBestImageForTrack(
                                      (artistData["images"] as List<dynamic>)
                                          .map((image) => AlbumImagesTrack(
                                                url: image["url"],
                                                height: image["height"],
                                                width: image["width"],
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
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w300,
                                    color: Colors.white.withAlpha(200),
                                  ),
                                ),
                                if (index !=
                                    jsonDecode(currentMediaItem
                                                .extras?["artists"])
                                            .length -
                                        1)
                                  Text(
                                    ", ",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w300,
                                      color: Colors.white.withAlpha(200),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
