import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../../utils/platform.dart';
import '../../../../app/view_models/app_settings_view_model.dart';
import '../../../../shell/view_models/shell_view_model.dart';
import '../../../themes/colors.dart';
import '../liquid_glass_background.dart';
import '../liquid_glass_render.dart';

Widget backButton(BuildContext context) {
  final Widget child = Container(
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
            child: liquidGlassBackground(
              enabled: context.readSettings.useLiquidGlass,
              child: CupertinoButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.shell.showBottomNavBar.value = true;
                  context.shell.showSearchBar.value = true;
                },
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
              onTap: () {
                Navigator.of(context).pop();
                context.shell.showBottomNavBar.value = true;
                context.shell.showSearchBar.value = true;
              },
              child: child,
            ),
          ),
        );
}
