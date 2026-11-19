import '../domain/models/catalog/track.dart';

/// Pixel count used to rank [image] against other sizes of the same picture.
///
/// A missing dimension is estimated from the other one the same way the
/// server data has always been ranked.
int _resolution(AlbumImagesTrack image) {
  final width = image.width;
  final height = image.height;
  if (width != null) return width * (height ?? width);
  if (height != null) return height + height;
  return 0;
}

/// URL of the largest image in [images], or an empty string if there is none.
String bestImageUrl(List<AlbumImagesTrack> images) {
  if (images.isEmpty) return '';
  var best = images.first;
  var bestResolution = 0;
  for (final image in images) {
    final resolution = _resolution(image);
    if (resolution > bestResolution) {
      best = image;
      bestResolution = resolution;
    }
  }
  return best.url;
}

/// URL of the smallest image in [images] covering [width] by [height].
///
/// Falls back to [bestImageUrl] when every image is smaller.
String imageUrlForSize(List<AlbumImagesTrack> images, int width, int height) {
  if (images.isEmpty) return '';
  final wanted = width * height;
  final sorted = [...images]
    ..sort((a, b) => _resolution(a).compareTo(_resolution(b)));
  for (final image in sorted) {
    if (_resolution(image) >= wanted) return image.url;
  }
  return bestImageUrl(images);
}
