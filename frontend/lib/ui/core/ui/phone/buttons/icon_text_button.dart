import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../../utils/platform.dart';
import '../../../themes/colors.dart';

Widget iconTextButton(
  IconData icon,
  String text,
  TextStyle style,
  Function() function,
  Color color, {
  EdgeInsets? padding,
}) {
  return kIsApple
      ? CupertinoButton(
          onPressed: function,
          padding: padding,
          child: Row(
            children: [
              Icon(icon, color: color, size: 27.5),
              Text(text, style: style),
            ],
          ),
        )
      : Builder(
          builder: (context) => IconButton(
            style: IconButton.styleFrom(
              splashFactory: InkRipple.splashFactory,
              overlayColor: context.colors.text.withAlpha(50),
            ),
            icon: Center(
              child: Row(
                children: [
                  Icon(icon, color: color, size: 27.5),
                  Text(text, style: style),
                ],
              ),
            ),
            onPressed: function,
          ),
        );
}
