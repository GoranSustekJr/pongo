import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_swipe_action_cell/core/cell.dart';

import '../../../../utils/platform.dart';
import '../../../core/app_icons.dart';
import '../../../core/themes/colors.dart';
import '../../../core/ui/phone/buttons/icon_button.dart';
import '../../../core/ui/phone/inkwell.dart';
import '../../../core/ui/phone/liquid_glass_background.dart';
import '../../../core/ui/space.dart';

class PlaylistTile extends StatelessWidget {
  final bool first;
  final bool last;
  final Uint8List? cover;
  final String title;
  final String? subtitle;
  final Function() function;
  final Function() removePlaylist;
  const PlaylistTile({
    super.key,
    required this.first,
    required this.last,
    this.cover,
    required this.title,
    this.subtitle,
    required this.function,
    required this.removePlaylist,
  });

  @override
  Widget build(BuildContext context) {
    const double radius = 15;

    final BorderRadius borderRadius = BorderRadius.only(
      topLeft: first ? const Radius.circular(radius) : Radius.zero,
      topRight: first ? const Radius.circular(radius) : Radius.zero,
      bottomLeft: last ? const Radius.circular(radius) : Radius.zero,
      bottomRight: last ? const Radius.circular(radius) : Radius.zero,
    );

    final Widget child = SwipeActionCell(
      key: UniqueKey(),
      trailingActions: [
        SwipeAction(
          content: iconButton(
            AppIcons.trash,
            Col.error.withAlpha(200),
            removePlaylist,
          ),
          onTap: (CompletionHandler handler) {},
          color: Col.transp,
          backgroundRadius: radius,
        ),
      ],
      child: Container(
        height: 65,
        width: MediaQuery.of(context).size.width - 20,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          color: context.colors.primaryCard.withAlpha(150),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            if (!first && !kIsApple)
              Container(
                height: 1,
                width: MediaQuery.of(context).size.width,
                color: context.colors.icon.withAlpha(50),
              ),
            Expanded(child: Container()),
            SizedBox(
              height: 56,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 10,
                            top: 2,
                            bottom: 2,
                          ),
                          child: Container(
                            width: 45,
                            height: 45,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              color: context.colors.realBackground,
                            ),
                            child: cover == null
                                ? Center(
                                    child: Icon(
                                      Icons.queue_music_rounded,
                                      color: context.colors.onIcon,
                                      size: 25,
                                    ),
                                  )
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(5),
                                    child: FadeInImage(
                                      width: 250,
                                      fit: BoxFit.cover,
                                      height: 250,
                                      placeholder: const AssetImage(
                                        'assets/images/placeholder.png',
                                      ),
                                      fadeInDuration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      fadeOutDuration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      image: MemoryImage(cover!),
                                    ),
                                  ),
                          ),
                        ),
                        razw(12.5),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: context.colors.text,
                                ),
                              ),
                              if (subtitle != null)
                                Text(
                                  subtitle!,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: context.colors.text,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: Container(
                            height: 30,
                            width: 1,
                            color: context.colors.onIcon,
                          ),
                        ),
                        SizedBox(
                          width: 28,
                          height: 49,
                          child: Icon(
                            CupertinoIcons.chevron_right,
                            color: context.colors.onIcon,
                          ),
                        ),
                        const SizedBox(width: 30),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Expanded(child: Container()),
          ],
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: ClipRRect(
        child: kIsApple
            ? GlassSurface(
                blur: 0,
                borderRadius: borderRadius,
                tint: context.colors.text,
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: function,
                  child: child,
                ),
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: inkWell(child, function),
              ),
      ),
    );
  }
}
