import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'package:pongo/core/constants/app_constants.dart';
import 'package:pongo/core/notifications/notifications.dart';
import 'package:pongo/core/state/globals.dart';
import 'package:pongo/features/auth/data/access_token_handler.dart';
import 'package:pongo/features/auth/models/access_token.dart';

/// Authenticated calls to the Pongo API.
///
/// Every request carries the current access token and is retried once after
/// renewing it when the server rejects it. Disabled accounts get a notification
/// instead of a retry.
class ApiClient {
  const ApiClient();

  /// Returns the decoded response, or an empty map on any failure.
  Future<Map<String, dynamic>> post(
    BuildContext context,
    String path,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) {
    return postBuilt(context, path, () async => body, headers: headers);
  }

  /// Same as [post], for a body that has to be read from storage first.
  Future<Map<String, dynamic>> postBuilt(
    BuildContext context,
    String path,
    Future<Map<String, dynamic>> Function() buildBody, {
    Map<String, String>? headers,
  }) async {
    try {
      final response = await send(context, path, buildBody, headers: headers);
      if (response == null) return {};
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  /// Returns the successful response, or null if the request was rejected.
  /// Network errors are left to the caller.
  Future<http.Response?> send(
    BuildContext context,
    String path,
    Future<Map<String, dynamic>> Function() buildBody, {
    Map<String, String>? headers,
  }) async {
    for (int attempt = 1; attempt <= 2; attempt++) {
      final accessToken =
          Provider.of<AccessToken>(context, listen: false).accessToken;
      final body = await buildBody();

      final response = await http.post(
        Uri.parse("${AppConstants.SERVER_URL}$path"),
        headers: headers,
        body: jsonEncode({"at+JWT": accessToken, ...body}),
      );

      if (response.statusCode == 200) return response;
      if (response.statusCode != 401) return null;

      if (jsonDecode(response.body)["detail"] == "Disabled") {
        Notifications().showDisabledNotification(notificationsContext.value!);
        return null;
      }
      if (attempt < 2) await AccessTokenHandler().renew(context);
    }
    return null;
  }
}
