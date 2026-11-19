import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../config/app_config.dart';
import '../../../utils/result.dart';
import 'response_body.dart';

/// Thrown when the API rejects a request.
class ApiException implements Exception {
  /// Creates an exception for a response with [statusCode].
  const ApiException(this.statusCode, [this.message = '']);

  /// The HTTP status code of the rejected response.
  final int statusCode;

  /// The detail the server sent, if any.
  final String message;

  @override
  String toString() => 'ApiException($statusCode, $message)';
}

/// Thrown when the signed in account was disabled on the server.
class AccountDisabledException implements Exception {
  /// Creates an account disabled exception.
  const AccountDisabledException();
}

/// Authenticated calls to the Pongo API.
///
/// Every request carries the current access token and is retried once after
/// [refreshSession] renews it when the server rejects it. Disabled accounts
/// call [onAccountDisabled] instead of retrying.
class ApiClient {
  /// Creates a client for the server in [_config].
  ApiClient({required this._config, http.Client? client})
    : _client = client ?? http.Client();

  final AppConfig _config;
  final http.Client _client;

  /// Returns the access token sent with each request.
  String? Function()? accessTokenProvider;

  /// Renews the access token, returning whether it succeeded.
  Future<bool> Function()? refreshSession;

  /// Called when the server reports the account as disabled.
  VoidCallback? onAccountDisabled;

  Uri _uri(String path) => Uri.parse('${_config.serverUrl}$path');

  /// Posts [body] to [path] and decodes the JSON response.
  Future<Result<Map<String, dynamic>>> post(
    String path,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    final result = await postForResponse(path, body, headers: headers);
    switch (result) {
      case Ok(:final value):
        try {
          return switch (jsonDecode(value.utf8Body)) {
            final Map<String, dynamic> map => Result.ok(map),
            _ => const Result.error(FormatException('Expected a JSON object')),
          };
        } on FormatException catch (e) {
          return Result.error(e);
        }
      case Error(:final error):
        return Result.error(error);
    }
  }

  /// Posts [body] to [path] and returns the raw successful response.
  Future<Result<http.Response>> postForResponse(
    String path,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    try {
      for (var attempt = 1; attempt <= 2; attempt++) {
        final response = await _client.post(
          _uri(path),
          headers: headers,
          body: jsonEncode({'at+JWT': accessTokenProvider?.call(), ...body}),
        );

        if (response.statusCode == 200) return Result.ok(response);
        if (response.statusCode != 401) {
          debugPrint('ApiClient $path returned ${response.statusCode}');
          return Result.error(ApiException(response.statusCode));
        }

        if (_detail(response) == 'Disabled') {
          onAccountDisabled?.call();
          return const Result.error(AccountDisabledException());
        }
        if (attempt < 2) await refreshSession?.call();
      }
      return const Result.error(ApiException(401));
    } on Exception catch (e) {
      debugPrint('ApiClient $path failed: $e');
      return Result.error(e);
    }
  }

  /// Posts [body] to [path] without an access token, for signing in.
  Future<Result<Map<String, dynamic>>> postUnauthenticated(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _client.post(_uri(path), body: jsonEncode(body));
      if (response.statusCode != 200) {
        return Result.error(
          ApiException(response.statusCode, _detail(response) ?? ''),
        );
      }
      return Result.ok(jsonDecode(response.utf8Body) as Map<String, dynamic>);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  String? _detail(http.Response response) {
    try {
      final body = jsonDecode(response.utf8Body);
      return body is Map ? body['detail']?.toString() : null;
    } on FormatException {
      return null;
    }
  }
}
