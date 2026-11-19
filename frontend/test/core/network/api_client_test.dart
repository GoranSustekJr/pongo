import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pongo/data/services/api/api_client.dart';
import 'package:pongo/utils/result.dart';

import '../../fakes/test_config.dart';

void main() {
  late String token;
  late int refreshes;
  late int disabled;

  ApiClient clientFor(MockClientHandler handler) {
    return ApiClient(config: testConfig, client: MockClient(handler))
      ..accessTokenProvider = (() => token)
      ..refreshSession = () async {
        refreshes++;
        token = 'fresh';
        return true;
      }
      ..onAccountDisabled = (() => disabled++);
  }

  setUp(() {
    token = 'expired';
    refreshes = 0;
    disabled = 0;
  });

  test('sends the access token with the body', () async {
    late http.Request request;
    final client = clientFor((r) async {
      request = r;
      return http.Response('{"ok": true}', 200);
    });

    final result = await client.post('path', {'q': 'x'});

    expect(result, isA<Ok<Map<String, dynamic>>>());
    expect((result as Ok).value, {'ok': true});
    expect(request.url.toString(), 'http://api.test/path');
    expect(jsonDecode(request.body), {'at+JWT': 'expired', 'q': 'x'});
  });

  test('other status codes fail without retrying', () async {
    var calls = 0;
    final client = clientFor((r) async {
      calls++;
      return http.Response('nope', 500);
    });

    final result = await client.post('path', {});

    expect(result, isA<Error<Map<String, dynamic>>>());
    expect((result as Error).error, isA<ApiException>());
    expect(calls, 1);
    expect(refreshes, 0);
  });

  test('network errors and bodies that are not objects fail', () async {
    expect(
      await clientFor((r) async => throw http.ClientException('down'))
          .post('path', {}),
      isA<Error<Map<String, dynamic>>>(),
    );
    expect(
      await clientFor((r) async => http.Response('[1]', 200)).post('path', {}),
      isA<Error<Map<String, dynamic>>>(),
    );
  });

  test('renews the token once and retries with the new one', () async {
    final sent = <String>[];
    final client = clientFor((r) async {
      final sentToken = (jsonDecode(r.body) as Map)['at+JWT'] as String;
      sent.add(sentToken);
      return sentToken == 'fresh'
          ? http.Response('{"ok": true}', 200)
          : http.Response('{"detail": "Expired"}', 401);
    });

    final result = await client.post('path', {});

    expect(sent, ['expired', 'fresh']);
    expect(refreshes, 1);
    expect((result as Ok).value, {'ok': true});
  });

  test('gives up after the second rejection', () async {
    var calls = 0;
    final client = clientFor((r) async {
      calls++;
      return http.Response('{"detail": "Expired"}', 401);
    });

    final result = await client.post('path', {});

    expect(calls, 2);
    expect(refreshes, 1);
    expect((result as Error).error, isA<ApiException>());
  });

  test('reports a disabled account instead of retrying', () async {
    final client = clientFor(
      (r) async => http.Response('{"detail": "Disabled"}', 401),
    );

    final result = await client.post('path', {});

    expect((result as Error).error, isA<AccountDisabledException>());
    expect(disabled, 1);
    expect(refreshes, 0);
  });
}
