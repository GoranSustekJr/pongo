import 'package:pongo/exports.dart';
import 'package:http/http.dart' as http;

class ArtistSpotify {
  // REMOVED     REMOVED

  // Initialize the API

  Future<Map> get(context, String said) async {
    int tries = 0;

    try {
      while (tries < 2) {
        tries++;
        final accessTokenHandler =
            Provider.of<AccessToken>(context, listen: false);

        String market = await Storage().getMarket() ?? 'US';

        final response = await http.post(
          Uri.parse("${AppConstants.SERVER_URL}get_artist_metadata"),
          body: jsonEncode(
            {
              "at+JWT": accessTokenHandler.accessToken,
              "said": said,
              "market": market,
            },
          ),
        );

        if (response.statusCode == 200) {
          Map<String, dynamic> data = jsonDecode(response.body);

          return data;
        } else if (response.statusCode == 401) {
          if (jsonDecode(response.body)["detail"] == "Disabled") {
            Notifications()
                .showDisabledNotification(notificationsContext.value!);
            break;
          } else {
            if (tries < 2) {
              await AccessTokenhandler().renew(context);
            } else {
              break; // Exit the loop after the second attempt
            }
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

// Get artist image
  Future<Map> getImage(context, String said) async {
    int tries = 0;

    try {
      while (tries < 2) {
        tries++;
        final accessTokenHandler =
            Provider.of<AccessToken>(context, listen: false);

        final response = await http.post(
          Uri.parse(
              "${AppConstants.SERVER_URL}caf5cc332d474f35ff74e94af44f2a7801b620b2ce0196560e038b511d14986e"),
          body: jsonEncode(
            {
              "at+JWT": accessTokenHandler.accessToken,
              "said": said,
            },
          ),
        );

        if (response.statusCode == 200) {
          Map<String, dynamic> data = jsonDecode(response.body);

          return data;
        } else if (response.statusCode == 401) {
          if (jsonDecode(response.body)["detail"] == "Disabled") {
            Notifications()
                .showDisabledNotification(notificationsContext.value!);
            break;
          } else {
            if (tries < 2) {
              await AccessTokenhandler().renew(context);
            } else {
              break; // Exit the loop after the second attempt
            }
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
