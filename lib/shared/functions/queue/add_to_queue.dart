import 'package:pongo/exports.dart';
import 'package:spotify_api/spotify_api.dart' as sp;

class AddToQueue {
  // Add type spotify track
  Future<void> add(
    context,
    sp.Track track,
    String id,
    Function(String) doesNotExist,
    Function(String) doesNowExist,
  ) async {
    final audioServiceHandler =
        Provider.of<AudioHandler>(context, listen: false)
            as AudioServiceHandler;
    print("add to queue");
    final duration = await TrackMetadata().getDuration(context, track.id);

    print(duration.runtimeType);

    if (duration["duration"] == null) {
      TrackMetadata().checkTrackExists(
        context,
        track.id,
        doesNotExist,
        doesNowExist,
        (duration) async {
          MediaItem mediaItem = MediaItem(
            id: "$id${track.id}",
            title: track.name,
            artist: track.artists.map((artist) => artist.name).join(', '),
            album: track.album != null ? track.album!.name : "",
            duration: Duration(milliseconds: (duration * 1000).toInt()),
            artUri: Uri.parse(
              track.album != null
                  ? calculateBestImageForTrack(track.album!.images)
                  : '',
            ),
            extras: {
              "released": track.album != null ? track.album!.releaseDate : "",
            },
          );
          changeTrackOnTap.value = false;
          audioServiceHandler.queue.value.add(mediaItem);
          await audioServiceHandler.playlist
              .add(audioServiceHandler.createAudioSource(mediaItem));
        },
      );
    } else {
      MediaItem mediaItem = MediaItem(
        id: "$id${track.id}",
        title: track.name,
        artist: track.artists.map((artist) => artist.name).join(', '),
        album: track.album != null ? track.album!.name : "",
        duration: Duration(milliseconds: (duration["duration"] * 1000).toInt()),
        artUri: Uri.parse(
          track.album != null
              ? calculateBestImageForTrack(track.album!.images)
              : '',
        ),
        extras: {
          "released": track.album != null ? track.album!.releaseDate : "",
        },
      );
      changeTrackOnTap.value = false;
      audioServiceHandler.queue.value.add(mediaItem);
      await audioServiceHandler.playlist
          .add(audioServiceHandler.createAudioSource(mediaItem));
    }
  }

  // Add type track
  Future<void> addTypeTrack(
    context,
    Track track,
    String id,
    Function(String) doesNotExist,
    Function(String) doesNowExist,
  ) async {
    final audioServiceHandler =
        Provider.of<AudioHandler>(context, listen: false)
            as AudioServiceHandler;
    print("add to queue");
    final duration = await TrackMetadata().getDuration(context, track.id);

    print(duration.runtimeType);

    if (duration["duration"] == null) {
      TrackMetadata().checkTrackExists(
        context,
        track.id,
        doesNotExist,
        doesNowExist,
        (duration) async {
          MediaItem mediaItem = MediaItem(
            id: "$id${track.id}",
            title: track.name,
            artist: track.artists.map((artist) => artist.name).join(', '),
            album: track.album != null ? track.album!.name : "",
            duration: Duration(milliseconds: (duration * 1000).toInt()),
            artUri: Uri.parse(
              track.album != null
                  ? calculateBestImageForTrack(track.album!.images)
                  : '',
            ),
            extras: {
              "released": track.album != null ? track.album!.releaseDate : "",
            },
          );
          changeTrackOnTap.value = false;
          audioServiceHandler.queue.value.add(mediaItem);
          await audioServiceHandler.playlist
              .add(audioServiceHandler.createAudioSource(mediaItem));
        },
      );
    } else {
      MediaItem mediaItem = MediaItem(
        id: "$id${track.id}",
        title: track.name,
        artist: track.artists.map((artist) => artist.name).join(', '),
        album: track.album != null ? track.album!.name : "",
        duration: Duration(milliseconds: (duration["duration"] * 1000).toInt()),
        artUri: Uri.parse(
          track.album != null
              ? calculateBestImageForTrack(track.album!.images)
              : '',
        ),
        extras: {
          "released": track.album != null ? track.album!.releaseDate : "",
        },
      );
      changeTrackOnTap.value = false;
      audioServiceHandler.queue.value.add(mediaItem);
      await audioServiceHandler.playlist
          .add(audioServiceHandler.createAudioSource(mediaItem));
    }
  }
}
