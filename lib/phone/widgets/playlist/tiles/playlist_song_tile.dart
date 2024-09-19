import 'package:flutter/cupertino.dart';
import 'package:pongo/exports.dart';

class PlaylistSongTile extends StatelessWidget {
  final Track track;
  final bool first;
  final bool last;
  final bool exists;
  final Function() function;
  final Widget? trailing;
  const PlaylistSongTile({
    super.key,
    required this.track,
    required this.first,
    required this.last,
    required this.function,
    this.trailing,
    required this.exists,
  });

  @override
  Widget build(BuildContext context) {
    double radius = 15;
    BorderRadius borderRadius = BorderRadius.only(
      topLeft: first ? Radius.circular(radius) : Radius.zero,
      topRight: first ? Radius.circular(radius) : Radius.zero,
      bottomLeft: last ? Radius.circular(radius) : Radius.zero,
      bottomRight: last ? Radius.circular(radius) : Radius.zero,
    );

    return Padding(
      padding: EdgeInsets.zero,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: exists ? 1 : 0.5,
        child: ClipRRect(
          child: kIsApple
              ? Container(
                  height: 65,
                  width: MediaQuery.of(context).size.width - 20,
                  decoration: BoxDecoration(
                    borderRadius: borderRadius,
                    color: Col.transp,
                  ),
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      function();
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (!first)
                          Container(
                            height: 1,
                            width: MediaQuery.of(context).size.width - 100,
                            color: Col.onIcon.withAlpha(50),
                          ),
                        Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(7.5),
                                  color: Col.realBackground.withAlpha(150),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(7.5),
                                  child: track.album ==
                                          null //!track["track"].keys.contains("album")
                                      ? Center(
                                          child: Icon(AppIcons.blankTrack,
                                              color: Colors.white),
                                        )
                                      : CachedNetworkImage(
                                          imageUrl:
                                              calculateWantedResolutionForTrack(
                                            track.album!.images,
                                            100,
                                            100,
                                          ),
                                          fit: BoxFit.cover,
                                        ),
                                ),
                              ),
                            ),
                            razw(12.5),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    track.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 16.5,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  razh(2.5),
                                  Text(
                                    track.artists
                                        .map((artist) => artist.name)
                                        .join(', '),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.white.withAlpha(200),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              child: trailing,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              : InkWell(
                  onTap: () {
                    function();
                  },
                  splashColor: Colors.white.withAlpha(100),
                  borderRadius: borderRadius,
                  child: Container(
                    height: 60,
                    width: MediaQuery.of(context).size.width - 20,
                    decoration: BoxDecoration(
                      borderRadius: borderRadius,
                      color: Col.primaryCard.withAlpha(200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          width: 55,
                          height: 55,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(7.5),
                            color: Col.realBackground.withAlpha(150),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(7.5),
                            child: track.album == null
                                ? Center(
                                    child: Icon(AppIcons.blankTrack,
                                        color: Colors.white),
                                  )
                                : CachedNetworkImage(
                                    imageUrl: calculateWantedResolutionForTrack(
                                      track.album!.images,
                                      100,
                                      100,
                                    ),
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                        Row(
                          children: [
                            razw(12.5),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    track.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 18.5,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  razh(2.5),
                                  Text(
                                    track.artists
                                        .map((artist) => artist.name)
                                        .join(', '),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.white.withAlpha(200),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              child: trailing,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
