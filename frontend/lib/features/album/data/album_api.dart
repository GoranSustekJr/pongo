import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'package:pongo/core/constants/app_constants.dart';
import 'package:pongo/core/notifications/notifications.dart';
import 'package:pongo/core/state/globals.dart';
import 'package:pongo/features/auth/data/access_token_handler.dart';
import 'package:pongo/features/auth/models/access_token.dart';

class AlbumSpotify {
  // Initialize the API

  Future<Map> getData(context, String salid) async {
    int tries = 0;

    try {
      while (tries < 2) {
        tries++;
        final accessTokenHandler =
            Provider.of<AccessToken>(context, listen: false);

        final response = await http.post(
          Uri.parse("${AppConstants.SERVER_URL}get_album_data"),
          body: jsonEncode(
            {
              "at+JWT": accessTokenHandler.accessToken,
              "salid": salid,
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

  Future<Map> getTracks(context, String salid) async {
    int tries = 0;

    try {
      while (tries < 2) {
        tries++;
        final accessTokenHandler =
            Provider.of<AccessToken>(context, listen: false);

        final response = await http.post(
          Uri.parse("${AppConstants.SERVER_URL}get_album"),
          body: jsonEncode(
            {
              "at+JWT": accessTokenHandler.accessToken,
              "salid": salid,
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
      //  print(e);
      return {};
    }
    return {};
  }

  Future<Map> getShuffle(context, String said) async {
    int tries = 0;

    try {
      while (tries < 2) {
        tries++;
        final accessTokenHandler =
            Provider.of<AccessToken>(context, listen: false);

        final response = await http.post(
          Uri.parse("${AppConstants.SERVER_URL}get_album_shuffle"),
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
      //print(e);
      return {};
    }
    return {};
  }
}
