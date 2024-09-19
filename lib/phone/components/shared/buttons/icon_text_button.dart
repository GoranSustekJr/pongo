import 'package:flutter/cupertino.dart';
import 'package:pongo/exports.dart';

iconTextButton(IconData icon, String text, TextStyle style, Function() function,
    Color color,
    {EdgeInsets? padding}) {
  return kIsApple
      ? CupertinoButton(
          onPressed: function,
          padding: padding,
          child: Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 27.5,
              ),
              Text(
                text,
                style: style,
              )
            ],
          ),
        )
      : IconButton(
          icon: Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 27.5,
              ),
              Text(
                text,
                style: style,
              )
            ],
          ),
          onPressed: function,
        );
}
