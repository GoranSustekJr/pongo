import 'package:pongo/exports.dart';
import 'package:pongo/shared/models/media_item.dart';

class Mix {
  // Get mix endpoints

  getMix(context, Track track) async {
    // Init the audioServiceHandler
    final audioServiceHandler =
        Provider.of<AudioHandler>(context, listen: false)
            as AudioServiceHandler;

    // Init websocket connection
    final WebSocketChannel channel = WebSocketChannel.connect(Uri.parse(
        "${AppConstants.SERVER_URL_WSS}cfc14e13ca191618a06bd94dd5976fccae585e36b3f651b467947288afb51ea8"));
    final accessTokenHandler = Provider.of<AccessToken>(context, listen: false);

    // Send the stid
    channel.sink.add(json.encode({
      "stid": track.id,
      "at+JWT": accessTokenHandler.accessToken,
    }));

    int i = 0;

    channel.stream.listen((message) async {
      i++;
      var response = json.decode(message);

      // Create a media item
      MediaItem mediaItem = MediaItemObject().create(
        "online.mix.${response["ytvid"]}",
        "Mix #$i - ${track.name}",
        track,
        Duration(milliseconds: (response["duration"]! * 1000).toInt()),
        mix: true,
      );

      // Extract video data and add to queue
      changeTrackOnTap.value = false;
      audioServiceHandler.queue.value.add(mediaItem);
      await audioServiceHandler.playlist
          .add(audioServiceHandler.createAudioSource(mediaItem));
    });
  }
}
