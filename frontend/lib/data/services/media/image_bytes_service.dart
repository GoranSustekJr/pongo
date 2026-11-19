import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// Reads image bytes from the network or the device.
class ImageBytesService {
  /// Creates a service that downloads with [client].
  ImageBytesService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// The bytes of the image at [source], a network URL, a `file://` URI or a
  /// file path.
  Future<Uint8List> read(String source) async {
    if (source.startsWith('file://')) {
      return File.fromUri(Uri.parse(source)).readAsBytes();
    }
    if (source.startsWith('http')) {
      return (await _client.get(Uri.parse(source))).bodyBytes;
    }
    return File(source).readAsBytes();
  }
}
