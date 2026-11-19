import 'dart:io';
import 'dart:typed_data';

import 'package:blurhash_ffi/blurhash.dart';
import 'package:flutter/painting.dart';

/// Encodes images into blurhash strings for blurred backgrounds.
class BlurhashService {
  /// The blurhash of the image at [url], a network URL or a `file://` URI.
  ///
  /// [detailed] uses more components for a finer result.
  Future<String> encodeUrl(String url, {bool detailed = true}) {
    final ImageProvider image = url.startsWith('file:///')
        ? FileImage(File(Uri.parse(url).toFilePath()))
        : NetworkImage(url);
    return _encode(image, detailed: detailed);
  }

  /// The blurhash of the encoded image in [bytes].
  Future<String> encodeBytes(Uint8List bytes, {bool detailed = true}) =>
      _encode(MemoryImage(bytes), detailed: detailed);

  Future<String> _encode(ImageProvider image, {required bool detailed}) {
    final components = detailed ? 3 : 2;
    return BlurhashFFI.encode(
      image,
      componentX: components,
      componentY: components,
    );
  }
}
