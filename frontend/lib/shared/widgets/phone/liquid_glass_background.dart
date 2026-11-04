import 'package:pongo/exports.dart';

Widget liquidGlassBackground(
    {Widget child = const SizedBox(), bool enabled = false}) {
  return !enabled
      ? LiquidGlass(
          blur: kIsApple ? AppConstants().liquidGlassBlur : 0,
          opacity: kIsApple ? 0.2 : 0,
          tint: kIsApple ? Colors.white : Col.transp,
          borderRadius: kIsApple
              ? const BorderRadius.all(Radius.circular(28))
              : BorderRadius.zero,
          child: child,
        )
      : child;
}
