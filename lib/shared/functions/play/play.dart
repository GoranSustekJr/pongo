import 'package:pongo/exports.dart';
import 'package:pongo/shared/utils/API%20requests/queue_add_multiple.dart';

class PlaySingle {
  Future<void> onlineTrack(
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
                    id: track.album!.id,
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

class PlayMultiple {
  Future<void> onlineTrack(
    String baseId,
    List<Track> tracks,
    List<String> missingTracks,
    Map<String, double> existingTracks,
    Function(String) addLoading,
    Function(String) removeLoading,
    Function(String, double) addDuration, {
    int? index,
    bool shuffle = false,
    bool online = true,
  }) async {
    final audioServiceHandler =
        Provider.of<AudioHandler>(mainContext.value!, listen: false)
            as AudioServiceHandler;

    if (missingTracks.isNotEmpty) {
      print("not empty");
      // Disable ability to shuffle
      queueAllowShuffle.value = false;

      // Halt current playback
      await audioServiceHandler.halt();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Add tracks with the check if they exist
        QueueAddMultiple().add(
            audioServiceHandler,
            baseId,
            tracks,
            missingTracks,
            existingTracks,
            addLoading,
            removeLoading,
            addDuration);
      });
    } else {
      // All songs already exist
      final List<MediaItem> mediaItems = [];

      // Add each track as a MediaItem
      for (int i = 0; i < tracks.length; i++) {
        final MediaItem mediaItem = MediaItem(
          id: "$baseId.${tracks[i].id}",
          title: tracks[i].name,
          artist: tracks[i].artists.map((artist) => artist.name).join(', '),
          album: tracks[i].album != null
              ? "${tracks[i].album!.id}..Ææ..${tracks[i].album!.name}"
              : "..Ææ..",
          duration: Duration(
              milliseconds: (existingTracks[tracks[i].id]! * 1000).toInt()),
          artUri: Uri.parse(
            tracks[i].album != null
                ? calculateBestImageForTrack(tracks[i].album!.images)
                : '',
          ),
          extras: {
            "online": online,
            "released":
                tracks[i].album != null ? tracks[i].album!.releaseDate : "",
          },
        );
        mediaItems.add(mediaItem);
      }

      // Start the queue
      await audioServiceHandler.initSongs(
          songs: mediaItems); // Init the MediaItems

      if (index != null || shuffle) {
        await audioServiceHandler.skipToQueueItem(index ??
            audioServiceHandler.audioPlayer
                .shuffleIndices![0]); // Skip to the wanted index in the queue
      }

      audioServiceHandler.play(); // Play

      queueAllowShuffle.value = true;

      if (shuffle) {
        await audioServiceHandler.setShuffleMode(AudioServiceShuffleMode.all);
      }
    }
  }
}
