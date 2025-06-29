import 'package:pongo/exports.dart';
import 'package:http/http.dart' as http;

class Premium {
  // Check if premium is aquired
  Future<Map> isPremium(context, {String? accessToken}) async {
    int tries = 0;

    try {
      while (tries < 2) {
        tries++;
        final accessTokenHandler =
            Provider.of<AccessToken>(context, listen: false);

        final response = await http.post(
          Uri.parse("${AppConstants.SERVER_URL}get_if_premium"),
          body: jsonEncode(
            {
              "at+JWT": accessToken ?? accessTokenHandler.accessToken,
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
          return {
            "premium": false,
            "error": true
          }; // Handle other status codes as needed
        }
      }
    } catch (e) {
      // print(e);
      return {"premium": false, "error": true};
    }
    return {"premium": false, "error": true};
  }

  // Buy premium
  Future<bool> buyPremium(
      context, String serverVerificationData, String? purchaseId) async {
    int tries = 0;

    try {
      while (tries < 2) {
        tries++;
        final accessTokenHandler =
            Provider.of<AccessToken>(context, listen: false);

        final response = await http.post(
          Uri.parse("${AppConstants.SERVER_URL}buy_premium"),
          body: jsonEncode(
            {
              "at+JWT": accessTokenHandler.accessToken,
              "serverVerificationData": serverVerificationData,
              "purchaseId": purchaseId,
            },
          ),
        );

        if (response.statusCode == 200) {
          Map<String, dynamic> data = jsonDecode(response.body);
          if (data["premium"]) {
            premium.value = true;
          }
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
          return false; // Handle other status codes as needed
        }
      }
    } catch (e) {
      // print(e);
      return false;
    }

    return false;
  }
}
