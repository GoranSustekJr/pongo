import 'package:flutter/cupertino.dart';
import 'package:pongo/exports.dart';
import 'package:pongo/phone/widgets/special/liquid_glass_render.dart';

backButton(context) {
  Widget child = Container(
    height: 50,
    width: 50,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(60),
      color: kIsApple ? null : Colors.black.withAlpha(100),
    ),
    child: const Stack(
      children: [
        Positioned(
          left: 9,
          top: 11,
          child: Icon(
            CupertinoIcons.chevron_left,
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
            tint: Col.text,
             */
            child: CupertinoButton(
              onPressed: () {
                Navigator.of(context).pop();
                showBottomNavBar.value = true;
                showSearchBar.value = true;
              },
              padding: EdgeInsets.zero,
              child: child,
            ),
          ),
        )
      : ClipRRect(
          borderRadius: BorderRadius.circular(360),
          child: Material(
            color: Col.transp,
            child: InkWell(
              onTap: () {
                Navigator.of(context).pop();
                showBottomNavBar.value = true;
                showSearchBar.value = true;
              },
              child: child,
            ),
          ),
        );
}
