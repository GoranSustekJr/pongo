import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../../utils/platform.dart';
import '../../../../core/app_icons.dart';
import '../../../../core/themes/colors.dart';
import '../../../../core/ui/image/image_compatible.dart';
import '../../../../core/ui/phone/inkwell.dart';
import '../../../../core/ui/space.dart';

class QueueTile extends StatelessWidget {
  final String title;
  final String artist;
  final String imageUrl;
  final Function() onTap;
  final Widget? trailing;
  const QueueTile({
    super.key,
    required this.onTap,
    this.trailing,
    required this.title,
    required this.artist,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final Widget child = Row(
      children: [
        Container(
          width: 65,
          height: 65,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7.5),
            color: context.colors.realBackground.withAlpha(150),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7.5),
            child: imageUrl == ''
                ? Center(child: Icon(AppIcons.blankTrack, color: Colors.white))
                : ImageCompatible(
                    image: imageUrl,
                  ) /* imageUrl.toString().contains("file:///")
                                ? Image.file(
                                    File.fromUri(Uri.parse(imageUrl)),
                                    fit: BoxFit.cover,
                                  )
                                : CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    fit: BoxFit.cover,
                                  ), */,
          ),
        ),
        razw(12.5),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              razh(2.5),
              Text(
                artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withAlpha(200),
                ),
              ),
            ],
          ),
        ),
        SizedBox(child: trailing),
      ],
    );

    return kIsApple
        ? SizedBox(
            height: 85,
            width: MediaQuery.of(context).size.width,
            child: CupertinoButton(
              padding: EdgeInsets.only(left: kIsMobile ? 15 : 10),
              onPressed: onTap,
              child: child,
            ),
          )
        : ClipRRect(
            borderRadius: BorderRadius.circular(7.5),
            child: inkWell(
              Padding(
                padding: EdgeInsets.only(
                  left: kIsMobile ? 15 : 10,
                  top: 7.5,
                  bottom: 7.5,
                ),
                child: child,
              ),
              onTap,
            ),
          );
  }
}
