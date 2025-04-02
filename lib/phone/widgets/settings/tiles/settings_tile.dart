import 'package:flutter/cupertino.dart';
import 'package:pongo/exports.dart';

settingsTile(context, bool first, bool last, IconData icon,
    IconData? trailingIcon, String title, String? subtitle, Function() function,
    {bool special = false}) {
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
              child: special
                  ? Image.asset('assets/images/pongo_logo_tranparent.png')
                  : Icon(icon, color: Col.onIcon, size: 27.5)),
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: kIsApple ? 13 : 15,
                  color: Colors.white,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: kIsApple ? 9 : 11,
                    color: Colors.white.withAlpha(150),
                  ),
                ),
            ],
          )),
          if (trailingIcon != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Container(
                height: 25,
                width: 1,
                color: Col.onIcon.withAlpha(200),
              ),
            ),
          if (trailingIcon != null)
            SizedBox(
                width: 28,
                height: 48,
                child: Icon(trailingIcon,
                    color: Col.onIcon.withAlpha(200), size: 20)),
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
              padding: EdgeInsets.zero, onPressed: function, child: child)
          : ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: first ? Radius.circular(radius) : Radius.zero,
                topRight: first ? Radius.circular(radius) : Radius.zero,
                bottomLeft: last ? Radius.circular(radius) : Radius.zero,
                bottomRight: last ? Radius.circular(radius) : Radius.zero,
              ),
              child: inkWell(child, function)),
    )),
  );
}
