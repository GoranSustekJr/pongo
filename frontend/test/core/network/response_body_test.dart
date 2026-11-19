import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:pongo/data/services/api/response_body.dart';

void main() {
  test('decodes a JSON body without a charset as UTF-8', () {
    final response = http.Response.bytes(
      utf8.encode('{"name":"Šuštek šđčćž"}'),
      200,
      headers: {'content-type': 'application/json'},
    );

    final body = jsonDecode(response.utf8Body) as Map<String, dynamic>;
    expect(body['name'], 'Šuštek šđčćž');
  });
}
