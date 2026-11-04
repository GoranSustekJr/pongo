import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'package:pongo/core/constants/app_constants.dart';
import 'package:pongo/core/notifications/notifications.dart';
import 'package:pongo/core/state/globals.dart';
import 'package:pongo/features/auth/data/access_token_handler.dart';
import 'package:pongo/features/auth/data/sign_in_handler.dart';
import 'package:pongo/features/auth/models/access_token.dart';

class DeleteAccount {
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
