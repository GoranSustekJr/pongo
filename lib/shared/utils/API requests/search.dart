import 'package:pongo/exports.dart';
import 'package:spotify_api/spotify_api.dart';
import 'package:http/http.dart' as http;

class SearchSpotify {
  // REMOVED     REMOVED

  // Initialize the API
  final api = SpotifyWebApi(
    refresher: ClientCredentialsRefresher(
      clientId: 'a89eb82a4af342fca1895ea0387d886b',
      clientSecret: '6ea0b3216618475fa1f9b031f08e1a20',
    ),
  );

  Future<Map> search(context, String q) async {
    int tries = 0;

    try {
      while (tries < 2) {
        tries++;
        final accessTokenHandler =
            Provider.of<AccessToken>(context, listen: false);
        String market = await Storage().getMarket() ?? 'US';
        print(accessTokenHandler.accessToken);
        final response = await http.post(
          Uri.parse("${AppConstants.SERVER_URL}search_spotify_tracks"),
          body: jsonEncode(
            {
              "at+JWT": accessTokenHandler.accessToken,
              "query": q,
              "market": market,
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
