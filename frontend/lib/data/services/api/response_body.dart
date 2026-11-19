import 'dart:convert';

import 'package:http/http.dart' as http;

extension Utf8ResponseBody on http.Response {
  /// [http.Response.body] falls back to Latin-1 when the content type has no
  /// charset, which garbles characters such as "š". The API always sends UTF-8.
  String get utf8Body => utf8.decode(bodyBytes, allowMalformed: true);
}
