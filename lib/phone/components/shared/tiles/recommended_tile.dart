import 'package:flutter/cupertino.dart';
import 'package:pongo/exports.dart';
import 'package:pongo/phone/components/recommended/Pull%20down%20menu%20items/recommended_track_pulldown_menu_items.dart';

class RecommendedTile extends StatelessWidget {
  final dynamic data;
  final bool showLoading;
  final TileType type;
  final Function() onTap;
  final Widget? trailing;
  final Function(String)? doesNotExist;
  final Function(String)? doesNowExist;
  const RecommendedTile({
    super.key,
    required this.data,
    required this.showLoading,
    required this.type,
    required this.onTap,
    this.trailing,
    this.doesNotExist,
    this.doesNowExist,
  });

  @override
  Widget build(BuildContext context) {
    final String imageUrl;
    final String title;
    final String subtitle;
    final IconData noImage;
    final List<Widget> pullDownMenuItems;

    switch (type) {
      case TileType.track:
        imageUrl = data.album != null
            ? calculateWantedResolutionForTrack(data.album.images, 300, 300)
            : '';
        title = data.name;
        subtitle = data.artists.map((artist) => artist.name).join(', ');
        noImage = AppIcons.blankTrack;
        pullDownMenuItems = recommendedTrackCupertinoContextMenuActions(
            context, data, "recommended.single.", doesNotExist!, doesNowExist!);
        break;

      case TileType.playlist:
        imageUrl = data.image ?? '';
        title = data.name;
        subtitle = data.description != null
            ? data.description!.contains("<a href=spotify:")
                ? AppLocalizations.of(context)!.playlist
                : data.description!
            : AppLocalizations.of(context)!.playlist;
        noImage = AppIcons.blankAlbum;
        pullDownMenuItems = [const SizedBox()];
        break;

      case TileType.artist:
        imageUrl = data.image ?? '';
        title = data.name;
        subtitle = AppLocalizations.of(context)!.artist;
        noImage = AppIcons.blankArtist;
        pullDownMenuItems = [const SizedBox()];
        break;

      case TileType.album:
        imageUrl = data.image ?? '';
        title = data.name;
        subtitle = data.artists.join(", ");
        noImage = AppIcons.blankAlbum;
        pullDownMenuItems = [const SizedBox()];
        break;
    }

    return kIsApple
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7.5),
            child: SizedBox(
              height: 160,
              width: 120,
              child: CupertinoContextMenu(
                enableHapticFeedback: true,
                actions: pullDownMenuItems,
                child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: onTap,
                    child: Column(
                      children: [
                        Container(
                          height: 120,
                          width: 120,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                                type == TileType.artist ? 360 : 7.5),
                            color: Col.realBackground.withAlpha(150),
                          ),
                          child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                  type == TileType.artist ? 360 : 7.5),
                              child: Stack(
                                children: [
                                  imageUrl == ""
                                      ? Center(
                                          child: Icon(noImage,
                                              color: Colors.white),
                                        )
                                      : SizedBox(
                                          height: 120,
                                          width: 120,
                                          child: CachedNetworkImage(
                                            imageUrl: imageUrl,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: AnimatedOpacity(
                                      opacity: showLoading ? 1 : 0,
                                      duration:
                                          const Duration(milliseconds: 500),
                                      child: Center(
                                        child: Container(
                                          width: 30,
                                          height: 30,
                                          padding: const EdgeInsets.all(7.5),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(7.5),
                                            color:
                                                Col.primaryCard.withAlpha(225),
                                          ),
                                          child: Center(
                                              child: kIsApple
                                                  ? const CupertinoActivityIndicator(
                                                      radius: 10)
                                                  : CircularProgressIndicator(
                                                      key: const ValueKey(true),
                                                      strokeWidth: 2,
                                                      color: Colors.white
                                                          .withAlpha(200),
                                                    )),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )),
                        ),
                        razh(2.5),
                        SizedBox(
                          height: 18,
                          width: 120,
                          child: Text(
                            title,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: kIsApple ? 14 : 15,
                              fontWeight:
                                  kIsApple ? FontWeight.w500 : FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 17,
                          width: 120,
                          child: Text(
                            subtitle,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: kIsApple ? 12 : 13,
                              fontWeight:
                                  kIsApple ? FontWeight.w400 : FontWeight.w500,
                              color: Colors.white.withAlpha(175),
                            ),
                          ),
                        ),
                      ],
                    )),
              ),
            ),
          )
        : InkWell(
            splashColor: Colors.white.withAlpha(200),
            highlightColor: Colors.white.withAlpha(150),
            onTap: onTap,
            child: SizedBox(
              height: 85,
              width: MediaQuery.of(context).size.width,
              child: ListTile(
                leading: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                    maxWidth: 66,
                    maxHeight: 66,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7.5),
                    child: imageUrl == ""
                        ? Center(
                            child: Icon(noImage),
                          )
                        : CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
                title: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withAlpha(200),
                  ),
                ),
              ),
            ),
          );
  }
}
