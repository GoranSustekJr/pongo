import 'package:pongo/exports.dart';
import 'package:spotify_api/spotify_api.dart' as sp;

class TrackPlay {
  Future<void> playSingle(
    context,
    Track track,
    String id,
    Function(String) addLoading,
    Function(String) removeLoading,
    Function(MediaItem) play,
  ) async {
    // Use a Completer to ensure the function completes only when all async operations are done
    final completer = Completer<void>();

    await TrackMetadata().checkTrackExists(
      context,
      track.id,
      addLoading,
      removeLoading,
      (duration) async {
        UriAudioSource source = AudioSource.uri(
          Uri.parse("${AppConstants.SERVER_URL}play_song/${track.id}"),
          tag: MediaItem(
            id: "$id${track.id}",
            title: track.name,
            artist: track.artists.map((artist) => artist.name).join(', '),
            album: track.album != null
                ? "${track.album!.id}..Ææ..${track.album!.name}"
                : "..Ææ..",
            duration: Duration(milliseconds: (duration * 1000).toInt()),
            artUri: track.album != null
                ? Uri.parse(calculateBestImageForTrack(track.album!.images))
                : null,
            extras: {
              "artists": jsonEncode(track.artists
                  .map((artist) => {"id": artist.id, "name": artist.name})
                  .toList()),
              "released": track.album != null ? track.album!.releaseDate : "",
            },
          ),
        );

        // if stil this album playling or a single
        if (id.split('.')[1] == "single") {
          // Play the track using the mediaItem created from the source
          play(source.tag as MediaItem);
        } else if (currentAlbumPlaylistId.value != "") {
          if (currentAlbumPlaylistId.value.split('.')[1] == id.split('.')[1] ||
              currentAlbumPlaylistId.value == id.split('.')[1]) {
            // Play the track using the mediaItem created from the source
            play(source.tag as MediaItem);
          }
        }

        // Once everything is done, complete the completer
        completer.complete();
      },
      //   ); //TODO: Disabled
      //   },
    );

    // Return the future, ensuring it completes when all async work inside is done
    return completer.future;
  }

  Future<void> playAlreadyExists(
    context,
    Track track,
    String id,
    int i,
    Map<String, double> existingTracks,
    Function(MediaItem, int) play,
  ) async {
    UriAudioSource source = AudioSource.uri(
      Uri.parse("${AppConstants.SERVER_URL}play_song/${track.id}"),
      tag: MediaItem(
        id: "$id${track.id}",
        title: track.name,
        artist: track.artists.map((artist) => artist.name).join(', '),
        album: track.album != null
            ? "${track.album!.id}..Ææ..${track.album!.name}"
            : "..Ææ..",
        duration:
            Duration(milliseconds: (existingTracks[track.id]! * 1000).toInt()),
        artUri: track.album != null
            ? Uri.parse(calculateBestImageForTrack(track.album!.images))
            : null,
        extras: {
          "artists": jsonEncode(track.artists
              .map((artist) => {"id": artist.id, "name": artist.name})
              .toList()),
          "released": track.album != null ? track.album!.releaseDate : "",
          "salid": track.album != null ? track.album!.id : "",
        },
      ),
    );
    await play(source.tag as MediaItem, i);
  }

  Future<void> playConcenating(
    context,
    List<Track> tracks,
    Map<String, double> existingTracks,
    String id,
    bool cancel,
    Function(String) addLoading,
    Function(String) removeLoading,
    Function(MediaItem, int i) play,
  ) async {
    for (int i = 0; i < tracks.length; i++) {
      // Await playSingle to fully complete before moving to the next track
      if (!cancel) {
        if (!existingTracks.containsKey(tracks[i].id)) {
          await playSingle(
            context,
            tracks[i],
            id,
            addLoading,
            removeLoading,
            (mediaItem) async {
              play(mediaItem, i);
            },
          );
        } else {
          await playAlreadyExists(
            context,
            tracks[i],
            id,
            i,
            existingTracks,
            play,
          );
        }
      } else {
        break;
      }
    }
  }

