import 'package:pongo/exports.dart';

class RecommendationsForYouPhone extends StatelessWidget {
  final List<Track> pTracks;
  final List<Artist> pArtists;
  final List<Album> pAlbums;
  final List<Playlist> pPlaylists;
  final List<Track> euTracks;
  final List<Artist> euArtists;
  final List<String> pTrackLoading;
  final TextStyle suggestionHeader;
  final AudioServiceHandler audioServiceHandler;
  final Function(String) loadingAdd;
  final Function(String) loadingRemove;
  const RecommendationsForYouPhone({
    super.key,
    required this.pTracks,
    required this.pArtists,
    required this.pAlbums,
    required this.pPlaylists,
    required this.euTracks,
    required this.euArtists,
    required this.suggestionHeader,
    required this.pTrackLoading,
    required this.audioServiceHandler,
    required this.loadingAdd,
    required this.loadingRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (euTracks.isNotEmpty || euArtists.isNotEmpty)
          searchResultText(
              AppLocalizations.of(context).foryou, suggestionHeader),
        if (euTracks.isNotEmpty) razh(10),
        if (euTracks.isNotEmpty)
          SizedBox(
            height: 160,
            width: MediaQuery.of(context).size.width,
            child: ListView.builder(
              padding: const EdgeInsets.only(left: 10, right: 10),
              itemCount: euTracks.length > 25 ? 25 : euTracks.length,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                return RecommendedTile(
                  data: euTracks[index],
                  showLoading: pTrackLoading.contains(euTracks[index].id),
                  type: TileType.track,
                  onTap: () async {
                    await PlaySingle().onlineTrack(
                      context,
                      audioServiceHandler,
                      "recommended.single.",
                      euTracks[index],
                      loadingAdd,
                      loadingRemove,
                    );
                  },
                  doesNotExist: loadingAdd,
                  doesNowExist: loadingRemove,
                  trailing: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: pTrackLoading.contains(euTracks[index].id)
                        ? const CircularProgressIndicator.adaptive(
                            key: ValueKey(true),
                          )
                        : StreamBuilder(
                            key: const ValueKey(false),
                            stream: audioServiceHandler.mediaItem.stream,
                            builder: (context, snapshot) {
                              final String id = snapshot.data != null
                                  ? snapshot.data!.id.split(".")[2]
                                  : "";

                              return id == euTracks[index].id
                                  ? StreamBuilder(
                                      stream: audioServiceHandler
                                          .audioPlayer.playingStream,
                                      builder: (context, playingStream) {
                                        return Trailing(
                                          forceWhite: false,
                                          show: !pTrackLoading
                                              .contains(euTracks[index].id),
                                          showThis: id == euTracks[index].id,
                                          trailing: const Padding(
                                            padding: EdgeInsets.only(right: 10),
                                            child: CircularProgressIndicator
                                                .adaptive(
                                              key: ValueKey(true),
                                            ),
                                          ),
                                        );
                                      })
                                  : const SizedBox();
                            },
                          ),
                  ),
                );
              },
            ),
          ),
        if (euTracks.isNotEmpty && euTracks.length > 25) razh(10),
        if (euTracks.isNotEmpty)
          SizedBox(
            height: 160,
            width: MediaQuery.of(context).size.width,
            child: ListView.builder(
              padding: const EdgeInsets.only(left: 10, right: 10),
              itemCount: euTracks.length - 25 > 0 ? euTracks.length - 25 : 0,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                return RecommendedTile(
                  data: euTracks[25 + index],
                  showLoading: pTrackLoading.contains(euTracks[25 + index].id),
                  type: TileType.track,
                  onTap: () async {
                    await PlaySingle().onlineTrack(
                        context,
                        audioServiceHandler,
                        "recommended.single.",
                        euTracks[25 + index],
                        loadingAdd,
                        loadingRemove);
                  },
                  doesNotExist: loadingAdd,
                  doesNowExist: loadingRemove,
                  trailing: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: pTrackLoading.contains(euTracks[25 + index].id)
                        ? const CircularProgressIndicator.adaptive(
                            key: ValueKey(true),
                          )
                        : StreamBuilder(
                            key: const ValueKey(false),
                            stream: audioServiceHandler.mediaItem.stream,
                            builder: (context, snapshot) {
                              final String id = snapshot.data != null
                                  ? snapshot.data!.id.split(".")[2]
                                  : "";

                              return id == euTracks[25 + index].id
                                  ? StreamBuilder(
                                      stream: audioServiceHandler
                                          .audioPlayer.playingStream,
                                      builder: (context, playingStream) {
                                        return Trailing(
                                          forceWhite: false,
                                          show: !pTrackLoading.contains(
                                              euTracks[25 + index].id),
                                          showThis:
                                              id == euTracks[25 + index].id,
                                          trailing: const Padding(
                                            padding: EdgeInsets.only(right: 10),
                                            child: CircularProgressIndicator
                                                .adaptive(
                                              key: ValueKey(true),
                                            ),
                                          ),
                                        );
                                      })
                                  : const SizedBox();
                            },
                          ),
                  ),
                );
              },
            ),
          ),
        if (euArtists.isNotEmpty && euTracks.isNotEmpty) razh(30),
        if (euArtists.isNotEmpty)
          SizedBox(
            height: 160,
            width: MediaQuery.of(context).size.width,
            child: ListView.builder(
              padding: const EdgeInsets.only(left: 10, right: 10),
              itemCount: euArtists.length >= 30 ? 30 : euArtists.length,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                return RecommendedTile(
                  data: euArtists[index],
                  type: TileType.artist,
                  showLoading: false,
                  onTap: () {
                    Navigations().nextScreen(
                        context,
                        ArtistPhone(
                          context: context,
                          artist: euArtists[index],
                        ));
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}
