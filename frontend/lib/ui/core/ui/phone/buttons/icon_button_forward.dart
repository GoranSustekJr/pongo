import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Widget iconButtonForward(
  IconData icon,
  Function() function, {
  double height = 35,
}) {
  return SizedBox(
    height: 60,
    child: CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: function,
      child: Center(
        child: Icon(icon, color: Colors.white, size: height),
      ),
    ),
  );
}
