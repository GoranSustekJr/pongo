import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../../utils/platform.dart';
import '../../../../app/view_models/app_settings_view_model.dart';
import '../../../themes/colors.dart';
import '../liquid_glass_background.dart';
import '../liquid_glass_render.dart';

Widget backLikeButton(
  BuildContext context,
  IconData icon,
  Function() function,
) {
  final Widget child = Container(
    height: 50,
    width: 50,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(60),
      color: kIsApple ? null : Colors.black.withAlpha(100),
    ),
    child: Stack(
      children: [Center(child: Icon(icon, size: 27.5, color: Colors.white))],
    ),
  );
  return kIsApple
      ? liquidGlassLayer(
          child: liquidGlass(
            radius: 360,
            /* blur: Dimens.liquidGlassBlur,
            borderRadius: BorderRadius.circular(360),
            tint: context.colors.text, */
            child: liquidGlassBackground(
              enabled: context.readSettings.useLiquidGlass,
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
            child: InkWell(onTap: function, child: child),
          ),
        );
}
