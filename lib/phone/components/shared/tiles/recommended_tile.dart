// ignore_for_file: unused_local_variable

import 'package:flutter/cupertino.dart';
import 'package:flutter_desktop_context_menu/flutter_desktop_context_menu.dart';
import 'package:pongo/exports.dart';
import 'package:pongo/phone/components/recommended/Pull%20down%20menu%20items/recommended_track_pulldown_menu_items_desktop.dart';

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
    Size size = MediaQuery.of(context).size;
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
                ? AppLocalizations.of(context).playlist
                : data.description!
            : AppLocalizations.of(context).playlist;
        noImage = AppIcons.blankAlbum;
        pullDownMenuItems = [const SizedBox()];
        break;

      case TileType.artist:
        imageUrl = data.image ?? '';
        title = data.name;
        subtitle = AppLocalizations.of(context).artist;
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

    Widget child = Column(
      crossAxisAlignment: type == TileType.artist
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Container(
          height: kIsDesktop ? 160 : 120,
          width: kIsDesktop ? 160 : 120,
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(type == TileType.artist ? 360 : 7.5),
            color: Col.realBackground.withAlpha(150),
          ),
          child: ClipRRect(
            borderRadius:
                BorderRadius.circular(type == TileType.artist ? 360 : 7.5),
            child: imageUrl == ""
                ? Center(
                    child: Icon(noImage, color: Col.icon),
                  )
                : SizedBox(
                    child: ImageCompatible(image: imageUrl),
                  ),
          ),
        ),
        razh(2.5),
        Flexible(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 18,
                      //   width: 120,
                      child: Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: kIsApple ? 14 : 15,
                          fontWeight:
                              kIsApple ? FontWeight.w500 : FontWeight.w600,
                          color: Col.text,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ),
                    SizedBox(
                      height: 17,
                      // width: 120,
                      child: Text(
                        subtitle,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: kIsApple ? 12 : 13,
                          fontWeight:
                              kIsApple ? FontWeight.w400 : FontWeight.w500,
                          color: Col.text.withAlpha(175),
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        )
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7.5),
      child: SizedBox(
        height: kIsDesktop ? 200 : 160,
        width: kIsDesktop ? 160 : 120,
        child: GestureDetector(
            onSecondaryTap: () async {
              if (kIsDesktop) {
                if (type == TileType.track) {
                  /*   bool favourite = await DatabaseHelper()
                          .favouriteTrackAlreadyExists(data.id); */
                  popUpContextMenu(
                    recommendedTrackPulldownMenuItemsDesktop(
                        context,
                        data,
                        "recommended.single",
                        false, //favourite,
                        doesNotExist!,
                        doesNowExist!),
                  );
                }
              }
            },
            onLongPressStart: (LongPressStartDetails details) async {
              if (kIsMobile) {
                bool isFavourite =
                    await DatabaseHelper().favouriteTrackAlreadyExists(data.id);
                if (type == TileType.track) {
                  showPullDownMenu(
                    context: context,
                    items: searchTrackPulldownMenuItems(
                      context,
                      data,
                      "recommended.single.",
                      isFavourite,
                      doesNotExist!,
                      doesNowExist!,
                    ),
                    position: RelativeRect.fromLTRB(
                      details.globalPosition.dx >= 260
                          ? details.globalPosition.dx
                          : size.width - details.globalPosition.dx,
                      size.height - details.globalPosition.dy - 300 > 150
                          ? details.globalPosition.dy
                          : 400,
                      details.globalPosition.dx >= 260
                          ? size.width - details.globalPosition.dx
                          : details.globalPosition.dx,
                      details.globalPosition.dy,
                    ),
                    topWidget: const SizedBox(),
                  );
                }
              }
            },
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: onTap,
              child: child,
            )),
      ),
    );
  }
}
