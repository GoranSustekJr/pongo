import 'package:pongo/exports.dart';
import 'package:http/http.dart' as http;

class DeleteAccount {
  // REMOVED     REMOVED

  // Initialize the API

  Future delete(context) async {
    int tries = 0;

    try {
      while (tries < 2) {
        tries++;
        final accessTokenHandler =
            Provider.of<AccessToken>(context, listen: false);

        final response = await http.post(
          Uri.parse("${AppConstants.SERVER_URL}delete_account"),
          body: jsonEncode(
            {
              "at+JWT": accessTokenHandler.accessToken,
            },
          ),
        );

        if (response.statusCode == 200) {
          await SignInHandler().signOut(context);
          break;
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
