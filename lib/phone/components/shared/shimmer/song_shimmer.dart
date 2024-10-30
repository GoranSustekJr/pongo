import 'package:shimmer/shimmer.dart';
import '../../../../exports.dart';

songTileSchimmer(context, bool first, bool last) {
  double radius = 7.5;

  return Shimmer.fromColors(
    baseColor: Col.onIcon,
    highlightColor: Col.background.withAlpha(50),
    child: SizedBox(
      height: 85,
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
              color: Col.onIcon.withAlpha(50),
            ),
          Expanded(child: Container()),
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 15),
                child: Container(
                  width: 65,
                  height: 65,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(7.5),
                    color: Col.realBackground.withAlpha(150),
                  ),
                  child: shimmContainer(65, 65, radius),
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
  );
}
