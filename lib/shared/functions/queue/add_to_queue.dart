import 'package:pongo/exports.dart';
import 'package:spotify_api/spotify_api.dart' as sp;

class AddToQueue {
  // Add type spotify track
  Future<void> addLast(
    context,
    sp.Track track,
    String id,
    Function(String) doesNotExist,
    Function(String) doesNowExist,
  ) async {
    final audioServiceHandler =
        Provider.of<AudioHandler>(context, listen: false)
            as AudioServiceHandler;
    final duration = await TrackMetadata().getDuration(context, track.id);

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
            album: track.album?.name, //TODO: Remove
            duration: Duration(milliseconds: (duration * 1000).toInt()),
            artUri: track.album != null
                ? Uri.parse(calculateBestImageForTrack(track.album!.images))
                : null,
            extras: {
              "released": track.album != null ? track.album!.releaseDate : "",
              "album": track.album != null
                  ? "${track.album!.id}..Ææ..${track.album!.name}"
                  : "..Ææ..",
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
        album: track.album?.name, //TODO: Remove
        duration: Duration(milliseconds: (duration["duration"] * 1000).toInt()),
        artUri: track.album != null
            ? Uri.parse(calculateBestImageForTrack(track.album!.images))
            : null,
        extras: {
          "released": track.album != null ? track.album!.releaseDate : "",
          "album": track.album != null
              ? "${track.album!.id}..Ææ..${track.album!.name}"
              : "..Ææ..",
        },
      );
      changeTrackOnTap.value = false;
      audioServiceHandler.queue.value.add(mediaItem);
      await audioServiceHandler.playlist
          .add(audioServiceHandler.createAudioSource(mediaItem));
    }
    shuffleEnabledWarning(context);
  }

  // Add type track
  Future<void> addTypeTrackLast(
    context,
    Track track,
    String id,
    Function(String) doesNotExist,
    Function(String) doesNowExist,
  ) async {
    final audioServiceHandler =
        Provider.of<AudioHandler>(context, listen: false)
            as AudioServiceHandler;
    final duration = await TrackMetadata().getDuration(context, track.id);

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
            album: track.album?.name, //TODO: Remove
            duration: Duration(milliseconds: (duration * 1000).toInt()),
            artUri: track.album != null
                ? Uri.parse(calculateBestImageForTrack(track.album!.images))
                : null,
            extras: {
              "artists": jsonEncode(track.artists
                  .map((artist) => {"id": artist.id, "name": artist.name})
                  .toList()),
              "released": track.album != null ? track.album!.releaseDate : "",
              "album": track.album != null
                  ? "${track.album!.id}..Ææ..${track.album!.name}"
                  : "..Ææ..",
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
        album: track.album?.name, //TODO: Remove
        duration: Duration(milliseconds: (duration["duration"] * 1000).toInt()),
        artUri: track.album != null
            ? Uri.parse(calculateBestImageForTrack(track.album!.images))
            : null,
        extras: {
          "artists": jsonEncode(track.artists
              .map((artist) => {"id": artist.id, "name": artist.name})
              .toList()),
          "released": track.album != null ? track.album!.releaseDate : "",
          "album": track.album != null
              ? "${track.album!.id}..Ææ..${track.album!.name}"
              : "..Ææ..",
        },
      );
      changeTrackOnTap.value = false;
      audioServiceHandler.queue.value.add(mediaItem);
      await audioServiceHandler.playlist
          .add(audioServiceHandler.createAudioSource(mediaItem));
    }
    shuffleEnabledWarning(context);
  }

  Future<void> addFirst(
    context,
    sp.Track track,
    String id,
    Function(String) doesNotExist,
    Function(String) doesNowExist,
  ) async {
    final audioServiceHandler =
        Provider.of<AudioHandler>(context, listen: false)
            as AudioServiceHandler;
    final duration = await TrackMetadata().getDuration(context, track.id);

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
            album: track.album?.name, //TODO: Remove
            duration: Duration(milliseconds: (duration * 1000).toInt()),
            artUri: track.album != null
                ? Uri.parse(calculateBestImageForTrack(track.album!.images))
                : null,
            extras: {
              "artists": jsonEncode(track.artists
                  .map((artist) => {"id": artist.id, "name": artist.name})
                  .toList()),
              "released": track.album != null ? track.album!.releaseDate : "",
              "album": track.album != null
                  ? "${track.album!.id}..Ææ..${track.album!.name}"
                  : "..Ææ..",
            },
          );
          changeTrackOnTap.value = false;
          audioServiceHandler.queue.value.insert(
              audioServiceHandler.audioPlayer.currentIndex != null
                  ? audioServiceHandler.audioPlayer.currentIndex! + 1
                  : 0,
              mediaItem);
          await audioServiceHandler.playlist.insert(
              audioServiceHandler.audioPlayer.currentIndex != null
                  ? audioServiceHandler.audioPlayer.currentIndex! + 1
                  : 0,
              audioServiceHandler.createAudioSource(mediaItem));
        },
      );
    } else {
      MediaItem mediaItem = MediaItem(
        id: "$id${track.id}",
        title: track.name,
        artist: track.artists.map((artist) => artist.name).join(', '),
        album: track.album?.name, //TODO: Remove
        duration: Duration(milliseconds: (duration["duration"] * 1000).toInt()),
        artUri: track.album != null
            ? Uri.parse(calculateBestImageForTrack(track.album!.images))
            : null,
        extras: {
          "artists": jsonEncode(track.artists
              .map((artist) => {"id": artist.id, "name": artist.name})
              .toList()),
          "released": track.album != null ? track.album!.releaseDate : "",
          "album": track.album != null
              ? "${track.album!.id}..Ææ..${track.album!.name}"
              : "..Ææ..",
        },
      );
      changeTrackOnTap.value = false;
      audioServiceHandler.queue.value.insert(
          audioServiceHandler.audioPlayer.currentIndex != null
              ? audioServiceHandler.audioPlayer.currentIndex! + 1
              : 0,
          mediaItem);
      await audioServiceHandler.playlist.insert(
          audioServiceHandler.audioPlayer.currentIndex != null
              ? audioServiceHandler.audioPlayer.currentIndex! + 1
              : 0,
          audioServiceHandler.createAudioSource(mediaItem));
    }
    shuffleEnabledWarning(context);
  }

  // Add type track
  Future<void> addTypeTrackFirst(
    context,
    Track track,
    String id,
    Function(String) doesNotExist,
    Function(String) doesNowExist,
  ) async {
    final audioServiceHandler =
        Provider.of<AudioHandler>(context, listen: false)
            as AudioServiceHandler;
    final duration = await TrackMetadata().getDuration(context, track.id);

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
            album: track.album?.name, //TODO: Remove
            duration: Duration(milliseconds: (duration * 1000).toInt()),
            artUri: track.album != null
                ? Uri.parse(calculateBestImageForTrack(track.album!.images))
                : null,
            extras: {
              "artists": jsonEncode(track.artists
                  .map((artist) => {"id": artist.id, "name": artist.name})
                  .toList()),
              "released": track.album != null ? track.album!.releaseDate : "",
              "album": track.album != null
                  ? "${track.album!.id}..Ææ..${track.album!.name}"
                  : "..Ææ..",
            },
          );
          changeTrackOnTap.value = false;
          audioServiceHandler.queue.value.insert(
              audioServiceHandler.audioPlayer.currentIndex != null
                  ? audioServiceHandler.audioPlayer.currentIndex! + 1
                  : 0,
              mediaItem);
          await audioServiceHandler.playlist.insert(
              audioServiceHandler.audioPlayer.currentIndex != null
                  ? audioServiceHandler.audioPlayer.currentIndex! + 1
                  : 0,
              audioServiceHandler.createAudioSource(mediaItem));
        },
      );
    } else {
      MediaItem mediaItem = MediaItem(
        id: "$id${track.id}",
        title: track.name,
        artist: track.artists.map((artist) => artist.name).join(', '),
        album: track.album?.name, //TODO: Remove
        duration: Duration(milliseconds: (duration["duration"] * 1000).toInt()),
        artUri: track.album != null
            ? Uri.parse(calculateBestImageForTrack(track.album!.images))
            : null,
        extras: {
          "artists": jsonEncode(track.artists
              .map((artist) => {"id": artist.id, "name": artist.name})
              .toList()),
          "released": track.album != null ? track.album!.releaseDate : "",
          "album": track.album != null
              ? "${track.album!.id}..Ææ..${track.album!.name}"
              : "..Ææ..",
        },
      );
      changeTrackOnTap.value = false;
      audioServiceHandler.queue.value.insert(
          audioServiceHandler.audioPlayer.currentIndex != null
              ? audioServiceHandler.audioPlayer.currentIndex! + 1
              : 0,
          mediaItem);
      await audioServiceHandler.playlist.insert(
          audioServiceHandler.audioPlayer.currentIndex != null
              ? audioServiceHandler.audioPlayer.currentIndex! + 1
              : 0,
          audioServiceHandler.createAudioSource(mediaItem));
    }
    shuffleEnabledWarning(context);
  }

  void shuffleEnabledWarning(context) {
    final audioServiceHandler =
        Provider.of<AudioHandler>(context, listen: false)
            as AudioServiceHandler;
    if (audioServiceHandler.audioPlayer.shuffleModeEnabled) {
      Notifications().showWarningNotification(
          context, AppLocalizations.of(context).shufflemodeison);
    }
  }
}
