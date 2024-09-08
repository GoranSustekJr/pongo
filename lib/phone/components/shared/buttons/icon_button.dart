import 'package:flutter/cupertino.dart';
import 'package:pongo/exports.dart';

iconButton(IconData icon, Color color, Function() function) {
  if (kIsApple) {
    return CupertinoButton(
        onPressed: function,
        child: Icon(
          icon,
          color: color,
        ));
  } else {
    return SizedBox(
        width: 50,
        height: 50,
        child: IconButton(onPressed: function, icon: Icon(icon, color: color)));
  }
}
