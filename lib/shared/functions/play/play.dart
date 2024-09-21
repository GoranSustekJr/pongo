import 'package:pongo/exports.dart';
import 'package:spotify_api/spotify_api.dart' as sp;

class Play {
  Future<void> onlineTrack(
      context,
      AudioServiceHandler audioServiceHandler,
      String id,
      sp.Track track,
      Function(String) loadingAdd,
      Function(String) loadingRemove) async {
    final playNew = audioServiceHandler.mediaItem.value != null
        ? audioServiceHandler.mediaItem.value!.id.split(".")[2] != track.id
        : true;
    if (playNew) {
      queueAllowShuffle.value = true;

      TrackPlay().playSingle(
          context,
          Track(
            id: track.id,
            name: track.name,
            artists: track.artists
                .map((artist) => ArtistTrack(id: artist.id, name: artist.name))
                .toList(),
            album: track.album == null
                ? null
                : AlbumTrack(
                    name: track.album!.name,
                    images: track.album!.images
                        .map((image) => AlbumImagesTrack(
                            url: image.url,
                            height: image.height,
                            width: image.width))
                        .toList(),
                    releaseDate: track.album!.releaseDate,
                  ),
          ),
          id,
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
  }

  Future<void> onlineTrackTypteTrack(
      context,
      AudioServiceHandler audioServiceHandler,
      String id,
      Track track,
      Function(String) loadingAdd,
      Function(String) loadingRemove) async {
    final playNew = audioServiceHandler.mediaItem.value != null
        ? audioServiceHandler.mediaItem.value!.id.split(".")[2] != track.id
        : true;
    if (playNew) {
      queueAllowShuffle.value = true;

      TrackPlay().playSingle(
          context,
          Track(
            id: track.id,
            name: track.name,
            artists: track.artists
                .map((artist) => ArtistTrack(id: artist.id, name: artist.name))
                .toList(),
            album: track.album == null
                ? null
                : AlbumTrack(
                    name: track.album!.name,
                    images: track.album!.images
                        .map((image) => AlbumImagesTrack(
                            url: image.url,
                            height: image.height,
                            width: image.width))
                        .toList(),
                    releaseDate: track.album!.releaseDate,
                  ),
          ),
          id,
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
  }
}
