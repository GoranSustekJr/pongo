import 'package:flutter/cupertino.dart';
import 'package:pongo/exports.dart';

enum TileType { playlist, artist, album, track }

class SearchResultTile extends StatelessWidget {
  final dynamic data;
  final TileType type;
  final Function() onTap;
  final Widget? trailing;
  const SearchResultTile({
    super.key,
    this.data,
    required this.type,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final String imageUrl;
    final String title;
    final String subtitle;
    final IconData noImage;

    switch (type) {
      case TileType.track:
        imageUrl = data.album != null
            ? calculateWantedResolutionForTrack(data.album.images, 300, 300)
            : '';
        title = data.name;
        subtitle = data.artists.map((artist) => artist.name).join(', ');
        noImage = AppIcons.blankTrack;
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
        break;

      case TileType.artist:
        imageUrl = data.image ?? '';
        title = data.name;
        subtitle = AppLocalizations.of(context)!.artist;
        noImage = AppIcons.blankArtist;
        break;

      case TileType.album:
        imageUrl = data.image ?? '';
        title = data.name;
        subtitle = data.artists.join(", ");
        noImage = AppIcons.blankAlbum;
        break;
    }

    return kIsApple
        ? /*SwipeActionCell(
             key: key!,
            trailingActions: type == TileType.track
                ? [
                    SwipeAction(
                      content: iconButton(
                          AppIcons.addToQueue, Colors.white, addToQueue!),
                      onTap: (CompletionHandler handler) {
                        //handler.call(null);
                      },
                      color: Col.transp,
                      backgroundRadius: 360,
                    ),
                  ]
                : [],
            child: CupertinoContextMenu(
              actions: [
                CupertinoContextMenuAction(
                  isDestructiveAction: true,
                  isDefaultAction: true,
                  onPressed: () {
                    print("object");
                    //   Navigator.pop(context);
                  },
                  child: const Text("ACtion"),
                )
              ],
              enableHapticFeedback: true,
              child: */
        SizedBox(
            height: 85,
            width: MediaQuery.of(context).size.width,
            child: CupertinoButton(
                padding: const EdgeInsets.only(left: 15, right: 5),
                onPressed: onTap,
                child: Row(
                  children: [
                    Container(
                      width: 65,
                      height: 65,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(7.5),
                        color: Col.realBackground.withAlpha(150),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(7.5),
                        child: imageUrl == ""
                            ? Center(
                                child: Icon(noImage, color: Colors.white),
                              )
                            : CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
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
                            title,
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
                            subtitle,
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
                )),
            /*    ),
            ), */
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
