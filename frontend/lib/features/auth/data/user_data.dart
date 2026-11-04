import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'package:pongo/core/constants/app_constants.dart';
import 'package:pongo/features/auth/data/access_token_handler.dart';
import 'package:pongo/features/auth/data/sign_in_handler.dart';
import 'package:pongo/features/auth/models/access_token.dart';

class UserData {
  Future<Map?> get(context) async {
    int tries = 0;

    while (tries < 2) {
      tries++;
      final accessTokenHandler =
          Provider.of<AccessToken>(context, listen: false);

      final response = await http.post(
        Uri.parse("${AppConstants.SERVER_URL}user_data"),
        body: jsonEncode(
          {"at+JWT": accessTokenHandler.accessToken},
        ),
      );

      if (response.statusCode == 200) {
        Map data = jsonDecode(response.body);

        return data;
      } else if (response.statusCode == 401) {
        if (tries < 2) {
          await AccessTokenHandler().renew(context);
        } else {
          break; // Exit the loop after the second attempt
        }
      } else {
        SignInHandler().signOut(context);
        return null; // Handle other status codes as needed
      }
    }
    SignInHandler().signOut(context);
    return null; // Return null if it fails after the retry
  }
}
