import 'dart:ui';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:pongo/exports.dart';

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
    Size size = MediaQuery.of(context).size;

    return RepaintBoundary(
      child: ClipRRect(
        child: Container(
          width: size.width,
          height: size.height,
          color: const Color(0xFF141C3D),
          child: Stack(
            children: <Widget>[
              BlurHash(
                hash: blurhash,
                imageFit: BoxFit.cover,
              ),
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                      sigmaX: sigmaX.toDouble(),
                      sigmaY: sigmaY.toDouble()), // Use dynamic values
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
