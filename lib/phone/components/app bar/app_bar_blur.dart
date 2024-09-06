import 'dart:ui';
import 'package:pongo/exports.dart';

appBarBlur() {
  return ClipRRect(
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        color: Colors.transparent,
      ),
    ),
  );
}
