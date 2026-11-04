import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'package:pongo/core/constants/app_constants.dart';
import 'package:pongo/core/state/globals.dart';
import 'package:pongo/core/storage/secure_storage.dart';
import 'package:pongo/features/auth/data/sign_in_handler.dart';
import 'package:pongo/features/auth/models/access_token.dart';

class AccessTokenHandler {
  Future<void> updateSystemWide(context, accessToken) async {
    await Storage().writeAccessToken(accessToken);
    final accessTokenProvided =
        Provider.of<AccessToken>(context, listen: false);
    await accessTokenProvided.setAccessToken(accessToken);
  }

  renew(context) async {
    final refreshToken = await Storage().getRefreshToken();
    final response =
        await http.post(Uri.parse("${AppConstants.SERVER_URL}renew_at"),
            body: jsonEncode({
              "jwt": refreshToken,
            }));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await updateSystemWide(context, data["at"]);
      if (data["st"] != null) {
        streamToken = data["st"];
        await Storage().writeStreamToken(streamToken);
      }
    } else if (response.statusCode == 401) {
      //Bas refresh token! => Sign out
      SignInHandler().signOut(context);
    }
  }
}
