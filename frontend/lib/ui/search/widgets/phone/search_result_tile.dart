import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../domain/models/catalog/album.dart';
import '../../../../domain/models/catalog/artist.dart';
import '../../../../domain/models/catalog/playlist.dart';
import '../../../../domain/models/catalog/track.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../utils/image_resolution.dart';
import '../../../../utils/platform.dart';
import '../../../core/app_icons.dart';
import '../../../core/themes/colors.dart';
import '../../../core/ui/image/image_compatible.dart';
import '../../../core/ui/space.dart';

enum TileType { playlist, artist, album, track }

/// What a tile shows for [data], a [Track], [Playlist], [Artist] or [Album].
({String imageUrl, String title, String subtitle, IconData noImage})
tileContent(BuildContext context, Object data) {
  final l10n = AppLocalizations.of(context);
  return switch (data) {
    final Track track => (
      imageUrl: track.album != null
          ? imageUrlForSize(track.album!.images, 300, 300)
          : '',
      title: track.name,
      subtitle: track.artistNames,
      noImage: AppIcons.blankTrack,
    ),
    final Playlist playlist => (
      imageUrl: playlist.image,
      title: playlist.name,
      subtitle: switch (playlist.description) {
        final String description
            when !description.contains('<a href=spotify:') =>
          description,
        _ => l10n.playlist,
      },
      noImage: AppIcons.blankAlbum,
    ),
    final Artist artist => (
      imageUrl: artist.image,
      title: artist.name,
      subtitle: l10n.artist,
      noImage: AppIcons.blankArtist,
    ),
    final Album album => (
      imageUrl: album.image,
      title: album.name,
      subtitle: album.artists.join(', '),
      noImage: AppIcons.blankAlbum,
    ),
    _ => throw ArgumentError.value(data, 'data', 'Unsupported tile data'),
  };
}

class SearchResultTile extends StatelessWidget {
  /// The [Track], [Playlist], [Artist] or [Album] shown.
  final Object data;
  final bool pushWhite;
  final TileType type;
  final Function() onTap;
  final Widget? trailing;
  const SearchResultTile({
    super.key,
    required this.data,
    required this.type,
    required this.onTap,
    this.trailing,
    required this.pushWhite,
  });

  @override
  Widget build(BuildContext context) {
    final (:imageUrl, :title, :subtitle, :noImage) = tileContent(context, data);

    final Widget widget = Row(
      children: [
        Container(
          width: 65,
          height: 65,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7.5),
            color: context.colors.realBackground.withAlpha(150),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7.5),
            child: imageUrl == ''
                ? Center(
                    child: Icon(
                      noImage,
                      color: pushWhite ? Colors.white : context.colors.icon,
                    ),
                  )
                : ImageCompatible(image: imageUrl),
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
                  color: pushWhite ? Colors.white : context.colors.text,
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
                  color: pushWhite
                      ? Colors.white
                      : context.colors.text.withAlpha(200),
                ),
              ),
            ],
          ),
        ),
        SizedBox(child: trailing),
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
                splashColor: context.colors.text.withAlpha(50),
                highlightColor: context.colors.text.withAlpha(25),
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
