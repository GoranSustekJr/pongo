import '../../../exports.dart';
import 'package:http/http.dart' as http;

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
        Uri.parse("ws://goransustekdoo.ddns.net:9090/test"));
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

  Future getLyrics(context, String name, String artist, double duration,
      String album, Function(Map, double) finished) async {
    try {
      print(1);
      final response = await http.get(
        Uri(
          scheme: 'https',
          host: 'lrclib.net',
          path: '/api/get',
          queryParameters: {
            "artist_name": artist,
            "track_name": name,
            "duration": duration.toString(),
            "album_name": album,
          },
        ),
      );
      print(2);

      if (response.statusCode == 200) {
        //print(jsonDecode(response.body));
        final data = json.decode(utf8.decode(response.bodyBytes));
        print("RESPONSE; BYTES; ${response.bodyBytes}");
        print("RESPONSE; UTF8-DECODED; ${utf8.decode(response.bodyBytes)}");
        print(
            "RESPONSE; JSON-DECODED; ${json.decode(utf8.decode(response.bodyBytes))["plainLyrics"]}");
        print(
            "RESPONSE; ONLY-JSON-DECODED; ${json.decode((response.body))["plainLyrics"]}");

        print("HEADERS; ${response.headers}");
        if (data["syncedLyrics"] == null || data["plainLyrics"] == null) {
          getIfLyricsFail(context, name, artist, duration, album, finished);
        } else {
          finished(data, duration);
        }
      } else {
        print(response.statusCode);
        print(jsonDecode(response.body));
        getIfLyricsFail(context, name, artist, duration, album, finished);
      }
    } catch (e) {
      print(e);

      return {};
    }
    finished({"plainLyrics": "", "syncedLyrics": ""}, duration);
  }

  getIfLyricsFail(context, String name, String artist, double duration,
      String album, Function(Map, double) finished) async {
    print(
        "GEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEET");
    final response = await http.get(
      Uri(
        scheme: 'https',
        host: 'lrclib.net',
        path: '/api/search',
        queryParameters: {
          "q": "$artist $name",
        },
      ),
    );

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));

      for (int i = 0; i < data.length; i++) {
        print(data[i]["duration"]);
      }
      if (data.length == 0) {
        print("object");
        finished({"plainLyrics": "", "syncedLyrics": ""}, duration);
      } else {
        print(data[0].keys);

        finished(data[0], duration);
      }
    } else {
      finished({"plainLyrics": "", "syncedLyrics": ""}, duration);
    }
  }
}
