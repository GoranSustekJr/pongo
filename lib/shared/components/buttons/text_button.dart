import 'package:flutter/cupertino.dart';
import 'package:pongo/exports.dart';

textButton(String txt, Function() function, TextStyle style,
    {EdgeInsets? edgeInsets, double borderRadius = 0}) {
  return /* kIsApple
      ? */
      CupertinoButton(
    onPressed: function,
    padding: edgeInsets,
    child: Text(
      txt,
      style: style,
      overflow: TextOverflow.ellipsis,
    ),
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

textButtonNoPadding(String txt, Function() function, TextStyle style) {
  return kIsApple
      ? CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: function,
          child: Text(
            txt,
            style: style,
            overflow: TextOverflow.ellipsis,
          ),
        )
      : TextButton(
          onPressed: function,
          child: Text(
            txt,
            style: style,
            overflow: TextOverflow.ellipsis,
          ),
        );
}
