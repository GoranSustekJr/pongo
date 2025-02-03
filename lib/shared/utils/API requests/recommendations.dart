import 'package:pongo/exports.dart';
import 'package:http/http.dart' as http;

class Recommendations {
  // REMOVED     REMOVED

  Future<Map> get(context) async {
    int tries = 0;

    // Get recommendations

    try {
      while (tries < 2) {
        tries++;
        final accessTokenHandler =
            Provider.of<AccessToken>(context, listen: false);
        String market = await Storage().getMarket() ?? 'US';
        List<String> history = await DatabaseHelper().queryTrackHistoryNum(50);

        int categoriesNum = await Storage().getNumOfCategories();
        String locale = await Storage().getLocale() ?? 'en';

        final response = await http.post(
          Uri.parse("${AppConstants.SERVER_URL}get_recommendations"),
          body: jsonEncode(
            {
              "at+JWT": accessTokenHandler.accessToken,
              "market": market,
              "history": history,
              "category_num": categoriesNum,
              "locale": locale,
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
      //print(e);SignInHandler().signOut(context);

      SignInHandler().signOut(context);
      return {};
    }
    return {};
  }

  Future<Map> getDeprecated(context) async {
    int tries = 0;

    // Search result num

    List stids = await DatabaseHelper().queryLFHTracksBy5();
    bool recommendForYou = await Storage().getRecommendedForYou();
    bool recommendPongo = await Storage().getRecommendedPongo();

    try {
      while (tries < 2) {
        tries++;
        final accessTokenHandler =
            Provider.of<AccessToken>(context, listen: false);
        String market = await Storage().getMarket() ?? 'US';

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
