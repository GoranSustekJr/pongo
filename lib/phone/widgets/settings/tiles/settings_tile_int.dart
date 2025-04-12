import 'package:flutter/cupertino.dart';
import 'package:pongo/exports.dart';

settingsTileInt(context, bool first, bool last, IconData icon, int trailingNum,
    String title, String? subtitle, Function() function) {
  double radius = 15;
  BorderRadius borderRadius = BorderRadius.only(
    topLeft: first ? Radius.circular(radius) : Radius.zero,
    topRight: first ? Radius.circular(radius) : Radius.zero,
    bottomLeft: last ? Radius.circular(radius) : Radius.zero,
    bottomRight: last ? Radius.circular(radius) : Radius.zero,
  );

  Widget child = Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      if (!first)
        Container(
          height: 1,
          width: MediaQuery.of(context).size.width - 70,
          color: Col.onIcon.withAlpha(50),
        ),
      Row(
        children: [
          SizedBox(
              width: 58,
              height: 48,
              child: Icon(icon, color: Col.onIcon, size: 27.5)),
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: Col.text,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9,
                    color: Col.text.withAlpha(150),
                  ),
                ),
            ],
          )),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Container(
              height: 25,
              width: 1,
              color: Col.onIcon.withAlpha(200),
            ),
          ),
          SizedBox(
              width: 28,
              height: 48,
              child: Center(
                child: Text(
                  trailingNum.toString(),
                  style: TextStyle(color: Col.text),
                ),
              )),
          const SizedBox(
            width: 15,
          )
        ],
      ),
    ],
  );

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10),
    child: ClipRRect(
        child: Container(
      height: 50,
      width: MediaQuery.of(context).size.width - 20,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        color: Col.primaryCard.withAlpha(150),
      ),
      child: kIsApple
          ? CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                function();
              },
              child: child,
            )
          : ClipRRect(
              borderRadius: borderRadius, child: inkWell(child, function)),
    )),
  );
}
