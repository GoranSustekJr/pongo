import 'package:pongo/exports.dart';
import 'package:http/http.dart' as http;

class SearchSpotify {
  // REMOVED     REMOVED

  Future<Map> search(context, String q) async {
    int tries = 0;

    // Search result num

    final numSearchArtists = await Storage().getNumOfSearchArtists();
    final numSearchAlbums = await Storage().getNumOfSearchAlbums();
    final numSearchTracks = await Storage().getNumOfSearchTracks();
    final numSearchPlaylists = await Storage().getNumOfSearchPlaylists();

    try {
      while (tries < 2) {
        tries++;
        final accessTokenHandler =
            Provider.of<AccessToken>(context, listen: false);
        String market = await Storage().getMarket() ?? 'US';
        print(accessTokenHandler.accessToken);
        final response = await http.post(
          Uri.parse("${AppConstants.SERVER_URL}search_spotify"),
          body: jsonEncode(
            {
              "at+JWT": accessTokenHandler.accessToken,
              "query": q,
              "market": market,
              "artists_num": numSearchArtists,
              "albums_num": numSearchAlbums,
              "tracks_num": numSearchTracks,
              "playlists_num": numSearchPlaylists,
            },
          ),
        );

        if (response.statusCode == 200) {
          Map<String, dynamic> data = jsonDecode(response.body);
          print("KEYS: ${data["albums"]["items"].length}");
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
      print(e);

      return {};
    }
    return {};
  }
}
