import 'dart:ui';
import 'package:pongo/exports.dart';

class Background extends StatelessWidget {
  final Widget child;

  const Background({
    super.key,
    required this.child,
  });

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
              hash: r'L03[fE,t|H$Q712s2swd{}{}OD{}',  cyan - UAQwR.X8$$10OYAD}r}rR+5mJ8=wxu9^S21I
              imageFit: BoxFit.cover,
            ), */
            Image.asset(
              darkMode.value
                  ? 'assets/images/pongo_background_10k.png'
                  : 'assets/images/pongo_white_red_background_10k.png',
              fit: BoxFit.fill,
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
            ),
            /* Blurhash(
              blurhash: AppConstants().BLURHASH,
              sigmaX: 0,
              sigmaY: 0,
              child: const SizedBox(),
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
