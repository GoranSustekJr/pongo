import 'package:pongo/exports.dart';
import 'package:http/http.dart' as http;

class SearchSpotify {
  Future<Map> search(context, String q) async {
    int tries = 0;

    try {
      while (tries < 2) {
        tries++;
        final accessTokenHandler =
            Provider.of<AccessToken>(context, listen: false);
        String market = await Storage().getMarket() ?? 'US';
        final response = await http.post(
          Uri.parse("${AppConstants.SERVER_URL}search_spotify"),
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
      //print(e);
      return {};
    }
    return {};
  }
}
