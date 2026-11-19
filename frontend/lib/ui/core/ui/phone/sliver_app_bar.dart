import 'package:flutter/material.dart';
import 'package:kr_pull_down_button/pull_down_button.dart';
import 'package:star_menu/star_menu.dart';

import '../../../../domain/models/catalog/track.dart';
import '../../../../domain/models/playlists/playlist_handler.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../utils/image_resolution.dart';
import '../../../../utils/platform.dart';
import '../../../app/view_models/app_settings_view_model.dart';
import '../../../playlists/view_models/open_playlist.dart';
import '../../app_icons.dart';
import '../../themes/colors.dart';
import '../../themes/dimens.dart';
import '../../view_models/track_actions_view_model.dart';
import '../app_blur.dart';
import '../image/image_compatible.dart';
import 'buttons/back_button.dart';
import 'buttons/back_like_button.dart';
import 'liquid_glass_background.dart';

class SliverAppBarPhone extends StatelessWidget {
  final String name;
  final List<Track> tracks;
  final String image;
  final double scrollControllerOffset;
  SliverAppBarPhone({
    super.key,
    required this.name,
    required this.tracks,
    required this.scrollControllerOffset,
    required this.image,
  });

  final GlobalKey globalKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    Future<void> download() async {
      // Get the tracks that need to be downloaded
      final List<String> toDownload = await context.trackActions
          .missingDownloads(tracks.map((track) => track.id).toList());
      if (!context.mounted) return;

      OpenPlaylist().show(
        context,
        PlaylistHandler(
          type: PlaylistHandlerType.offline,
          toDownload: toDownload,
          function: PlaylistHandlerFunction.createPlaylist,
          track: tracks
              .map(
                (track) => PlaylistHandlerOnlineTrack(
                  id: track.id,
                  name: track.name,
                  artist: track.artists,
                  cover: bestImageUrl(track.album?.images ?? const []),
                  albumTrack: track.album,
                  playlistHandlerCoverType: PlaylistHandlerCoverType.url,
                ),
              )
              .toList(),
        ),
      );
      if (!kIsApple) {
        StarMenuOverlay.dispose();
      }
    }

    void addToPlaylist() {
      OpenPlaylist().show(
        context,
        PlaylistHandler(
          type: PlaylistHandlerType.online,
          function: PlaylistHandlerFunction.createPlaylist,
          track: tracks.map(onlineHandlerTrack).toList(),
        ),
      );
      if (!kIsApple) {
        StarMenuOverlay.dispose();
      }
    }

    return SliverAppBar(
      snap: false,
      collapsedHeight: kToolbarHeight,
      expandedHeight: kIsMacOS ? 400 : MediaQuery.of(context).size.height / 2,
      floating: false,
      pinned: true,
      backgroundColor: Col.transp,
      surfaceTintColor: Col.transp,
      stretch: true,
      title: Row(
        children: [
          backButton(context),
          Flexible(
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
          Container(
            key: globalKey,
            child: backLikeButton(context, AppIcons.playlist, () {
              // IOS
              // if (kIsIOS) {
              showPullDownMenu(
                context: context,
                items: [
                  PullDownMenuItem(
                    icon: AppIcons.addToQueue,
                    onTap: addToPlaylist,
                    title: AppLocalizations.of(context).addtoplaylist,
                  ),
                  const PullDownMenuDivider(),
                  PullDownMenuItem(
                    icon: AppIcons.download,
                    onTap: download,
                    title: AppLocalizations.of(context).download,
                  ),
                ],
                position: RelativeRect.fromLTRB(
                  30,
                  Scaffold.of(context).appBarMaxHeight == null
                      ? MediaQuery.of(context).padding.top +
                            AppBar().preferredSize.height
                      : Scaffold.of(context).appBarMaxHeight!,
                  20,
                  0,
                ),
                topWidget: const SizedBox(),
              );
              /* } else {
                  // Android
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
                      items: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(7.5)),
                          child: inkWell(
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 7.5),
                              height: 40,
                              width: 200,
                              decoration: const BoxDecoration(),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      AppLocalizations.of(context).download,
                                      style: textStyle,
                                      maxLines: 1,
                                    ),
                                  ),
                                  Icon(
                                    AppIcons.download,
                                    color: context.colors.text,
                                    size: 18,
                                  )
                                ],
                              ),
                            ),
                            download,
                          ),
                        ),
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(7.5)),
                          child: inkWell(
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 7.5),
                              height: 40,
                              width: 200,
                              decoration: const BoxDecoration(),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      AppLocalizations.of(context)
                                          .addtoplaylist,
                                      style: textStyle,
                                      maxLines: 1,
                                    ),
                                  ),
                                  Icon(
                                    AppIcons.addToQueue,
                                    color: context.colors.text,
                                    size: 18,
                                  )
                                ],
                              ),
                            ),
                            addToPlaylist,
                          ),
                        ),
                      ],
                      parentContext: globalKey.currentContext,
                    ),
                  );
                } */
            }),
          ),
        ],
      ),
      automaticallyImplyLeading: false,
      flexibleSpace: ClipRRect(
        borderRadius: kIsDesktop
            ? BorderRadius.circular(15)
            : BorderRadius.zero,
        child: FlexibleSpaceBar(
          titlePadding: EdgeInsets.zero,
          centerTitle: true,
          title: AppBar(
            backgroundColor: context.readSettings.useBlur
                ? Col.transp
                : context.colors.realBackground.withAlpha(
                    ((MediaQuery.of(context).size.height / 2 <=
                                    scrollControllerOffset
                                ? 1
                                : scrollControllerOffset /
                                      (MediaQuery.of(context).size.height /
                                          2)) *
                            Dimens.noBlur)
                        .toInt(),
                  ),
            automaticallyImplyLeading: false,
            flexibleSpace: Opacity(
              opacity:
                  MediaQuery.of(context).size.height / 2 <=
                      scrollControllerOffset
                  ? 1
                  : scrollControllerOffset /
                        (MediaQuery.of(context).size.height / 2),
              child: ClipRRect(
                borderRadius: kIsDesktop
                    ? BorderRadius.circular(15)
                    : BorderRadius.zero,
                child: liquidGlassBackground(
                  child: BackdropFilter(
                    filter: nonAppleBlur(context, 10),
                    child: Container(),
                  ),
                ),
              ),
            ),
          ),
          background: Center(
            child: SizedBox(
              width: kIsMacOS ? 300 : MediaQuery.of(context).size.width - 60,
              height: kIsMacOS ? 300 : MediaQuery.of(context).size.width - 60,
              child: Center(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: ImageCompatible(image: image),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
