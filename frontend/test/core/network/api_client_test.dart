import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

import 'package:pongo/core/network/api_client.dart';
import 'package:pongo/features/auth/models/access_token.dart';

void main() {
  late BuildContext context;
  late AccessToken accessToken;

  setUpAll(() => dotenv.testLoad(fileInput: 'SERVER_URL=http://api.test/\n'));

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    accessToken = AccessToken();
    await accessToken.setAccessToken('expired');
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(Provider<AccessToken>.value(
      value: accessToken,
      child: Builder(builder: (c) {
        context = c;
        return const SizedBox();
      }),
    ));
  }

  Future<Map<String, dynamic>> post(WidgetTester tester, MockClient client) {
    return tester
        .runAsync(() => http.runWithClient(
              () => const ApiClient().post(context, 'path', {'q': 'x'}),
              () => client,
            ))
        .then((value) => value!);
  }

  testWidgets('sends the access token with the body', (tester) async {
    await pump(tester);
    late http.Request request;
    final data = await post(tester, MockClient((r) async {
      request = r;
      return http.Response('{"ok": true}', 200);
    }));

    expect(data, {'ok': true});
    expect(request.url.toString(), 'http://api.test/path');
    expect(jsonDecode(request.body), {'at+JWT': 'expired', 'q': 'x'});
  });

  testWidgets('other status codes give an empty map without retrying',
      (tester) async {
    await pump(tester);
    var calls = 0;
    final data = await post(tester, MockClient((r) async {
      calls++;
      return http.Response('nope', 500);
    }));

    expect(data, isEmpty);
    expect(calls, 1);
  });

  testWidgets('network errors and bad bodies give an empty map',
      (tester) async {
    await pump(tester);
    expect(
        await post(tester,
            MockClient((r) async => throw http.ClientException('down'))),
        isEmpty);
    expect(
        await post(tester, MockClient((r) async => http.Response('[1]', 200))),
        isEmpty);
  });

  testWidgets('renews the token once and retries with the new one',
      (tester) async {
    await pump(tester);
    final sent = <String>[];
    final data = await post(tester, MockClient((r) async {
      final body = jsonDecode(r.body) as Map;
      if (!body.containsKey('at+JWT')) {
        return http.Response(jsonEncode({'at': 'fresh'}), 200);
      }
      sent.add(body['at+JWT']);
      return body['at+JWT'] == 'fresh'
          ? http.Response('{"ok": true}', 200)
          : http.Response('{"detail": "Expired"}', 401);
    }));

    expect(sent, ['expired', 'fresh']);
    expect(data, {'ok': true});
  });

  testWidgets('gives up after the second rejection', (tester) async {
    await pump(tester);
    var calls = 0;
    final data = await post(tester, MockClient((r) async {
      final body = jsonDecode(r.body) as Map;
      if (!body.containsKey('at+JWT')) {
        return http.Response(jsonEncode({'at': 'fresh'}), 200);
      }
      calls++;
      return http.Response('{"detail": "Expired"}', 401);
    }));

    expect(calls, 2);
    expect(data, isEmpty);
  });
}
