import 'package:pongo/exports.dart';
import 'package:http/http.dart' as http;

class Recommendations {
  // REMOVED     REMOVED

  Future<Map> get(context) async {
    int tries = 0;

    // Search result num

    List stids = await DatabaseHelper().queryLFHTracksBy5();
    bool recommendForYou = await Storage().getRecommendedForYou();
    bool recommendPongo = await Storage().getRecommendedPongo();

    print(stids);

    try {
      while (tries < 2) {
        tries++;
        final accessTokenHandler =
            Provider.of<AccessToken>(context, listen: false);
        String market = await Storage().getMarket() ?? 'US';
        print(accessTokenHandler.accessToken);
        final response = await http.post(
          Uri.parse("${AppConstants.SERVER_URL}get_suggestions"),
          body: jsonEncode(
            {
              "at+JWT": accessTokenHandler.accessToken,
              "market": market,
              "stids": stids,
              "personal_rec": recommendForYou, // Get personal recommendatins
              "pongo_rec": recommendPongo, // Get pongo recommendations
            },
          ),
        );

        if (response.statusCode == 200) {
          Map<String, dynamic> data = jsonDecode(response.body);
          print("KEYS: ${data.keys}");
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
