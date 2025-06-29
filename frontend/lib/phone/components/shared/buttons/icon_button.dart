import 'package:flutter/cupertino.dart';
import 'package:pongo/exports.dart';

Widget iconButton(IconData icon, Color color, Function() function,
    {EdgeInsets? edgeInsets, double? size}) {
  if (kIsApple) {
    return CupertinoButton(
        padding: edgeInsets,
        onPressed: function,
        child: Icon(
          icon,
          color: color,
          size: size,
        ));
  } else {
    return SizedBox(
        width: 50,
        height: 50,
        child: IconButton(
            style: IconButton.styleFrom(
                splashFactory: InkRipple.splashFactory,
                overlayColor: Col.text.withAlpha(50)),
            onPressed: function,
            icon: Icon(icon, color: color)));
  }
}
