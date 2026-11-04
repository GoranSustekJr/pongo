import 'package:flutter/cupertino.dart';
import 'package:pongo/exports.dart';

Widget iconButtonForward(IconData icon, Function() function,
    {double height = 35}) {
  return SizedBox(
    height: 60,
    child: CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: function,
      child: Center(
        child: Icon(
          icon,
          color: Colors.white,
          size: height,
        ),
      ),
    ),
  );
}
