import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../utils/platform.dart';
import '../../themes/colors.dart';

CupertinoButton textButton(
  String txt,
  Function() function,
  TextStyle style, {
  EdgeInsets? edgeInsets,
  double borderRadius = 0,
}) {
  return /* kIsApple
      ? */ CupertinoButton(
    onPressed: function,
    padding: edgeInsets,
    child: Text(txt, style: style, overflow: TextOverflow.ellipsis),
  );
  /* : ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: inkWell(
            Padding(
              padding: const EdgeInsets.all(2.5),
              child: Text(
                txt,
                style: style,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            function,
          ),
        ); */
}

Widget textButtonNoPadding(String txt, Function() function, TextStyle style) {
  return kIsApple
      ? CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: function,
          child: Text(txt, style: style, overflow: TextOverflow.ellipsis),
        )
      : Builder(
          builder: (context) => TextButton(
            onPressed: function,
            style: TextButton.styleFrom(
              splashFactory: InkRipple.splashFactory,
              overlayColor: context.colors.text.withAlpha(50),
            ),
            child: Text(txt, style: style, overflow: TextOverflow.ellipsis),
          ),
        );
}