  Future<void> playSingleTrack(
    context,
    sp.Track track,
    String id,
    Function(String) addLoading,
    Function(String) removeLoading,
    Function(MediaItem) play,
  ) async {
    // Use a Completer to ensure the function completes only when all async operations are done
    final completer = Completer<void>();

    await TrackMetadata().checkTrackExists(
      context,
      track.id,
      addLoading,
      removeLoading,
      (duration) async {
        UriAudioSource source = AudioSource.uri(
          Uri.parse("${AppConstants.SERVER_URL}play_song/${track.id}"),
          tag: MediaItem(
            id: "$id${track.id}",
            title: track.name,
            artist: track.artists.map((artist) => artist.name).join(', '),
            album: track.album != null
                ? "${track.album!.id}..Ææ..${track.album!.name}"
                : "..Ææ..",
            duration: Duration(milliseconds: (duration * 1000).toInt()),
            artUri: track.album != null
                ? Uri.parse(calculateBestImageForTrack(track.album!.images))
                : null,
            extras: {
              "artists": jsonEncode(track.artists
                  .map((artist) => {"id": artist.id, "name": artist.name})
                  .toList()),
              "released": track.album != null ? track.album!.releaseDate : "",
            },
          ),
        );

        // if stil this album playling
        if (currentAlbumPlaylistId.value == id.split('.')[1] ||
            id.split('.')[1] == "single") {
          // Play the track using the mediaItem created from the source
          play(source.tag as MediaItem);
        }

        // Once everything is done, complete the completer
        completer.complete();
      },
      //   );
      //   },
    );

    // Return the future, ensuring it completes when all async work inside is done
    return completer.future;
  }

  Future<void> playAlreadyExistsTrack(
    context,
    sp.Track track,
    String id,
    int i,
    Map<String, double> existingTracks,
    Function(MediaItem, int) play,
  ) async {
    UriAudioSource source = AudioSource.uri(
      Uri.parse("${AppConstants.SERVER_URL}play_song/${track.id}"),
      tag: MediaItem(
        id: "$id${track.id}",
        title: track.name,
        artist: track.artists.map((artist) => artist.name).join(', '),
        album: track.album != null
            ? "${track.album!.id}..Ææ..${track.album!.name}"
            : "..Ææ..",
        duration:
            Duration(milliseconds: (existingTracks[track.id]! * 1000).toInt()),
        artUri: track.album != null
            ? Uri.parse(calculateBestImageForTrack(track.album!.images))
            : null,
        extras: {
          "artists": jsonEncode(track.artists
              .map((artist) => {"id": artist.id, "name": artist.name})
              .toList()),
          "released": track.album != null ? track.album!.releaseDate : "",
          "salid": track.album != null ? track.album!.id : "",
        },
      ),
    );
    await play(source.tag as MediaItem, i);
  }

  Future<void> playConcenatingTrack(
      context,
      List<sp.Track> tracks,
      Map<String, double> existingTracks,
      String id,
      bool cancel,
      Function(String) addLoading,
      Function(String) removeLoading,
      Function(MediaItem, int i) play,
      {bool setPlay = true}) async {
    for (int i = 0; i < tracks.length; i++) {
      // Await playSingle to fully complete before moving to the next track
      if (!cancel) {
        if (!existingTracks.containsKey(tracks[i].id)) {
          await playSingleTrack(
            context,
            tracks[i],
            id,
            addLoading,
            removeLoading,
            (mediaItem) async {
              play(mediaItem, i);
            },
          );
        } else {
          await playAlreadyExistsTrack(
            context,
            tracks[i],
            id,
            i,
            existingTracks,
            play,
          );
        }
      } else {
        break;
      }
    }
  }
}
