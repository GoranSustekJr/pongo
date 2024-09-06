import '../../../exports.dart';

class TrackMetadata {
  checkTrackExists(context, String stid, Function(String) doesNotExist,
      Function(String) doesNowExist, Function(double) finished) async {
    // Overlay

    /*  OverlayEntry overlayEntry = overlay(context);
    // Add overlay
    Overlay.of(context).insert(overlayEntry);
 */
    // Init websocket connection
    final WebSocketChannel channel = WebSocketChannel.connect(
        Uri.parse("wss://goransustekdoo.ddns.net:5002/test"));
    final accessTokenHandler = Provider.of<AccessToken>(context, listen: false);

    // Send the stid
    channel.sink.add(json.encode({
      "stid": stid,
      "at+JWT": accessTokenHandler.accessToken,
    }));

    int responseNum = 0;
    bool? exists;

    channel.stream.listen((message) async {
      var response = json.decode(message);
      responseNum += 1;

      print("Response; $response");
      // print(response["exists"]);

      // First response
      if (responseNum == 1) {
        exists = response["exists"] == 'true';

        // If first response returns exists = false, then update UI for adding song
        if (!exists!) {
          // overlayEntry.remove();

          if (response["exists"] == "false") {
            //  print("Exists: $exists; ${response["exists"] == "false"}");
            doesNotExist(stid);
          } else {
            print("HMM");
            await AccessTokenhandler().renew(context);
            return checkSongExistsNoRenewal(
                context, stid, doesNotExist, doesNowExist, finished);
          }
        }
      }

      // Second response
      if (responseNum == 2) {
        if (!exists!) {
          // If it was adding, now it is added
          doesNowExist(stid);
          //return response["duration"];
          finished(response["duration"]);
        } else {
          // TODO: Store all gotten data
          print("AAAAAAAAAAAAAAA");
          finished(response["duration"]);
          // print(response["song_data"]["album"]["name"]);
          //   final trackData = await TrackData().get(context, stid);

          //  newScreen(trackData);
          //  overlayEntry.remove();
          //return response["duration"];
        }
      }
    });
  }

  checkSongExistsNoRenewal(context, String stid, Function(String) doesNotExist,
      Function(String) doesNowExist, Function(double) finished) async {
    // Overlay

    /*  OverlayEntry overlayEntry = overlay(context);
    // Add overlay */
    //  Overlay.of(context).insert(overlayEntry);

    // Init websocket connection
    final WebSocketChannel channel = WebSocketChannel.connect(
        Uri.parse("wss://goransustekdoo.ddns.net:5002/testtest"));
    final accessTokenHandler = Provider.of<AccessToken>(context, listen: false);

    // Send the stid
    channel.sink.add(json.encode({
      "stid": stid,
      "at+JWT": accessTokenHandler.accessToken,
    }));

    int responseNum = 0;
    bool? exists;

    channel.stream.listen((message) async {
      var response = json.decode(message);
      responseNum += 1;

      // First response
      if (responseNum == 1) {
        exists = response["exists"] == 'true';

        // If first response returns exists = false, then update UI for adding song
        if (!exists!) {
          if (response["exists"] == "false") {
            doesNotExist(stid);
          }
        }
      }

      // Second response
      if (responseNum == 2) {
        if (!exists!) {
          finished(response["duration"]);
          // If it was adding, now it is added
          doesNowExist(stid);
          // return response["duration"];
        } else {
          finished(response["duration"]);
          // return response["duration"];
        }
      }
    });
  }
}
