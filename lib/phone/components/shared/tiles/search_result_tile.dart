import 'package:flutter/cupertino.dart';
import 'package:pongo/exports.dart';

enum TileType { playlist, artist, album, track }

class SearchResultTile extends StatelessWidget {
  final dynamic data;
  final bool pushWhite;
  final TileType type;
  final Function() onTap;
  final Widget? trailing;
  const SearchResultTile({
    super.key,
    this.data,
    required this.type,
    required this.onTap,
    this.trailing,
    required this.pushWhite,
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
                ? AppLocalizations.of(context).playlist
                : data.description!
            : AppLocalizations.of(context).playlist;
        noImage = AppIcons.blankAlbum;
        break;

      case TileType.artist:
        imageUrl = data.image ?? '';
        title = data.name;
        subtitle = AppLocalizations.of(context).artist;
        noImage = AppIcons.blankArtist;
        break;

      case TileType.album:
        imageUrl = data.image ?? '';
        title = data.name;
        subtitle = data.artists.join(", ");
        noImage = AppIcons.blankAlbum;
        break;
    }

    Widget widget = Row(
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
                    child: Icon(noImage,
                        color: pushWhite ? Colors.white : Col.icon),
                  )
                : ImageCompatible(
                    image: imageUrl,
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
                style: TextStyle(
                  fontSize: 18.5,
                  fontWeight: FontWeight.w600,
                  color: pushWhite ? Colors.white : Col.text,
                ),
              ),
              razh(2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: pushWhite ? Colors.white : Col.text.withAlpha(200),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          child: trailing,
        ),
      ],
    );

    return SizedBox(
      height: 85,
      width: MediaQuery.of(context).size.width,
      child: kIsApple
          ? CupertinoButton(
              padding: const EdgeInsets.only(left: 15, right: 5),
              onPressed: onTap,
              child: widget,
              /*    ),
            ), */
            )
          : Material(
              color: Col.transp,
              child: InkWell(
                splashColor: Col.text.withAlpha(50),
                highlightColor: Col.text.withAlpha(25),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.only(left: 15, right: 5),
                  child: widget,
                ),
              ),
            ),
    );
  }
}
