import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../themes/colors.dart';
import '../../shimmer/shimmer_container.dart';
import '../../space.dart';

Padding songTileSchimmer(BuildContext context, bool first, bool last) {
  const double radius = 7.5;

  return Padding(
    padding: EdgeInsets.zero,
    child: Shimmer.fromColors(
      baseColor: context.colors.onIcon,
      highlightColor: Col.background.withAlpha(50),
      child: SizedBox(
        height: 65,
        width: MediaQuery.of(context).size.width - 20,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!first)
              Container(
                height: 1,
                width: MediaQuery.of(context).size.width - 100,
                color: context.colors.onIcon.withAlpha(50),
              ),
            Expanded(child: Container()),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 15),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(7.5),
                      color: context.colors.realBackground.withAlpha(150),
                    ),
                    child: shimmContainer(50, 50, radius),
                  ),
                ),
                razw(12.5),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      shimmContainer(150, 8, radius),
                      razh(7.5),
                      shimmContainer(80, 5, radius),
                    ],
                  ),
                ),
              ],
            ),
            Expanded(child: Container()),
          ],
        ),
      ),
    ),
  );
}
