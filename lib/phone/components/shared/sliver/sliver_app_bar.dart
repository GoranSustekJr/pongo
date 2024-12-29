import 'dart:ui';

import 'package:pongo/exports.dart';

class SliverAppBarPhone extends StatelessWidget {
  final String name;
  final List<Track> tracks;
  final String image;
  final double scrollControllerOffset;
  const SliverAppBarPhone({
    super.key,
    required this.name,
    required this.tracks,
    required this.scrollControllerOffset,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      snap: false,
      collapsedHeight: kToolbarHeight,
      expandedHeight: MediaQuery.of(context).size.height / 2,
      floating: false,
      pinned: true,
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
                ),
              ),
            ),
          ),
          backLikeButton(
            context,
            AppIcons.playlist,
            () {
              if (kIsIOS) {
                showPullDownMenu(
                    context: context,
                    items: [
                      PullDownMenuItem(
                          icon: AppIcons.addToQueue,
                          onTap: () {
                            OpenPlaylist().show(
                              context,
                              PlaylistHandler(
                                type: PlaylistHandlerType.online,
                                function:
                                    PlaylistHandlerFunction.createPlaylist,
                                track: tracks
                                    .map((track) => PlaylistHandlerOnlineTrack(
                                          id: track.id,
                                          name: track.name,
                                          artist: track.artists
                                              .map((artist) => {
                                                    "id": artist.id,
                                                    "name": artist.name
                                                  })
                                              .toList(),
                                          cover:
                                              calculateWantedResolutionForTrack(
                                                  track.album != null
                                                      ? track.album!.images
                                                      : track.album!.images,
                                                  150,
                                                  150),
                                          playlistHandlerCoverType:
                                              PlaylistHandlerCoverType.url,
                                        ))
                                    .toList(),
                              ),
                            );
                          },
                          title: AppLocalizations.of(context)!.addtoplaylist),
                      PullDownMenuItem(
                          icon: AppIcons.download,
                          onTap: () async {
                            // Get the tracks that need to be downloaded
                            List<String> toDownload = await DatabaseHelper()
                                .queryMissingStids(
                                    tracks.map((track) => track.id).toList());

                            OpenPlaylist().show(
                              context,
                              PlaylistHandler(
                                type: PlaylistHandlerType.offline,
                                toDownload: toDownload,
                                function:
                                    PlaylistHandlerFunction.createPlaylist,
                                track: tracks
                                    .map((track) => PlaylistHandlerOnlineTrack(
                                          id: track.id,
                                          name: track.name,
                                          artist: track.artists
                                              .map((artist) => {
                                                    "id": artist.id,
                                                    "name": artist.name
                                                  })
                                              .toList(),
                                          cover: calculateBestImageForTrack(
                                            track.album != null
                                                ? track.album!.images
                                                : track.album!.images,
                                          ),
                                          playlistHandlerCoverType:
                                              PlaylistHandlerCoverType.url,
                                        ))
                                    .toList(),
                              ),
                            );
                          },
                          title: AppLocalizations.of(context)!.download),
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
              }
            },
          ),
        ],
      ),
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.zero,
        centerTitle: true,
        title: AppBar(
          automaticallyImplyLeading: false,
          flexibleSpace: Opacity(
            opacity:
                MediaQuery.of(context).size.height / 2 <= scrollControllerOffset
                    ? 1
                    : scrollControllerOffset /
                        (MediaQuery.of(context).size.height / 2),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 10,
                sigmaY: 10,
              ),
              child: Container(),
            ),
          ),
        ),
        background: Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width - 60,
            height: MediaQuery.of(context).size.width - 60,
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
    );
  }
}
