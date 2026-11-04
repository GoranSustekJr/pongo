// ignore_for_file: non_nullable_equals_parameter

import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:pongo/exports.dart';
import 'dart:ui' as ui;

const _DEFAULT_SIZE = 32;

/// Display a Hash then load an Image
class BlurHashh extends StatefulWidget {
  const BlurHashh({
    required this.hash,
    super.key,
    this.color = Colors.blueGrey,
    this.imageFit = BoxFit.fill,
    this.decodingWidth = _DEFAULT_SIZE,
    this.decodingHeight = _DEFAULT_SIZE,
    this.image,
    this.onReady,
    this.onStarted,
    this.httpHeaders = const {},
    this.errorBuilder,
  })  : assert(decodingWidth > 0),
        assert(decodingHeight != 0);

  /// Callback when image is downloaded
  final VoidCallback? onReady;

  /// Callback when image download starts
  final VoidCallback? onStarted;

  /// Hash to decode
  final String hash;

  /// Displayed background color before decoding
  final Color color;

  /// How to fit decoded & downloaded image
  final BoxFit imageFit;

  /// Decoding width
  final int decodingWidth;

  /// Decoding height
  final int decodingHeight;

  /// Remote resource to download
  final String? image;

  /// HTTP headers for secure calls
  final Map<String, String> httpHeaders;

  /// Network image errorBuilder
  final ImageErrorWidgetBuilder? errorBuilder;

  @override
  BlurHashhState createState() => BlurHashhState();
}

class BlurHashhState extends State<BlurHashh> {
  late Future<ui.Image> _image;
  late bool loading;

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() {
    _decodeImage();
    loading = false;
  }

  @override
  void didUpdateWidget(BlurHashh oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hash != oldWidget.hash ||
        widget.image != oldWidget.image ||
        widget.decodingWidth != oldWidget.decodingWidth ||
        widget.decodingHeight != oldWidget.decodingHeight) {
      _init();
    }
  }

  void _decodeImage() {
    _image = blurHashDecodeImage(
      blurHash: widget.hash,
      width: widget.decodingWidth,
      height: widget.decodingHeight,
    );
  }

  @override
  Widget build(BuildContext context) => Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: [
          buildBlurHashBackground(),
          //   if (widget.image != null) prepareDisplayedImage(widget.image!),
        ],
      );

  /*  Widget prepareDisplayedImage(String image) => Image.network(
        image,
        fit: widget.imageFit,
        headers: widget.httpHeaders,
        errorBuilder: widget.errorBuilder,
        loadingBuilder: (context, img, loadingProgress) {
          if (!loading) {
            loading = true;
            widget.onStarted?.call();
          }

          if (loadingProgress == null) {
            widget.onReady?.call();
            return img;
          } else {
            return const SizedBox();
          }
        },
      ); */

  /// Decode the blurhash and display the resulting image
  Widget buildBlurHashBackground() => FutureBuilder<ui.Image>(
        future: _image,
        builder: (ctx, snap) => snap.hasData
            ? Image(image: UiImage(snap.data!), fit: widget.imageFit)
            : Container(color: widget.color),
      );
}

class UiImage extends ImageProvider<UiImage> {
  final ui.Image image;
  final double scale;

  const UiImage(this.image, {this.scale = 1.0});

  @override
  Future<UiImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<UiImage>(this);

  @override
  ImageStreamCompleter loadImage(UiImage key, ImageDecoderCallback decode) =>
      OneFrameImageStreamCompleter(_loadAsync(key));

  Future<ImageInfo> _loadAsync(UiImage key) async {
    assert(key == this);
    return ImageInfo(image: image, scale: key.scale);
  }

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType) return false;
    final UiImage typedOther = other;
    return image == typedOther.image && scale == typedOther.scale;
  }

  @override
  int get hashCode => Object.hash(image.hashCode, scale);

/*   @override
  String toString() =>
      '$runtimeType(${describeIdentity(image)}, scale: $scale)'; */
}

class Blurhash extends StatelessWidget {
  final Widget child;
  final String blurhash;
  final int sigmaX;
  final int sigmaY;

  const Blurhash({
    super.key,
    required this.child,
    required this.blurhash,
    required this.sigmaX,
    required this.sigmaY,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: Container(
        color: const Color(0xFF141C3D),
        child: BlurHash(
          hash: blurhash,
          imageFit: BoxFit.cover,
        ),
      ),
    );
  }
}
