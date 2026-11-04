import 'package:pongo/exports.dart';

Widget profileImage(String image) {
  Widget child = image != ""
      ? ClipRRect(
          borderRadius: BorderRadius.circular(360),
          child: ImageCompatible(
            image: image,
            width: 160,
            height: 160,
          ),
        )
      : Center(
          child: Icon(
            AppIcons.profile,
            color: Col.icon,
            size: 60,
          ),
        );
  return kIsApple
      ? LiquidGlass(
          blur: AppConstants().liquidGlassBlur,
          tint: Col.text,
          child: SizedBox(
            width: 160,
            height: 160,
            child: child,
          ))
      : CircleAvatar(
          radius: 80,
          backgroundColor: Col.primaryCard.withAlpha(150),
          child: child,
        );
}
