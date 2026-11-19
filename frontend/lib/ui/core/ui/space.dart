import 'package:flutter/material.dart';

import '../themes/colors.dart';

Widget razh(double x) {
  return SizedBox(height: x);
}

SizedBox razw(double x) {
  return SizedBox(width: x);
}

Widget divider(double x) {
  return Builder(
    builder: (context) =>
        Container(width: x, height: 1, color: context.colors.onIcon),
  );
}

Padding dividerVertical(double y, double x, double padding) {
  return Padding(
    padding: EdgeInsets.symmetric(horizontal: padding),
    child: Container(width: x, height: y, color: Colors.white),
  );
}
