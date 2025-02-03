import 'package:pongo/exports.dart';
import 'package:http/http.dart' as http;

class Premium {
  // Check if premium is aquired
  Future<bool> isPremium(context) async {
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
              "at+JWT": accessTokenHandler.accessToken,
            },
          ),
        );

        if (response.statusCode == 200) {
          Map<String, dynamic> data = jsonDecode(response.body);
          print(data["premium"]);
          return data["premium"];
        } else if (response.statusCode == 401) {
          if (tries < 2) {
            await AccessTokenhandler().renew(context);
          } else {
            break; // Exit the loop after the second attempt
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
          print(data["premium"]);
          if (data["premium"]) {
            premium.value = true;
          }
        } else if (response.statusCode == 401) {
          if (tries < 2) {
            await AccessTokenhandler().renew(context);
          } else {
            break; // Exit the loop after the second attempt
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
