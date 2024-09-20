import 'package:spotify_api/spotify_api.dart' as sp;
import 'package:pongo/exports.dart';

class RecommendationsForYouPhone extends StatelessWidget {
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
              AppLocalizations.of(context)!.foryou, suggestionHeader),
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
                    final playNew = audioServiceHandler.mediaItem.value != null
                        ? audioServiceHandler.mediaItem.value!.id
                                .split(".")[2] !=
                            euTracks[index].id
                        : true;
                    if (playNew) {
                      TrackPlay().playSingle(
                          context,
                          Track(
                            id: euTracks[index].id,
                            name: euTracks[index].name,
                            artists: euTracks[index]
                                .artists
                                .map((artist) => ArtistTrack(
                                    id: artist.id, name: artist.name))
                                .toList(),
                            album: euTracks[index].album == null
                                ? null
                                : AlbumTrack(
                                    name: euTracks[index].album!.name,
                                    images: euTracks[index]
                                        .album!
                                        .images
                                        .map((image) => AlbumImagesTrack(
                                            url: image.url,
                                            height: image.height,
                                            width: image.width))
                                        .toList(),
                                    releaseDate:
                                        euTracks[index].album!.releaseDate,
                                  ),
                          ),
                          "recommended.single.",
                          loadingAdd,
                          loadingRemove, (mediaItem) async {
                        final audioServiceHandler =
                            Provider.of<AudioHandler>(context, listen: false)
                                as AudioServiceHandler;
                        await audioServiceHandler.initSongs(songs: [mediaItem]);
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
                    final playNew = audioServiceHandler.mediaItem.value != null
                        ? audioServiceHandler.mediaItem.value!.id
                                .split(".")[2] !=
                            euTracks[25 + index].id
                        : true;
                    if (playNew) {
                      TrackPlay().playSingle(
                          context,
                          Track(
                            id: euTracks[25 + index].id,
                            name: euTracks[25 + index].name,
                            artists: euTracks[25 + index]
                                .artists
                                .map((artist) => ArtistTrack(
                                    id: artist.id, name: artist.name))
                                .toList(),
                            album: euTracks[25 + index].album == null
                                ? null
                                : AlbumTrack(
                                    name: euTracks[25 + index].album!.name,
                                    images: euTracks[25 + index]
                                        .album!
                                        .images
                                        .map((image) => AlbumImagesTrack(
                                            url: image.url,
                                            height: image.height,
                                            width: image.width))
                                        .toList(),
                                    releaseDate:
                                        euTracks[25 + index].album!.releaseDate,
                                  ),
                          ),
                          "recommended.single.",
                          loadingAdd,
                          loadingRemove, (mediaItem) async {
                        final audioServiceHandler =
                            Provider.of<AudioHandler>(context, listen: false)
                                as AudioServiceHandler;
                        await audioServiceHandler.initSongs(songs: [mediaItem]);
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
