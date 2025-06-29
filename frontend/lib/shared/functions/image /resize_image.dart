import 'package:pongo/exports.dart';
import 'dart:ui' as ui;

Future<MemoryImage> resizeImage(Uint8List imageData, int targetWidth) async {
  // Decode the image to a ui.Image
  final codec = await ui.instantiateImageCodec(imageData);
  final frame = await codec.getNextFrame();
  final originalImage = frame.image;

  // Calculate the new dimensions
  final targetHeight =
      (originalImage.height * targetWidth / originalImage.width).round();

  // Resize the image
  final resizedImage =
      await originalImage.toByteData(format: ui.ImageByteFormat.png);
  final resizedCodec = await ui.instantiateImageCodec(
    resizedImage!.buffer.asUint8List(),
    targetWidth: targetWidth,
    targetHeight: targetHeight,
  );
  final resizedFrame = await resizedCodec.getNextFrame();
  final resizedImageBytes =
      await resizedFrame.image.toByteData(format: ui.ImageByteFormat.png);

  return MemoryImage(resizedImageBytes!.buffer.asUint8List());
}
