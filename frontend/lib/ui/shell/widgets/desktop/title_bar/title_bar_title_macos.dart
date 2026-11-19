// ignore_for_file: unrelated_type_equality_checks

import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../../../../data/repositories/player/media_items.dart';
import '../../../../../utils/platform.dart';
import '../../../../../utils/result.dart';
import '../../../../artist/widgets/phone/artist_phone.dart';
import '../../../../core/app_icons.dart';
import '../../../../core/themes/colors.dart';
import '../../../../core/ui/image/image_compatible.dart';
import '../../../../core/ui/space.dart';
import '../../../view_models/shell_view_model.dart';

class TitleBarTitleMacos extends StatelessWidget {
  final MediaItem currentMediaItem;
  const TitleBarTitleMacos({super.key, required this.currentMediaItem});

  @override
  Widget build(BuildContext context) {
    final artists = currentMediaItem.artistRefs;
    return SizedBox(
      width:
          MediaQuery.of(context).size.width -
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
                color: context.colors.primaryCard,
                child:
                    currentMediaItem.artUri != null &&
                        currentMediaItem.artUri != '' &&
                        currentMediaItem.artUri != 'null'
                    ? SizedBox(
                        height: 50,
                        width: 50,
                        child: ImageCompatible(
                          image: (currentMediaItem.artUri?.toString() ?? ''),
                        ),
                      )
                    : Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: context.colors.primaryCard.withAlpha(150),
                        ),
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
                    // Ensures horizontal scrolling instead of wrapping
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(artists.length, (index) {
                        final artist = artists[index];
                        return CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () async {
                            final result = await context.shell.artist(
                              id: artist.id,
                              name: artist.name ?? '',
                            );
                            if (result case Ok(:final value)
                                when context.mounted) {
                              await showMacosSheet(
                                context: context,
                                builder: (_) => ArtistPhone(
                                  artist: value,
                                  context: context,
                                ),
                              );
                            }
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                artist.name ?? '',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w300,
                                  color: Colors.white.withAlpha(200),
                                ),
                              ),
                              if (index != artists.length - 1)
                                Text(
                                  ', ',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w300,
                                    color: Colors.white.withAlpha(200),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
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
