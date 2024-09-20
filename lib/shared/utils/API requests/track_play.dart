import 'package:pongo/exports.dart';
import 'package:pongo/shared/utils/API%20requests/track_metadata.dart';

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
          ),
        );

        // Play the track using the mediaItem created from the source
        play(source.tag as MediaItem);

        // Once everything is done, complete the completer
        completer.complete();
      },
      //   );
      //   },
    );

    // Return the future, ensuring it completes when all async work inside is done
    return completer.future;
  }

  Future<void> playConcenating(
    context,
    String spid,
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
          print("STARTED; $i");
          UriAudioSource source = AudioSource.uri(
            Uri.parse("${AppConstants.SERVER_URL}play_song/${tracks[i].id}"),
            tag: MediaItem(
              id: "$id${tracks[i].id}",
              title: tracks[i].name,
              artist: tracks[i].artists.map((artist) => artist.name).join(', '),
              album: tracks[i].album != null ? tracks[i].album!.name : "",
              duration: Duration(
                  milliseconds: (existingTracks[tracks[i].id]! * 1000).toInt()),
              artUri: Uri.parse(
                tracks[i].album != null
                    ? calculateBestImageForTrack(tracks[i].album!.images)
                    : '',
              ),
              extras: {
                "released":
                    tracks[i].album != null ? tracks[i].album!.releaseDate : "",
              },
            ),
          );
          print("GOING; $i");
          play(source.tag as MediaItem, i);
        }
      } else {
        break;
      }
    }
  }
}
