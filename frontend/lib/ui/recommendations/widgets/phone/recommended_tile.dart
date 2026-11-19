// ignore_for_file: unused_local_variable

import 'package:flutter/cupertino.dart';
import 'package:flutter_desktop_context_menu/flutter_desktop_context_menu.dart';
import 'package:kr_pull_down_button/pull_down_button.dart';
import 'package:star_menu/star_menu.dart';

import '../../../../domain/models/catalog/album.dart' show Album;
import '../../../../domain/models/catalog/artist.dart' show Artist;
import '../../../../domain/models/catalog/playlist.dart' show Playlist;
import '../../../../domain/models/catalog/track.dart';
import '../../../../utils/platform.dart';
import '../../../core/themes/colors.dart';
import '../../../core/ui/image/image_compatible.dart';
import '../../../core/ui/space.dart';
import '../../../core/view_models/track_actions_view_model.dart';
import '../../../search/widgets/phone/search_result_tile.dart';
import '../../../search/widgets/phone/search_track_pulldown_menu_items.dart';
import '../desktop/recommended_track_pulldown_menu_items_desktop.dart';

class RecommendedTile extends StatelessWidget {
  static double get height => kIsDesktop ? 200 : 178;
  static double get _imageSize => kIsDesktop ? 160 : 140;

  /// The [Track], [Playlist], [Artist] or [Album] shown.
  final Object data;
  final bool showLoading;
  final TileType type;
  final Function() onTap;
  final Widget? trailing;
  const RecommendedTile({
    super.key,
    required this.data,
    required this.showLoading,
    required this.type,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final (:imageUrl, :title, :subtitle, :noImage) = tileContent(context, data);

    // Start menu --> android popup
    final StarMenuController starMenuController = StarMenuController();

    // Star menu global key
    final GlobalKey globalKey = GlobalKey();

    final Widget child = Column(
      crossAxisAlignment: type == TileType.artist
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Container(
          height: _imageSize,
          width: _imageSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              type == TileType.artist ? 360 : 14,
            ),
            color: context.colors.realBackground.withAlpha(150),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              type == TileType.artist ? 360 : 14,
            ),
            child: imageUrl == ''
                ? Center(child: Icon(noImage, color: context.colors.icon))
                : SizedBox(child: ImageCompatible(image: imageUrl)),
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
                          fontWeight: kIsApple
                              ? FontWeight.w500
                              : FontWeight.w600,
                          color: context.colors.text,
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
                          fontWeight: kIsApple
                              ? FontWeight.w400
                              : FontWeight.w500,
                          color: context.colors.text.withAlpha(175),
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7.5),
      child: SizedBox(
        key: globalKey,
        height: height,
        width: _imageSize,
        child: GestureDetector(
          onSecondaryTap: () async {
            if (kIsDesktop) {
              if (data case final Track track) {
                await popUpContextMenu(
                  recommendedTrackPulldownMenuItemsDesktop(
                    context,
                    track,
                    'recommended.single',
                    false, //favourite,
                  ),
                );
              }
            }
          },
          onLongPressStart: (LongPressStartDetails details) async {
            if (kIsMobile) {
              if (data case final Track track) {
                final bool isFavourite = await context.trackActions.isFavourite(
                  track.id,
                );
                if (!context.mounted) return;
                if (true) {
                  await showPullDownMenu(
                    context: context,
                    items: searchTrackPulldownMenuItemsApple(
                      context,
                      track,
                      'recommended.single',
                      isFavourite,
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
                } /* else {
                  StarMenuOverlay.displayStarMenu(
                    globalKey.currentContext!,
                    StarMenu(
                      params: StarMenuParameters(
                          shape: MenuShape.linear,
                          useTouchAsCenter: true,
                          boundaryBackground: BoundaryBackground(
                            blurSigmaX: 5,
                            blurSigmaY: 5,
                            padding: EdgeInsets.zero,
                            color: context.colors.realBackground.withAlpha(200),
                          ),
                          linearShapeParams: const LinearShapeParams(
                              alignment: LinearAlignment.center)),
                      onItemTapped: (index, controller) {
                        controller.closeMenu;
                      },
                      items: searchTrackPulldownMenuItemsAndroid(
                        context,
                        data,
                        "recommended.single.",
                        isFavourite,
                      ),
                      parentContext: globalKey.currentContext,
                    ),
                  );
                } */
              }
            }
          },
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: onTap,
            child: child,
          ),
        ),
      ),
    );
  }
}
