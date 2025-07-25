import 'package:pongo/exports.dart';
import 'package:http/http.dart' as http;

class SearializedData {
  Future<Map> tracks(context, List<String> stids) async {
    int tries = 0;

    try {
      while (tries < 2) {
        tries++;
        final accessTokenHandler =
            Provider.of<AccessToken>(context, listen: false);

        final response = await http.post(
          Uri.parse("${AppConstants.SERVER_URL}get_serialized_tracks"),
          body: jsonEncode(
            {
              "at+JWT": accessTokenHandler.accessToken,
              "stids": stids,
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

  Future<Map> getShuffle(context, List<String> stids) async {
    int tries = 0;

    try {
      while (tries < 2) {
        tries++;
        final accessTokenHandler =
            Provider.of<AccessToken>(context, listen: false);

        final response = await http.post(
          Uri.parse("${AppConstants.SERVER_URL}get_serialized_shuffle"),
          body: jsonEncode(
            {
              "at+JWT": accessTokenHandler.accessToken,
              "stids": stids,
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
      //print(e);
      return {};
    }
    return {};
  }
}
