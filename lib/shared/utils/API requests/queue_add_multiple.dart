import 'package:pongo/exports.dart';

class QueueAddMultiple {
  Future<void> add(
      AudioServiceHandler audioServiceHandler,
      String baseId,
      List<Track> tracks,
      List<String> missingTracks,
      Map<String, double> existingTracks,
      Function(String) addLoading,
      Function(String) removeLoading,
      Function(String, double) addDuration,
      {bool online = true}) async {
    try {
      final WebSocketChannel channel = WebSocketChannel.connect(
          Uri.parse("${AppConstants.SERVER_URL_WSS}concenating_stids"));
      final accessTokenHandler =
          Provider.of<AccessToken>(mainContext.value!, listen: false);

      // Convert the stream to BroadcastStream
      final stream = channel.stream.asBroadcastStream();

      // Send initial data
      channel.sink.add(json.encode({
        "stids": missingTracks.length,
        "at+JWT": accessTokenHandler.accessToken,
      }));

      for (int i = 0; i < tracks.length; i++) {
        if (!missingTracks.contains(tracks[i].id)) {
          // Track already exists

          // Create media item
          final MediaItem mediaItem = MediaItem(
            id: "$baseId.${tracks[i].id}",
            title: tracks[i].name,
            artist: tracks[i].artists.map((artist) => artist.name).join(', '),
            album: tracks[i].album?.name, //TODO: Remove
            duration: Duration(
                milliseconds: (existingTracks[tracks[i].id]! * 1000).toInt()),
            artUri: tracks[i].album != null
                ? Uri.parse(calculateBestImageForTrack(tracks[i].album!.images))
                : null,
            extras: {
              "artists": jsonEncode(tracks[i]
                  .artists
                  .map((artist) => {"id": artist.id, "name": artist.name})
                  .toList()),
              "online": online,
              "released":
                  tracks[i].album != null ? tracks[i].album!.releaseDate : "",
              "album": tracks[i].album != null
                  ? "${tracks[i].album!.id}..Ææ..${tracks[i].album!.name}"
                  : "..Ææ..",
            },
          );

          if (i == 0) {
            // If first, initiate the queue
            await audioServiceHandler.initSongs(songs: [mediaItem]);
            audioServiceHandler.play();
          } else {
            // Add to queue
            audioServiceHandler.queue.value.add(mediaItem);
            await audioServiceHandler.playlist
                .add(audioServiceHandler.createAudioSource(mediaItem));
          }
        } else {
          // Track does not exist
          addLoading(tracks[i].id);

          // Send the stid
          channel.sink.add(json.encode({
            "stid": tracks[i].id,
          }));

          // Wait for the WebSocket response
          final Completer<void> completer = Completer<void>();
          bool isCompleted = false; // Flag to prevent multiple completions

          stream.listen(
            (message) async {
              if (isCompleted) return; // Ignore additional responses
              isCompleted = true;

              var response = json.decode(message);

              double duration = response["duration"];

              // Update state
              removeLoading(tracks[i].id);
              addDuration(tracks[i].id, duration);

              // Create MediaItem and add it to the queue
              final MediaItem mediaItem = MediaItem(
                id: "$baseId.${tracks[i].id}",
                title: tracks[i].name,
                artist:
                    tracks[i].artists.map((artist) => artist.name).join(', '),
                album: tracks[i].album?.name, //TODO: Remove
                duration: Duration(milliseconds: (duration * 1000).toInt()),
                artUri: tracks[i].album != null
                    ? Uri.parse(
                        calculateBestImageForTrack(tracks[i].album!.images))
                    : null,
                extras: {
                  "artists": jsonEncode(tracks[i]
                      .artists
                      .map((artist) => {"id": artist.id, "name": artist.name})
                      .toList()),
                  "online": online,
                  "released": tracks[i].album != null
                      ? tracks[i].album!.releaseDate
                      : "",
                  "album": tracks[i].album != null
                      ? "${tracks[i].album!.id}..Ææ..${tracks[i].album!.name}"
                      : "..Ææ..",
                },
              );

              if (i == 0) {
                // If first, initiate the queue
                await audioServiceHandler.initSongs(songs: [mediaItem]);
                audioServiceHandler.play();
              } else {
                // Add to queue
                audioServiceHandler.queue.value.add(mediaItem);
                await audioServiceHandler.playlist
                    .add(audioServiceHandler.createAudioSource(mediaItem));
              }

              // Complete the completer
              completer.complete();
            },
            onError: (error) async {
              if (!isCompleted) {
                isCompleted = true;
                completer.completeError(error);
              }
            },
          );

          // Wait for the WebSocket response to complete
          await completer.future;
        }
      }

      queueAllowShuffle.value = true;
    } catch (e) {
      // print(e);
    }
  }
}
// TODO: Disabled
