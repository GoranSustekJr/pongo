import 'package:flutter/cupertino.dart';
import 'package:pongo/exports.dart';

class SearchBodyPhone extends StatelessWidget {
  final List<Track> tracks;
  final List<Artist> artists;
  final List<Album> albums;
  final List<Playlist> playlists;
  final List<String> loading;
  final ScrollController scrollController;
  final TextStyle suggestionHeader;
  final Function(String) loadingAdd;
  final Function(String) loadingRemove;

  const SearchBodyPhone({
    super.key,
    required this.tracks,
    required this.artists,
    required this.albums,
    required this.playlists,
    required this.loading,
    required this.scrollController,
    required this.suggestionHeader,
    required this.loadingAdd,
    required this.loadingRemove,
  });

  @override
  Widget build(BuildContext context) {
    final audioServiceHandler =
        Provider.of<AudioHandler>(context, listen: true) as AudioServiceHandler;
    return Scrollbar(
      controller: scrollController,
      child: SingleChildScrollView(
        key: const ValueKey(false),
        controller: scrollController,
        child: Padding(
          padding: EdgeInsets.only(
            top: Scaffold.of(context).appBarMaxHeight == null
                ? MediaQuery.of(context).padding.top +
                    AppBar().preferredSize.height +
                    20
                : Scaffold.of(context).appBarMaxHeight! + 20,
            bottom: MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (artists.isNotEmpty && numberOfSearchArtists.value > 0)
                searchResultText(
                    AppLocalizations.of(context).artists, suggestionHeader),
              if (artists.isNotEmpty && numberOfSearchArtists.value > 0)
                razh(10),
              if (artists.isNotEmpty && numberOfSearchArtists.value > 0)
                ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: artists.length > numberOfSearchArtists.value
                      ? numberOfSearchArtists.value
                      : artists.length,
                  shrinkWrap: true,
                  addAutomaticKeepAlives: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    return SearchResultTile(
                      key: ValueKey("artist.${artists[index].id}"),
                      pushWhite: false,
                      data: artists[index],
                      type: TileType.artist,
                      onTap: () {
                        Navigations().nextScreen(
                            context,
                            ArtistPhone(
                              context: context,
                              artist: artists[index],
                            ));
                      },
                    );
                  },
                ),
              if (artists.isNotEmpty && numberOfSearchArtists.value > 0)
                razh(50),
              if (albums.isNotEmpty && numberOfSearchAlbums.value > 0)
                searchResultText(
                    AppLocalizations.of(context).albums, suggestionHeader),
              if (albums.isNotEmpty && numberOfSearchAlbums.value > 0) razh(10),
              if (albums.isNotEmpty && numberOfSearchAlbums.value > 0)
                ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: albums.length > numberOfSearchAlbums.value
                      ? numberOfSearchAlbums.value
                      : albums.length,
                  shrinkWrap: true,
                  addAutomaticKeepAlives: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    return SearchResultTile(
                      key: ValueKey("album.${albums[index].id}"),
                      pushWhite: false,
                      data: albums[index],
                      type: TileType.album,
                      onTap: () {
                        Navigations().nextScreen(
                            context,
                            AlbumPhone(
                              album: albums[index],
                              context: context,
                            ));
                      },
                    );
                  },
                ),
              if (albums.isNotEmpty && numberOfSearchAlbums.value > 0) razh(50),
              if (tracks.isNotEmpty && numberOfSearchTracks.value > 0)
                searchResultText(
                    AppLocalizations.of(context).tracks, suggestionHeader),
              if (tracks.isNotEmpty && numberOfSearchTracks.value > 0) razh(10),
              if (tracks.isNotEmpty && numberOfSearchTracks.value > 0)
                ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: tracks.length > numberOfSearchTracks.value
                      ? numberOfSearchTracks.value
                      : tracks.length,
                  shrinkWrap: true,
                  addAutomaticKeepAlives: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    return SearchResultTile(
                      key: ValueKey("track.${tracks[index].id}"),
                      pushWhite: false,
                      data: tracks[index],
                      type: TileType.track,
                      trailing: Row(
                        children: [
                          SizedBox(
                            height: 40,
                            width: 20,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: loading.contains(tracks[index].id)
                                  ? const CircularProgressIndicator.adaptive(
                                      key: ValueKey(true),
                                    )
                                  : StreamBuilder(
                                      key: const ValueKey(false),
                                      stream:
                                          audioServiceHandler.mediaItem.stream,
                                      builder: (context, snapshot) {
                                        final String id = snapshot.data != null
                                            ? snapshot.data!.id.split(".")[2]
                                            : "";

                                        return id == tracks[index].id
                                            ? StreamBuilder(
                                                stream: audioServiceHandler
                                                    .audioPlayer.playingStream,
                                                builder:
                                                    (context, playingStream) {
                                                  return Trailing(
                                                    forceWhite: false,
                                                    show: !loading.contains(
                                                        tracks[index].id),
                                                    showThis:
                                                        id == tracks[index].id,
                                                    trailing: const Padding(
                                                      padding: EdgeInsets.only(
                                                          right: 10),
                                                      child:
                                                          CircularProgressIndicator
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
                          ),
                          FutureBuilder<bool>(
                            future: DatabaseHelper()
                                .favouriteTrackAlreadyExists(tracks[index].id),
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return const SizedBox(
                                  width: 50,
                                  height: 20,
                                  child: Center(
                                      child: Icon(CupertinoIcons
                                          .exclamationmark_circle)),
                                );
                              } else {
                                bool isFavourite = snapshot.data ?? false;

                                return SizedBox(
                                  width: 50,
                                  height: 50,
                                  child: PullDownButton(
                                    offset: const Offset(30, 30),
                                    position: PullDownMenuPosition.automatic,
                                    itemBuilder: (context) =>
                                        searchTrackPulldownMenuItemsApple(
                                      //TODO: Android
                                      context,
                                      tracks[index],
                                      "search.single.",
                                      isFavourite,
                                      loadingAdd,
                                      loadingRemove,
                                    ),
                                    buttonBuilder: (context, showMenu) =>
                                        CupertinoButton(
                                      onPressed: showMenu,
                                      padding: EdgeInsets.zero,
                                      child: Icon(
                                        CupertinoIcons.ellipsis,
                                        color: Col.icon,
                                      ),
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                      onTap: () async {
                        await PlaySingle().onlineTrack(
                          context,
                          audioServiceHandler,
                          "search.single.",
                          tracks[index],
                          loadingAdd,
                          loadingRemove,
                        );

                        if (useMix.value) {
                          Mix().getMix(context, tracks[index]);
                        }
                      },
                    );
                  },
                ),
              if (tracks.isNotEmpty && numberOfSearchTracks.value > 0) razh(50),
              if (playlists.isNotEmpty && numberOfSearchPlaylists.value > 0)
                searchResultText(
                    AppLocalizations.of(context).playlists, suggestionHeader),
              if (playlists.isNotEmpty && numberOfSearchPlaylists.value > 0)
                razh(10),
              if (playlists.isNotEmpty && numberOfSearchPlaylists.value > 0)
                ListView.builder(
                  padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).padding.bottom),
                  itemCount: playlists.length > numberOfSearchPlaylists.value
                      ? numberOfSearchPlaylists.value
                      : playlists.length,
                  shrinkWrap: true,
                  addAutomaticKeepAlives: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    return SearchResultTile(
                      key: ValueKey("playlist.${playlists[index].id}"),
                      pushWhite: false,
                      data: playlists[index],
                      type: TileType.playlist,
                      onTap: () {
                        Navigations().nextScreen(
                            context,
                            PlaylistPhone(
                              playlist: playlists[index],
                              context: context,
                            ));
                      },
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
