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
        Uri.parse("${AppConstants.SERVER_URL_WSS}test"));
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
          // Store all gotten data
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
    final WebSocketChannel channel =
        WebSocketChannel.connect(Uri.parse("wss://gogodom.ddns.net:9090/test"));
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

  Future<Map<String, dynamic>> getLyrics(BuildContext context, String name,
      String artist, double duration, String album) async {
    try {
      final response = await http.get(
        Uri(
          scheme: 'https',
          host: 'lrclib.net',
          path: '/api/get',
          queryParameters: {
            "artist_name": artist,
            "track_name": name,
            "duration": duration.toInt().toString(),
            "album_name": album,
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));

        // Check if syncedLyrics or plainLyrics is null
        if (data["syncedLyrics"] == null || data["plainLyrics"] == null) {
          // If either is null, attempt to get alternative lyrics
          return await getIfLyricsFail(context, name, artist, duration, album);
        } else {
          return data; // Return the fetched lyrics
        }
      } else {
        // Handle non-200 status codes
//        print("getLyrics failed with status code: ${response.statusCode}");
        return await getIfLyricsFail(context, name, artist, duration, album);
      }
    } catch (e) {
      //    print("Error fetching lyrics: $e");
      return await getIfLyricsFail(context, name, artist, duration, album);
    }
  }

  Future<Map<String, dynamic>> getIfLyricsFail(BuildContext context,
      String name, String artist, double duration, String album) async {
    try {
      final response = await http.get(
        Uri(
          scheme: 'https',
          host: 'lrclib.net',
          path: '/api/search',
          queryParameters: {
            "q": "$name - $artist",
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data.isEmpty) {
          // If no lyrics are found, return an empty response

          return {"plainLyrics": "", "syncedLyrics": "", "duration": 0};
        }

        // Filter synced lyrics
        List<int> syncedIndexes = [];
        List<int> durations = [];

        for (int i = 0; i < data.length; i++) {
          if (data[i]["syncedLyrics"] != null) {
            syncedIndexes.add(i);

            durations.add(data[i]["duration"].toInt());
          }
        }

        if (syncedIndexes.isNotEmpty) {
          // Find the closest match by duration

          int closestMatchIndex = durations
              .asMap()
              .entries
              .map((entry) =>
                  MapEntry(entry.key, (entry.value - duration).abs()))
              .reduce((a, b) => a.value < b.value ? a : b)
              .key;

          // Return the closest match with synced lyrics
          return data[syncedIndexes[closestMatchIndex]];
        } else {
          // If no synced lyrics are found, return the first result (plain lyrics)
          return data[0];
        }
      } else {
        // print(
        //   "getIfLyricsFail failed with status code: ${response.statusCode}");
        return {"plainLyrics": "", "syncedLyrics": "", "duration": 0};
      }
    } catch (e) {
      //   print("Error fetching alternative lyrics: $e");
      return {"plainLyrics": "", "syncedLyrics": "", "duration": 0};
    }
  }

  Future<Map> getDuration(context, String stid) async {
    int tries = 0;

    try {
      while (tries < 2) {
        tries++;
        final accessTokenHandler =
            Provider.of<AccessToken>(context, listen: false);

        final response = await http.post(
          Uri.parse("${AppConstants.SERVER_URL}get_track_duration"),
          body: jsonEncode(
            {
              "at+JWT": accessTokenHandler.accessToken,
              "stid": stid,
            },
          ),
        );

        if (response.statusCode == 200) {
          Map<String, dynamic> data = jsonDecode(response.body);

          return data;
        } else if (response.statusCode == 401) {
          if (tries < 2) {
            await AccessTokenhandler().renew(context);
          } else {
            break; // Exit the loop after the second attempt
          }
        } else {
          return {}; // Handle other status codes as needed
        }
      }
    } catch (e) {
      // print(e);

      return {};
    }
    return {};
  }
}
