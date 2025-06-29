import 'package:flutter/cupertino.dart';
import 'package:pongo/exports.dart';
import 'package:pongo/phone/widgets/special/liquid_glass_background.dart';
import 'package:pongo/phone/widgets/special/liquid_glass_render.dart';

backLikeButton(context, IconData icon, Function() function) {
  Widget child = Container(
    height: 50,
    width: 50,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(60),
      color: kIsApple ? null : Colors.black.withAlpha(100),
    ),
    child: Stack(
      children: [
        Center(
          child: Icon(
            icon,
            size: 27.5,
            color: Colors.white,
          ),
        ),
      ],
    ),
  );
  return kIsApple
      ? liquidGlassLayer(
          child: liquidGlass(
            radius: 360,
            /* blur: AppConstants().liquidGlassBlur,
            borderRadius: BorderRadius.circular(360),
            tint: Col.text, */
            child: liquidGlassBackground(
              enabled: liquidGlassEnabled,
              child: CupertinoButton(
                onPressed: function,
                padding: EdgeInsets.zero,
                child: child,
              ),
            ),
          ),
        )
      : ClipRRect(
          borderRadius: BorderRadius.circular(360),
          child: Material(
            color: Col.transp,
            child: InkWell(
              onTap: function,
              child: child,
            ),
          ),
        );
}
