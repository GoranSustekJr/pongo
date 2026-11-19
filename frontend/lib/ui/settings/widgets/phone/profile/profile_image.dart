import 'package:flutter/material.dart';

import '../../../../../utils/platform.dart';
import '../../../../core/app_icons.dart';
import '../../../../core/themes/colors.dart';
import '../../../../core/themes/dimens.dart';
import '../../../../core/ui/image/image_compatible.dart';
import '../../../../core/ui/phone/liquid_glass_background.dart';

Widget profileImage(BuildContext context, String image) {
  final Widget child = image != ''
      ? ClipRRect(
          borderRadius: BorderRadius.circular(360),
          child: ImageCompatible(image: image, width: 160, height: 160),
        )
      : Center(
          child: Icon(AppIcons.profile, color: context.colors.icon, size: 60),
        );
  return kIsApple
      ? GlassSurface(
          blur: Dimens.liquidGlassBlur,
          tint: context.colors.text,
          child: SizedBox(width: 160, height: 160, child: child),
        )
      : CircleAvatar(
          radius: 80,
          backgroundColor: context.colors.primaryCard.withAlpha(150),
          child: child,
        );
}
