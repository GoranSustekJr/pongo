import 'dart:ui';

import 'package:pongo/exports.dart';

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

  final TextStyle textStyle = TextStyle(
      overflow: TextOverflow.ellipsis,
      color: Col.text,
      fontSize: 18,
      fontWeight: FontWeight.w400);

  @override
  Widget build(BuildContext context) {
    void download() async {
      // Get the tracks that need to be downloaded
      List<String> toDownload = await DatabaseHelper()
          .queryMissingStids(tracks.map((track) => track.id).toList());

      OpenPlaylist().show(
        context,
        PlaylistHandler(
          type: PlaylistHandlerType.offline,
          toDownload: toDownload,
          function: PlaylistHandlerFunction.createPlaylist,
          track: tracks
              .map((track) => PlaylistHandlerOnlineTrack(
                    id: track.id,
                    name: track.name,
                    artist: track.artists
                        .map((artist) => {"id": artist.id, "name": artist.name})
                        .toList(),
                    cover: calculateBestImageForTrack(
                      track.album != null
                          ? track.album!.images
                          : track.album!.images,
                    ),
                    albumTrack: track.album,
                    playlistHandlerCoverType: PlaylistHandlerCoverType.url,
                  ))
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
          track: tracks
              .map((track) => PlaylistHandlerOnlineTrack(
                    id: track.id,
                    name: track.name,
                    artist: track.artists
                        .map((artist) => {"id": artist.id, "name": artist.name})
                        .toList(),
                    cover: calculateWantedResolutionForTrack(
                        track.album != null
                            ? track.album!.images
                            : track.album!.images,
                        150,
                        150),
                    albumTrack: track.album,
                    playlistHandlerCoverType: PlaylistHandlerCoverType.url,
                  ))
              .toList(),
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
            child: backLikeButton(
              context,
              AppIcons.playlist,
              () {
                // IOS
                // if (kIsIOS) {
                showPullDownMenu(
                    context: context,
                    items: [
                      PullDownMenuItem(
                          icon: AppIcons.addToQueue,
                          onTap: addToPlaylist,
                          title: AppLocalizations.of(context).addtoplaylist),
                      const PullDownMenuDivider(),
                      PullDownMenuItem(
                          icon: AppIcons.download,
                          onTap: download,
                          title: AppLocalizations.of(context).download),
                    ],
                    position: RelativeRect.fromLTRB(
                        30,
                        Scaffold.of(context).appBarMaxHeight == null
                            ? MediaQuery.of(context).padding.top +
                                AppBar().preferredSize.height
                            : Scaffold.of(context).appBarMaxHeight!,
                        20,
                        0),
                    topWidget: const SizedBox());
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
                            color: Col.realBackground.withAlpha(200),
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
                                    color: Col.text,
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
                                    color: Col.text,
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
              },
            ),
          ),
        ],
      ),
      automaticallyImplyLeading: false,
      flexibleSpace: ClipRRect(
        borderRadius:
            kIsDesktop ? BorderRadius.circular(15) : BorderRadius.zero,
        child: FlexibleSpaceBar(
          titlePadding: EdgeInsets.zero,
          centerTitle: true,
          title: AppBar(
            backgroundColor: useBlur.value
                ? Col.transp
                : Col.realBackground.withAlpha(
                    ((MediaQuery.of(context).size.height / 2 <=
                                    scrollControllerOffset
                                ? 1
                                : scrollControllerOffset /
                                    (MediaQuery.of(context).size.height / 2)) *
                            AppConstants().noBlur)
                        .toInt()),
            automaticallyImplyLeading: false,
            flexibleSpace: Opacity(
              opacity: MediaQuery.of(context).size.height / 2 <=
                      scrollControllerOffset
                  ? 1
                  : scrollControllerOffset /
                      (MediaQuery.of(context).size.height / 2),
              child: ClipRRect(
                borderRadius:
                    kIsDesktop ? BorderRadius.circular(15) : BorderRadius.zero,
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: useBlur.value ? 10 : 0,
                    sigmaY: useBlur.value ? 10 : 0,
                  ),
                  child: Container(),
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
                    child: ImageCompatible(
                      image: image,
                    ),
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
