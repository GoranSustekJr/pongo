import 'package:pongo/exports.dart';
import 'package:pongo/phone/views/album/album_phone.dart';
import 'package:pongo/phone/views/artist/artist_phone.dart';
import 'package:spotify_api/spotify_api.dart' as sp;

class SearchBodyPhone extends StatelessWidget {
  final List<sp.Track> tracks;
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
            // bottom: MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            children: [
              if (artists.isNotEmpty)
                searchResultText(
                    AppLocalizations.of(context)!.artists, suggestionHeader),
              if (artists.isNotEmpty) razh(10),
              if (artists.isNotEmpty)
                ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: artists.length > numberOfSearchArtists.value
                      ? numberOfSearchArtists.value
                      : artists.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    return SearchResultTile(
                      data: artists[index],
                      type: TileType.artist,
                      onTap: () {
                        // TODO: something
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
              if (albums.isNotEmpty) razh(50),
              if (albums.isNotEmpty)
                searchResultText(
                    AppLocalizations.of(context)!.albums, suggestionHeader),
              if (albums.isNotEmpty) razh(10),
              if (albums.isNotEmpty)
                ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: albums.length > numberOfSearchAlbums.value
                      ? numberOfSearchAlbums.value
                      : albums.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    return SearchResultTile(
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
              if (tracks.isNotEmpty) razh(50),
              if (tracks.isNotEmpty)
                searchResultText(
                    AppLocalizations.of(context)!.tracks, suggestionHeader),
              if (tracks.isNotEmpty) razh(10),
              if (tracks.isNotEmpty)
                ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: tracks.length > numberOfSearchTracks.value
                      ? numberOfSearchTracks.value
                      : tracks.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    return SearchResultTile(
                      data: tracks[index],
                      type: TileType.track,
                      trailing: SizedBox(
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
                                  stream: audioServiceHandler.mediaItem.stream,
                                  builder: (context, snapshot) {
                                    final String id = snapshot.data != null
                                        ? snapshot.data!.id.split(".")[2]
                                        : "";

                                    return id == tracks[index].id
                                        ? StreamBuilder(
                                            stream: audioServiceHandler
                                                .audioPlayer.playingStream,
                                            builder: (context, playingStream) {
                                              return SizedBox(
                                                width: 20,
                                                height: 40,
                                                child: MiniMusicVisualizer(
                                                  color: Colors.white,
                                                  radius: 60,
                                                  animate: playingStream.data ??
                                                      false,
                                                ),
                                              );
                                            })
                                        : const SizedBox();
                                  },
                                ),
                        ),
                      ),
                      onTap: () async {
                        final playNew =
                            audioServiceHandler.mediaItem.value != null
                                ? audioServiceHandler.mediaItem.value!.id
                                        .split(".")[2] !=
                                    tracks[index].id
                                : true;
                        if (playNew) {
                          TrackPlay().playSingle(
                              context,
                              Track(
                                id: tracks[index].id,
                                name: tracks[index].name,
                                artists: tracks[index]
                                    .artists
                                    .map((artist) => ArtistTrack(
                                        id: artist.id, name: artist.name))
                                    .toList(),
                                album: tracks[index].album == null
                                    ? null
                                    : AlbumTrack(
                                        name: tracks[index].album!.name,
                                        images: tracks[index]
                                            .album!
                                            .images
                                            .map((image) => AlbumImagesTrack(
                                                url: image.url,
                                                height: image.height,
                                                width: image.width))
                                            .toList(),
                                        releaseDate:
                                            tracks[index].album!.releaseDate,
                                      ),
                              ),
                              "search.single.",
                              loadingAdd,
                              loadingRemove, (mediaItem) async {
                            final audioServiceHandler =
                                Provider.of<AudioHandler>(context,
                                    listen: false) as AudioServiceHandler;
                            await audioServiceHandler
                                .initSongs(songs: [mediaItem]);
                            audioServiceHandler.play();
                          });
                        } else {
                          if (audioServiceHandler.audioPlayer.playing) {
                            await audioServiceHandler.pause();
                          } else {
                            await audioServiceHandler.play();
                          }
                        }
                      },
                    );
                  },
                ),
              if (playlists.isNotEmpty) razh(50),
              if (playlists.isNotEmpty)
                searchResultText(
                    AppLocalizations.of(context)!.playlists, suggestionHeader),
              if (playlists.isNotEmpty) razh(10),
              if (playlists.isNotEmpty)
                ListView.builder(
                  padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).padding.bottom),
                  itemCount: playlists.length > numberOfSearchPlaylists.value
                      ? numberOfSearchPlaylists.value
                      : playlists.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    return SearchResultTile(
                      data: playlists[index],
                      type: TileType.playlist,
                      onTap: () {
                        print(playlists[index].id);
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
