import 'dart:ui';

import 'package:pongo/exports.dart';

class SliverAppBarPhone extends StatelessWidget {
  final String name;
  final List<Track> tracks;
  final String image;
  final double scrollControllerOffset;
  const SliverAppBarPhone(
      {super.key,
      required this.name,
      required this.tracks,
      required this.scrollControllerOffset,
      required this.image});

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
                                .map((artist) => artist.name)
                                .toList()
                                .join(', '),
                            cover: calculateWantedResolutionForTrack(
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
