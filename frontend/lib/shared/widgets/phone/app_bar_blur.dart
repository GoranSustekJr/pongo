import 'dart:ui';
import 'package:pongo/exports.dart';

appBarBlur() {
  return ClipRRect(
    child: BackdropFilter(
      filter: ImageFilter.blur(
          sigmaX: useBlur.value ? 10 : 0, sigmaY: useBlur.value ? 10 : 0),
      child: Container(
        color: Colors.transparent,
      ),
    ),
  );
}
