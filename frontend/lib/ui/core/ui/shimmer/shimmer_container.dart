import 'package:flutter/material.dart';

import '../../themes/colors.dart';

Widget shimmContainer(double width, double height, double radius) {
  return Align(
    alignment: Alignment.centerLeft,
    child: Builder(
      builder: (context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          color: context.colors.onIcon,
        ),
      ),
    ),
  );
}
