import 'package:spotify_api/spotify_api.dart' as sp;
import 'package:pongo/exports.dart';

class RecommendedPongoPhone extends StatelessWidget {
  final List<sp.Track> pTracks;
  final List<Artist> pArtists;
  final List<Album> pAlbums;
  final List<Playlist> pPlaylists;
  final List<sp.Track> euTracks;
  final List<Artist> euArtists;
  final List<String> pTrackLoading;
  final TextStyle suggestionHeader;
  final AudioServiceHandler audioServiceHandler;
  final Function(String) loadingAdd;
  final Function(String) loadingRemove;
  const RecommendedPongoPhone({
    super.key,
    required this.pTracks,
    required this.pArtists,
    required this.pAlbums,
    required this.pPlaylists,
    required this.euTracks,
    required this.euArtists,
    required this.pTrackLoading,
    required this.suggestionHeader,
    required this.audioServiceHandler,
    required this.loadingAdd,
    required this.loadingRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (pTracks.isNotEmpty && (euArtists.isNotEmpty || euTracks.isNotEmpty))
          razh(30),
        if (pTracks.isNotEmpty)
          searchResultText(
              AppLocalizations.of(context)!.tracks, suggestionHeader),
        if (pTracks.isNotEmpty) razh(10),
        if (pTracks.isNotEmpty)
          SizedBox(
            height: 160,
            width: MediaQuery.of(context).size.width,
            child: ListView.builder(
              padding: const EdgeInsets.only(left: 10, right: 10),
              itemCount: pTracks.length > 25 ? 25 : pTracks.length,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                return RecommendedTile(
                  data: pTracks[index],
                  showLoading: pTrackLoading.contains(pTracks[index].id),
                  type: TileType.track,
                  onTap: () async {
                    await Play().onlineTrack(
                        context,
                        audioServiceHandler,
                        "recommended.single.",
                        pTracks[index],
                        loadingAdd,
                        loadingRemove);
                  },
                  doesNotExist: loadingAdd,
                  doesNowExist: loadingRemove,
                  trailing: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: pTrackLoading.contains(pTracks[index].id)
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

                              return id == pTracks[index].id
                                  ? StreamBuilder(
                                      stream: audioServiceHandler
                                          .audioPlayer.playingStream,
                                      builder: (context, playingStream) {
                                        return Trailing(
                                          show: !pTrackLoading
                                              .contains(pTracks[index].id),
                                          showThis: id == pTracks[index].id,
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
        if (pTracks.isNotEmpty) razh(10),
        if (pTracks.isNotEmpty)
          SizedBox(
            height: 160,
            width: MediaQuery.of(context).size.width,
            child: ListView.builder(
              padding: const EdgeInsets.only(left: 10, right: 10),
              itemCount: pTracks.length - 25 > 0 ? pTracks.length - 25 : 0,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                return RecommendedTile(
                  data: pTracks[25 + index],
                  showLoading: pTrackLoading.contains(pTracks[25 + index].id),
                  type: TileType.track,
                  onTap: () async {
                    await Play().onlineTrack(
                        context,
                        audioServiceHandler,
                        "recommended.single.",
                        pTracks[25 + index],
                        loadingAdd,
                        loadingRemove);
                  },
                  doesNotExist: loadingAdd,
                  doesNowExist: loadingRemove,
                  trailing: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: pTrackLoading.contains(pTracks[25 + index].id)
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

                              return id == pTracks[25 + index].id
                                  ? StreamBuilder(
                                      stream: audioServiceHandler
                                          .audioPlayer.playingStream,
                                      builder: (context, playingStream) {
                                        return Trailing(
                                          show: !pTrackLoading
                                              .contains(pTracks[25 + index].id),
                                          showThis:
                                              id == pTracks[25 + index].id,
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
        if (pArtists.isNotEmpty &&
            (euArtists.isNotEmpty || euTracks.isNotEmpty || pTracks.isNotEmpty))
          razh(30),
        if (pArtists.isNotEmpty)
          searchResultText(
              AppLocalizations.of(context)!.artists, suggestionHeader),
        if (pArtists.isNotEmpty) razh(10),
        if (pArtists.isNotEmpty)
          SizedBox(
            height: 160,
            width: MediaQuery.of(context).size.width,
            child: ListView.builder(
              padding: const EdgeInsets.only(left: 10, right: 10),
              itemCount: pArtists.length >= 30 ? 30 : pArtists.length,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                return RecommendedTile(
                  data: pArtists[index],
                  type: TileType.artist,
                  showLoading: false,
                  onTap: () {
                    Navigations().nextScreen(
                        context,
                        ArtistPhone(
                          context: context,
                          artist: pArtists[index],
                        ));
                  },
                );
              },
            ),
          ),
        if (pAlbums.isNotEmpty &&
            (euArtists.isNotEmpty ||
                euTracks.isNotEmpty ||
                pTracks.isNotEmpty ||
                pArtists.isNotEmpty))
          razh(30),
        if (pAlbums.isNotEmpty)
          searchResultText(
              AppLocalizations.of(context)!.newalbums, suggestionHeader),
        if (pAlbums.isNotEmpty) razh(10),
        if (pAlbums.isNotEmpty)
          if (pArtists.isNotEmpty)
            SizedBox(
              height: 160,
              width: MediaQuery.of(context).size.width,
              child: ListView.builder(
                padding: const EdgeInsets.only(left: 10, right: 10),
                itemCount: pAlbums.length,
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  return RecommendedTile(
                    data: pAlbums[index],
                    type: TileType.album,
                    showLoading: false,
                    onTap: () {
                      Navigations().nextScreen(
                          context,
                          AlbumPhone(
                            album: pAlbums[index],
                            context: context,
                          ));
                    },
                  );
                },
              ),
            ),
        if (pPlaylists.isNotEmpty &&
            (euArtists.isNotEmpty ||
                euTracks.isNotEmpty ||
                pTracks.isNotEmpty ||
                pArtists.isNotEmpty ||
                pAlbums.isNotEmpty))
          razh(30),
        if (pPlaylists.isNotEmpty)
          searchResultText(
              AppLocalizations.of(context)!.playlists, suggestionHeader),
        if (pPlaylists.isNotEmpty) razh(10),
        if (pPlaylists.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 10),
            child: SizedBox(
              height: 160,
              width: MediaQuery.of(context).size.width,
              child: ListView.builder(
                padding: const EdgeInsets.only(
                  left: 10,
                  right: 10,
                ),
                itemCount: pArtists.length >= 50 ? 50 : pArtists.length,
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  return RecommendedTile(
                    data: pPlaylists[index],
                    type: TileType.playlist,
                    showLoading: false,
                    onTap: () {
                      Navigations().nextScreen(
                          context,
                          PlaylistPhone(
                            playlist: pPlaylists[index],
                            context: context,
                          ));
                    },
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}
