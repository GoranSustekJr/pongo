import 'dart:ui';
import 'package:pongo/exports.dart';

class Background extends StatelessWidget {
  final Widget child;

  const Background({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return ClipRRect(
      child: Container(
        width: size.width,
        height: size.height,
        color: const Color(0xFF141C3D),
        child: Stack(
          children: <Widget>[
            /* 
            const BlurHashWidget(
              hash: r'L03[fE,t|H$Q712s2swd{}{}OD{}',
              imageFit: BoxFit.cover,
            ), */
            Image.asset(
              'assets/images/pongo_background_10k.png',
              fit: BoxFit.fill,
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
            ),
            /*   const  BlurHashWidget(
              hash: r'L03[fE,t|H$Q712s2swd{}{}OD{}',
              imageFit: BoxFit.cover,
            ), */
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                    sigmaX: 20, sigmaY: 10), // Reduced blur intensity
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
