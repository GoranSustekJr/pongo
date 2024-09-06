import 'package:flutter/cupertino.dart';
import 'package:pongo/exports.dart';

textButton(String txt, Function() function, TextStyle style) {
  return kIsApple
      ? CupertinoButton(
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
